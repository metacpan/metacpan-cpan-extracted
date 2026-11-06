package Perl::CodeMap;
use strict;
use warnings;
use 5.020;
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Find ();
use File::Spec ();
use JSON::PP ();
use Encode qw(decode FB_DEFAULT);
use IPC::Open3 ();
use Symbol qw(gensym);

our $VERSION = '0.3.2';

sub new {
    my ($class, %arg) = @_;
    my $root = abs_path($arg{root} // '.');
    die "Source directory does not exist\n" unless defined $root && -d $root;
    my $mode = $arg{parser} // 'auto';
    die "parser must be one of auto, ppi, lite\n" unless $mode =~ /\A(?:auto|ppi|lite)\z/;
    my $ppi = eval { require PPI; 1 } ? 1 : 0;
    die "PPI is not installed. Install it using 'cpanm PPI', or use --parser lite\n"
        if $mode eq 'ppi' && !$ppi;
    my $selected = $mode eq 'auto' ? ($ppi ? 'ppi' : 'lite') : $mode;
    my $max_bytes = $arg{max_source_bytes} // 2_000_000;
    die "max_source_bytes must be a positive integer\n" unless $max_bytes =~ /\A[1-9][0-9]*\z/;
    return bless {
        root => $root, parser => $selected,
        include_tests => $arg{include_tests} ? 1 : 0,
        embed_source => exists $arg{embed_source} ? ($arg{embed_source} ? 1 : 0) : 1,
        max_source_bytes => $max_bytes,
        source_base => $arg{source_base}, name => $arg{name},
        warnings => [],
    }, $class;
}

sub analyze {
    my ($self) = @_;
    my $root = $self->{root};
    my %ignored = map { $_ => 1 } qw(.git .svn .hg .idea .vscode node_modules vendor blib local _build cover_db .cache);
    if (!$self->{include_tests}) { $ignored{$_} = 1 for qw(t xt tests test); }
    my @candidates;
    File::Find::find({ no_chdir => 1, follow => 0, wanted => sub {
        my $path = $File::Find::name;
        if (-d $path) {
            my $base = basename($path);
            $File::Find::prune = 1 if $path ne $root && ($ignored{$base} || $base =~ /^\./);
            return;
        }
        return unless -f $path && !-l $path;
        return unless $self->{include_tests} || $path !~ /\.t\z/;
        return unless $path =~ /\.(?:pm|pl|psgi|t)\z/i || basename($path) !~ /\./;
        push @candidates, $path;
    } }, $root);
    @candidates = sort @candidates;
    my (%packages, %sources, $file_count);
    $file_count = 0;
    for my $path (@candidates) {
        open my $fh, '<:raw', $path or do {
            push @{$self->{warnings}}, 'Unable to read ' . File::Spec->abs2rel($path, $root);
            next;
        };
        local $/;
        my $raw = <$fh>;
        close $fh;
        my $rel = File::Spec->abs2rel($path, $root);
        $rel =~ s{\\}{/}g;
        next if $rel !~ /\.(?:pm|pl|psgi|t)\z/i && $raw !~ /\A\#![^\n]*\bperl\b/;
        $file_count++;
        if ($self->{embed_source}) {
            if (length($raw) <= $self->{max_source_bytes}) {
                $sources{$rel} = decode('UTF-8', $raw, FB_DEFAULT);
            } else {
                push @{$self->{warnings}}, "Source exceeds embedding limit: $rel";
            }
        }
        my $parsed = $self->_parse_file($path, $rel, $raw);
        my %associated;
        for my $event (@{$parsed->{events}}) {
            my $pkg = $event->{type} eq 'package' ? $event->{name}
                : _package_at($parsed->{scopes}, $event->{line}, $parsed->{default});
            next unless defined $pkg && $pkg =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
            $associated{$pkg} = 1;
            my $p = $packages{$pkg} ||= {path => $pkg, dir => dirname($rel), doc => '', imports => {}, files => {}};
            my $f = $p->{files}{$rel} ||= {path => $rel, name => basename($rel), lines => $parsed->{lines}, funcs => []};
            if ($event->{type} eq 'package') {
                $p->{doc} ||= _preceding_comment($parsed->{raw_lines}, $event->{line});
            } elsif ($event->{type} eq 'sub') {
                push @{$f->{funcs}}, {
                    n => $event->{name}, l => $event->{line}, s => $event->{size},
                    k => $event->{kind}, e => ($event->{name} !~ /^_/ ? JSON::PP::true : JSON::PP::false),
                    d => _preceding_comment($parsed->{raw_lines}, $event->{line}),
                };
            } elsif ($event->{type} eq 'include') {
                for my $target (@{$event->{targets}}) {
                    $p->{imports}{$target} = 1 if $target ne $pkg;
                }
            }
        }
        if (!%associated) {
            my $pkg = $parsed->{default};
            my $p = $packages{$pkg} ||= {path => $pkg, dir => dirname($rel), doc => '', imports => {}, files => {}};
            $p->{files}{$rel} ||= {path => $rel, name => basename($rel), lines => $parsed->{lines}, funcs => []};
        }
    }
    my @pkgs;
    for my $name (sort keys %packages) {
        my $p = $packages{$name};
        my @files = sort { $a->{path} cmp $b->{path} } values %{$p->{files}};
        for my $file (@files) {
            my %seen;
            @{$file->{funcs}} = sort { $a->{l} <=> $b->{l} || $a->{n} cmp $b->{n} }
                grep { !$seen{join(':', $_->{l}, $_->{n})}++ } @{$file->{funcs}};
        }
        push @pkgs, {
            path => $name, dir => $p->{dir}, doc => $p->{doc}, files => \@files,
            imports => [ sort grep { $_ ne $name && exists $packages{$_} } keys %{$p->{imports}} ],
        };
    }
    my ($source, $rev) = $self->_source_info;
    return {
        format => 1, name => ($self->{name} // basename($root)), module => $root,
        parser => $self->{parser}, rev => $rev, source => $source, scanned_files => $file_count,
        pkgs => \@pkgs, sources => \%sources, warnings => [@{$self->{warnings}}],
    };
}

sub _parse_file {
    my ($self, $path, $rel, $raw) = @_;
    my @lines = split /\n/, $raw, -1;
    pop @lines if @lines > 1 && $lines[-1] eq '';
    my $default = _inferred_name($rel);
    my @events;
    my @scopes;
    my @lite = _mask_lines(\@lines);
    if ($self->{parser} eq 'ppi') {
        my $doc = eval { PPI::Document->new($path) };
        if ($doc) {
            $doc->index_locations;
            for my $p (@{$doc->find('PPI::Statement::Package') || []}) {
                my $name = $p->namespace;
                my $at = $p->location;
                next unless $name && $at;
                my $scope = { name => $name, line => $at->[0] };
                push @scopes, $scope;
                push @events, {type => 'package', name => $name, line => $at->[0]};
            }
            for my $s (@{$doc->find('PPI::Statement::Sub') || []}) {
                my $name = $s->name;
                my $at = $s->location;
                next unless $name && $at;
                my $end = $at->[0];
                my $block = $s->block;
                if ($block) {
                    my $last = $block->last_token;
                    my $finish = $last && $last->location;
                    $end = $finish->[0] if $finish && $finish->[0] > $end;
                }
                push @events, {type => 'sub', name => $name, line => $at->[0],
                    size => $end-$at->[0]+1, kind => 'sub'};
            }
            for my $s (@{$doc->find('PPI::Statement::Include') || []}) {
                next if ($s->type // '') eq 'no';
                my $name = $s->module;
                my $at = $s->location;
                next unless $at && $name && $name =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
                push @events, {type => 'include', line => $at->[0], targets => [$name]};
            }
        } else {
            push @{$self->{warnings}}, "PPI could not parse $rel; using limited parser";
            push @events, _lite_events(\@lite, \@lines);
        }
    } else {
        push @events, _lite_events(\@lite, \@lines);
    }
    # Explicit scopes from literal source also support the optional lite mode;
    # this intentionally does not attempt full lexical Perl semantics.
    for my $i (0..$#lite) {
        next unless $lite[$i] =~ /^\s*package\s+([A-Za-z_]\w*(?:::\w+)*)\b/;
        my $name = $1;
        next if $self->{parser} eq 'ppi' && grep { $_->{name} eq $name && $_->{line} == $i+1 } @scopes;
        push @scopes, {name => $name, line => $i+1};
        push @events, {type => 'package', name => $name, line => $i+1};
    }
    push @events, _extra_events(\@lite, \@lines);
    my %seen;
    @events = grep {
        !$seen{join('|', $_->{type}, $_->{line}, ($_->{name}//''), ($_->{kind}//''),
            join(',',@{$_->{targets}//[]}))}++
    } @events;
    @scopes = sort { $a->{line} <=> $b->{line} } @scopes;
    return {events => \@events, scopes => \@scopes, default => $default, lines => scalar(@lines), raw_lines => \@lines};
}

sub _inferred_name {
    my ($rel) = @_;
    if ($rel =~ /(?:^|\/)lib\/(.+)\.pm\z/ || $rel =~ /\A(.+)\.pm\z/) {
        my $name = $1;
        $name =~ s{/}{::}g;
        return $name if $name =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
    }
    return 'main';
}

sub _package_at {
    my ($scopes, $line, $default) = @_;
    my $pkg = $default;
    for my $p (@$scopes) {
        last if $p->{line} > $line;
        $pkg = $p->{name};
    }
    return $pkg;
}

sub _mask_lines {
    my ($lines) = @_;
    my @out;
    my $pod = 0;
    my @heredocs;
    my $ended = 0;
    for my $raw (@$lines) {
        if ($ended) { push @out, ""; next; }
        if (@heredocs) {
            push @out, '';
            shift @heredocs if $raw =~ /^\Q$heredocs[0]\E\s*;?\s*\z/;
            next;
        }
        if ($pod) {
            $pod = 0 if $raw =~ /^=cut\b/;
            push @out, '';
            next;
        }
        if ($raw =~ /^=(?:pod|head\d|begin|for|item|over|back|encoding)\b/) {
            $pod = 1; push @out, ''; next;
        }
        if ($raw =~ /^__(?:DATA|END)__\b/) { $ended = 1; push @out, ''; next; }
        my ($out, $quote) = ('','');
        my @chars = split //, $raw;
        for (my $i=0; $i<@chars; $i++) {
            my $char = $chars[$i];
            if ($quote) {
                if ($char eq '\\') { $out .= '  '; $i++ if $i+1<@chars; next; }
                $quote = '' if $char eq $quote;
                $out .= ' '; next;
            }
            last if $char eq '#';
            if ($char eq "'" || $char eq '"' || $char eq '`') {
                $quote = $char; $out .= ' '; next;
            }
            $out .= $char;
        }
        push @out, $out;
        while ($out =~ /<<\s*([A-Za-z_]\w*)/g) { push @heredocs, $1; }
        while ($raw =~ /<<\s*['"]([A-Za-z_]\w*)['"]/g) { push @heredocs, $1; }
    }
    return @out;
}

sub _block_length {
    my ($lines,$start) = @_;
    for my $i ($start..$#$lines) {
        last if $i > $start+30;
        my $offset = index($lines->[$i],'{');
        if ($offset >= 0) {
            my $depth = 0;
            for my $j ($i..$#$lines) {
                my $line = $lines->[$j];
                for(my $c=($j==$i?$offset:0); $c<length($line); $c++) {
                    my $ch = substr($line,$c,1);
                    $depth++ if $ch eq '{';
                    $depth-- if $ch eq '}';
                    return $j-$start+1 if $depth == 0;
                }
            }
            return 1;
        }
        return 1 if $lines->[$i] =~ /;/;
    }
    return 1;
}

sub _lite_events {
    my ($masked,$original) = @_;
    my @events;
    for my $i (0..$#$masked) {
        my $s = $masked->[$i];
        if ($s =~ /^\s*(?:(?:my|our|state)\s+)?sub\s+([A-Za-z_]\w*(?:::\w+)*)\b/) {
            push @events, {type=>'sub',name=>$1,line=>$i+1,size=>_block_length($masked,$i),kind=>'sub'};
        }
        if ($s =~ /^\s*(?:use|require)\s+([A-Za-z_]\w*(?:::\w+)*)\b/) {
            push @events, {type=>'include',line=>$i+1,targets=>[$1]};
        }
    }
    return @events;
}

sub _extra_events {
    my ($masked, $original) = @_;
    my @events;
    for my $i (0..$#$masked) {
        my $s = $masked->[$i];
        if ($s =~ /^\s*method\s+([A-Za-z_]\w*)\b/) {
            push @events, {type=>'sub',name=>$1,line=>$i+1,size=>_block_length($masked,$i),kind=>'method'};
        }
        next unless $s =~ /^\s*(?:extends|with|use\s+(?:parent|base))\b/;
        my $part=$original->[$i];
        $part =~ s/^\s*(?:extends|with|use\s+(?:parent|base))\s*//;
        $part =~ s/\s*;.*\z//;
        $part =~ s/^-norequire\s*[,;]?\s*//;
        my @names;
        if ($part =~ /^qw\s*([\(\[\{<\/!#|])/) {
            my $open=$1; my %close=('('=>')','['=>']','{'=>'}','<'=>'>');
            my $end=$close{$open}//$open;
            if ($part =~ /\Q$open\E(.*?)\Q$end\E/) { @names=split /\s+/, $1; }
        } else {
            @names=$part =~ /['"]([A-Za-z_]\w*(?:::\w+)*)['"]/g;
        }
        @names=grep { /\A[A-Za-z_]\w*(?:::\w+)*\z/ } @names;
        push @events, {type=>'include',line=>$i+1,targets=>\@names} if @names;
    }
    return @events;
}

sub _preceding_comment {
    my ($lines,$line) = @_;
    my @parts;
    for (my $i=$line-2; $i>=0; $i--) {
        last unless $lines->[$i] =~ /^\s*#\s?(.*?)\s*\z/;
        unshift @parts, $1;
    }
    my $joined=join(' ',@parts);
    $joined =~ s/\s+/ /g;
    $joined =~ s/^\s+|\s+$//g;
    return length($joined)>180 ? substr($joined,0,177).'...' : $joined;
}

# Read source paths from a previously generated JSON without trusting paths
# that could traverse outside of the specified root (or traverse symlinks).
sub hydrate_sources {
    my ($self,$data,$dir) = @_;
    my $root=abs_path($dir // $self->{root});
    die "Source directory does not exist\n" unless $root && -d $root;
    my %paths=map { $_->{path} => 1 }
        map { @{$_->{files} || []} } @{$data->{pkgs} || []};
    $data->{sources} ||= {};
    my $count=0;
    for my $rel (sort keys %paths) {
        next if $rel =~ /\0|\\/ || $rel =~ m{\A/} || $rel =~ m{(?:\A|/)\.\.(?:/|\z)};
        my $path=File::Spec->catfile($root,split m{/},$rel);
        next unless -f $path && !-l $path && -s $path <= $self->{max_source_bytes};
        my $real=abs_path($path);
        next unless $real && index($real,"$root/")==0;
        open my $fh,'<:raw',$path or next;
        my $bytes=do { local $/; <$fh> };
        close $fh;
        $data->{sources}{$rel}=decode('UTF-8',$bytes,FB_DEFAULT);
        $count++;
    }
    return $count;
}

sub _capture {
    my (@command)=@_;
    my ($in,$out);
    my $err=gensym;
    my $pid=eval { IPC::Open3::open3($in,$out,$err,@command) };
    return undef unless $pid;
    close $in;
    my $value=do { local $/; <$out> };
    close $out;
    my $discard=do { local $/; <$err> };
    close $err;
    waitpid($pid,0);
    return undef if $?;
    $value //= '';
    $value =~ s/\s+\z//;
    return $value;
}

sub _source_info {
    my ($self)=@_;
    return ($self->{source_base},'') if defined $self->{source_base};
    my $rev=_capture('git','-C',$self->{root},'rev-parse','HEAD')//'';
    return ('','') unless $rev =~ /^[a-f0-9]{40}$/;
    my $remote=_capture('git','-C',$self->{root},'remote','get-url','origin')//'';
    my ($owner,$repo)=$remote =~ m{github\.com[:/]([^/\s:]+)/([^/\s]+?)(?:\.git)?\z};
    return ('',$rev) unless defined $owner;
    my $prefix=_capture('git','-C',$self->{root},'rev-parse','--show-prefix')//'';
    return ("https://github.com/$owner/$repo/blob/$rev/$prefix",$rev);
}

sub write_report {
    my ($self,$data,%opts) = @_;
    my $output=$opts{output}//'perl-code-map.html';
    die "Expected data with pkgs array\n" unless ref($data) eq 'HASH' && ref($data->{pkgs}) eq 'ARRAY';
    my $encoder=JSON::PP->new->canonical(1)->utf8(1);
    my $json=$encoder->encode($data);
    if ($opts{json}) {
        open my $fh,'>:raw',$opts{json} or die "Cannot write $opts{json}: $!\n";
        print {$fh} $json;
        close $fh or die "Cannot close $opts{json}: $!\n";
    }
    my $module_file=$INC{'Perl/CodeMap.pm'} // __FILE__;
    my $assets=File::Spec->catdir(dirname($module_file),'CodeMap','assets');
    my %a;
    for my $name (qw(template.html app.css app.js prism-core.min.js prism-perl.min.js)) {
        open my $fh,'<:raw',File::Spec->catfile($assets,$name)
            or die "Missing packaged report asset '$name' ($!)\n";
        $a{$name}=do { local $/; <$fh> };
        close $fh;
    }
    my $title=$data->{name}//'Perl';
    $title =~ s/&/&amp;/g;
    $title =~ s/</&lt;/g;
    $title =~ s/>/&gt;/g;
    $title =~ s/"/&quot;/g;
    $a{'template.html'} =~ s/\{\{TITLE\}\}/$title/g;
    $json =~ s/</\\u003c/g;
    $json =~ s/>/\\u003e/g;
    $json =~ s/&/\\u0026/g;
    open my $fh,'>:raw',$output or die "Cannot write $output: $!\n";
    my $html=$a{'template.html'};
    $html =~ s{<!-- STYLE -->}{'<style>' . $a{'app.css'} . '</style>'}e;
    $html =~ s{<!-- JSON -->}{'<script id="data" type="application/json">'.$json.'</script>'}e;
    $html =~ s{<!-- JS -->}{'<script>'.$a{'prism-core.min.js'}.'</script><script>'.$a{'prism-perl.min.js'}.'</script><script>'.$a{'app.js'}.'</script>'}e;
    print {$fh} $html;
    close $fh or die "Cannot close $output: $!\n";
    return $output;
}

1;

__END__

=head1 NAME

Perl::CodeMap - Analyze Perl packages and generate interactive dependency and source maps

=head1 VERSION

Version 0.3.2.

=head1 SYNOPSIS

The command-line interface is the recommended starting point:

  cpanm Perl::CodeMap
  cpanm PPI
  perl-codemap --root ./lib --parser ppi --output map.html
  perl-codemap --help
  perl-codemap --man

The module also exposes the analyzer and report generator programmatically:

  use strict;
  use warnings;
  use Perl::CodeMap;

  my $codemap = Perl::CodeMap->new(
      root           => './lib',
      parser         => 'auto',
      embed_source   => 1,
      include_tests  => 0,
  );

  my $analysis = $codemap->analyze;
  my $html_path = $codemap->write_report(
      $analysis,
      output => 'map.html',
      json   => 'map.json',
  );

  printf "Mapped %d packages to %s\n", scalar @{$analysis->{pkgs}}, $html_path;

=head1 DESCRIPTION

B<Perl::CodeMap> provides a static analyzer for Perl codebases. It discovers
package declarations, subroutines, file locations, and statically identifiable
local package dependencies without loading or executing the input source.
Its primary output is a self-contained HTML report featuring an interactive
package dependency graph, searchable symbols, and a syntax-highlighted source
viewer. It can also export the analysis as JSON for later use.

This module is the library underpinning the B<perl-codemap> command installed
by the same distribution. For most users, run C<perl-codemap --help> or
C<perl-codemap --man>; no Perl API programming is required.

The preferred analysis engine is L<PPI>. A limited heuristic fallback parser
is available when PPI is not installed. This tool does not implement Perl's
runtime semantics or a complete function-level call graph.

=head1 INSTALLATION

Install the application and recommended parser from CPAN:

  cpanm Perl::CodeMap
  cpanm PPI

Perl 5.20 or newer is required. PPI is recommended but is not required by
the distribution; parser C<auto> falls back to C<lite> if PPI is unavailable.

For a standalone usage example, visit
L<the public sample|https://interrupt21h.github.io/perl-codemap/>.

=head1 CONSTRUCTOR

=head2 new

  my $codemap = Perl::CodeMap->new(%options);

Constructs an analyzer object. The source root must exist and must be a
directory. Invalid parser modes, invalid per-file size limits, or an
explicit request for an unavailable PPI parser raise an exception with C<die>.

Accepted options are:

=over 4

=item C<root>

Filesystem directory to scan. Defaults to the current working directory (C<.>).
The path is resolved to an absolute path during construction.

=item C<parser>

One of C<auto> (default), C<ppi>, or C<lite>. C<auto> selects PPI when
installed, otherwise C<lite>. C<ppi> fails if PPI cannot be loaded.
C<lite> is a heuristic parser and may miss complex Perl syntax.

=item C<include_tests>

Boolean; default false. When enabled, include F<.t> test files and common
F<t/>, F<xt/>, F<test/>, and F<tests/> directories.

=item C<embed_source>

Boolean; default true. When enabled, place decoded source-file text in the
C<sources> field of the analysis, making the offline report's source browser
available. Reports may contain private information when this is enabled.

=item C<max_source_bytes>

Positive integer limiting the number of bytes embedded from any one source
file. Default C<2_000_000>. Oversized files are analyzed for symbols but
not embedded in C<sources>; a warning is recorded.

=item C<source_base>

Optional URL prefix used for links to hosted source files. If omitted, a
GitHub source URL may be inferred from the local Git checkout's C<origin>
remote and current revision. Set it explicitly for GitLab or other hosts.

=item C<name>

Optional display name for the generated report. Defaults to the basename
of the resolved source root.

=back

The constructor returns a C<Perl::CodeMap> object. It does not scan files;
call L</analyze> to perform the scan.

=head1 PUBLIC METHODS

=head2 analyze

  my $analysis = $codemap->analyze;

Statically reads candidate Perl files beneath the constructor's C<root> and
returns a hash reference describing packages, files, functions, dependencies,
source text (when enabled), and warnings.

The analyzer recognizes F<.pm>, F<.pl>, F<.psgi>, optionally F<.t>, and
extensionless files with a Perl shebang. It skips hidden directories,
symlinks, and common version-control, vendor, and build directories. It
creates edges only for local packages that are discoverable in the same scan.

The analysis does not modify the source tree and does not execute source files.
Individual unreadable files are noted in the C<warnings> array. Unexpected
I/O or parser failures may raise an exception.

See L</ANALYSIS DATA FORMAT> for the returned structure.

=head2 hydrate_sources

  my $loaded = $codemap->hydrate_sources($analysis, './original-source');

Adds decoded source contents to an existing analysis hash reference,
including a previously imported JSON export. The source root is the
second positional argument; if omitted, the analyzer's own root is used.
Paths are taken from the analysis's package/file list and interpreted
relative to that directory.

The method skips missing, oversized, symlinked, or unsafe paths; it prevents
source reads outside the resolved root. It modifies
C<$analysis-E<gt>{sources}> in place and returns the number of files loaded.
The root must exist or an exception is raised. It does not remove previously
embedded source entries that are unrelated to successfully loaded files.

Be careful when using data imported from untrusted JSON: the report will also
retain text already present in that JSON, including any embedded source.

=head2 write_report

  my $output_path = $codemap->write_report(
      $analysis,
      output => 'architecture.html',
      json   => 'architecture.json',
  );

Serializes the analysis data into a single, self-contained HTML file with
embedded CSS, JavaScript, syntax highlighting, and data. The HTML report
requires only a modern browser with JavaScript enabled; it does not require
a web server or CDN. Optionally writes a machine-readable JSON file.

Arguments:

=over 4

=item C<$analysis>

A hash reference containing at least a C<pkgs> array, normally returned by
L</analyze> or decoded from an earlier CodeMap JSON export.

=item C<output>

Optional HTML destination path. Defaults to C<perl-code-map.html>.

=item C<json>

Optional JSON export destination path. If omitted, no separate JSON file is
written.

=back

Returns the HTML output path. Invalid data or I/O failures raise an exception.
Existing output files at these paths are overwritten.

=head1 ANALYSIS DATA FORMAT

The analysis is a hash reference with the following top-level members:

=over 4

=item C<format>

Numeric CodeMap data format version (currently C<1>).

=item C<name>

Report display name.

=item C<module>

Absolute path of the scanned root. Treat this as potentially sensitive
metadata if exporting analysis outside your organization.

=item C<parser>

Parser selected for the analysis: C<ppi> or C<lite>.

=item C<scanned_files>

Number of recognized Perl source files read for the analysis.

=item C<rev>, C<source>

Detected Git revision and remote source prefix, or empty strings when unknown.

=item C<pkgs>

Array reference of package objects. Each package contains C<path> (fully
qualified package name), C<dir>, C<doc>, C<imports> (array of local package
names), and C<files> (array of file objects). Each file contains C<path>,
C<name>, C<lines>, and C<funcs>. Each function object contains the keys
C<n> (name), C<l> (starting line), C<s> (approximate body length), C<k>
(kind), C<e> (public-name flag), and C<d> (preceding documentation comment).

=item C<sources>

Hash reference mapping relative file paths to source text. Populated only
when source embedding is enabled and the source file does not exceed the
configured limit.

=item C<warnings>

Array reference of nonfatal scan and source-embedding warnings.

=back

This is an analysis/export structure, not a complete Perl abstract syntax
tree. The current format number is intended to support versioned consumers;
minor internal fields may evolve across versions. When processing imports,
validate C<format> and the expected types rather than assuming all fields
are always present.

=head1 ERROR HANDLING

These public methods use C<die> for invalid configuration, invalid report
data, and unrecoverable read/write errors. Callers may wrap them in C<eval>:

  my $data = eval { $codemap->analyze };
  if ($@) {
      warn "Unable to analyze source: $@";
  }

Per-file read failures may be returned as C<warnings> instead of being fatal.
The CLI maps failures to documented exit statuses; run C<perl-codemap --man>
for its exit-status reference.

=head1 LIMITATIONS

Dependency edges represent statically detectable local package references,
not runtime method calls. Dynamic C<require>, C<AUTOLOAD>, monkey-patching,
Moose/Moo method modifiers, Catalyst dispatch, and DBIx::Class runtime
relationships are not fully modeled. Multiple C<package> declarations per
file are supported; temporary block-scoped declarations are best effort.
For complicated syntax, use PPI and verify the result against the source.

=head1 SECURITY AND PRIVACY

B<Source embedding is enabled by default>. HTML/JSON results can contain
entire proprietary source files, secrets, internal names, and filesystem
paths. Keep reports from private repositories private. The option
C<embed_source =E<gt> 0> excludes source text but does not remove potentially
sensitive package metadata. Use a dedicated secrets scanner if you need one.

The source analyzer does not execute scanned files. It is not a security
sandbox or a secrets detector.

=head1 SEE ALSO

The executable's complete manual: C<perldoc perl-codemap> or
C<perl-codemap --man> after installation. The online
L<Perl CodeMap user guide|https://github.com/interrupt21h/perl-codemap/blob/main/docs/USER_GUIDE.md>
and L<source repository|https://github.com/interrupt21h/perl-codemap>
provide additional examples.

L<PPI>, L<Pod::Usage>,
L<Perl CodeMap on MetaCPAN|https://metacpan.org/dist/Perl-CodeMap>,
L<Live demo|https://interrupt21h.github.io/perl-codemap/>.

=head1 AUTHOR

Scott Muller <scott@21h.io>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Scott Muller. This program is distributed under the
MIT License. See LICENSE and NOTICE.md for attribution and third-party notices.

=cut
