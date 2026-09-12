package Sim::OPT::StructureDesignProcedure;

use strict;
use warnings;
use Exporter 'import';
use Cwd qw(getcwd abs_path);
use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Spec;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Time::Piece;

our $VERSION = '0.30';
our $LANGUAGE_VERSION = '1.2';
our $PROCEDURE_SCHEMA = 'Sim::OPT::StructureDesign/procedure-1';
our @EXPORT_OK = qw(
    design state experience parallel derive reembed merge imagine abstract retain_memory apply_abstraction compare statistics reconstruct_memory validation_sample direct_validation_statistics
    search star surrogate medoids surrogating_with clustering_and_finding_medoids clustering_and_medoiding
    reduce_scope enlarge_scope increase_resolution decrease_resolution pan maintain_resolution
    incumbent result_of
    procedure_language_version procedure_schema
    load_procedure run_procedure
);

# -------------------------------------------------------------------------
# Embedded-Perl DSL constructors. These only describe intent; they do not
# perform filesystem or Sim::OPT operations.
# -------------------------------------------------------------------------

sub design {
    my ($name, %a) = @_;
    die "design: name required\n" unless defined($name) && length($name);
    my $steps = delete($a{steps}) || [];
    die "design: steps must be an ARRAY reference\n" unless ref($steps) eq 'ARRAY';
    return {
        schema => $PROCEDURE_SCHEMA,
        name   => $name,
        root_dir => $a{root_dir} || $ENV{HOME} || '.',
        manifest => $a{manifest},
        steps  => $steps,
        %a,
    };
}

sub _node {
    my ($type, @args) = @_;
    my %a;
    if (@args && !ref($args[0])) {
        $a{name} = shift @args;
    }
    %a = (%a, @args);
    $a{type} = $type;
    $a{enabled} = 1 unless exists $a{enabled};
    return \%a;
}

sub state      { return _node('state',      @_); }
sub experience { return _node('experience', @_); }
sub parallel   { return _node('parallel',   @_); }
sub derive     { return _node('derive',     @_); }
sub reembed    { return _node('reembed',    @_); }
sub merge      { return _node('merge',      @_); }
sub imagine    { return _node('imagine',    @_); }
sub abstract   { return _node('abstract',   @_); }
sub retain_memory { return _node('retain_memory', @_); }
sub apply_abstraction { return _node('apply_abstraction', @_); }
sub compare    { return _node('compare',    @_); }
sub statistics { return _node('statistics', @_); }
sub reconstruct_memory { return _node('reconstruct_memory', @_); }
sub validation_sample { return _node('validation_sample', @_); }
sub direct_validation_statistics { return _node('direct_validation_statistics', @_); }

sub search     { return { kind => 'search', @_ }; }
sub star       { return { kind => 'star', @_ }; }
sub surrogate  { return { kind => 'surrogate', @_ }; }
sub medoids    { return { kind => 'medoids', @_ }; }

# Article-facing vocabulary.  Keep the older constructors as compatibility aliases.
sub surrogating_with {
    my ($method, @rest) = @_;
    die "surrogating_with: method required\n" unless defined($method) && length($method);
    return { kind => 'surrogate', method => $method, @rest };
}
sub clustering_and_finding_medoids {
    return { kind => 'clustering_and_finding_medoids', @_ };
}

# Backward-compatible spelling retained for old procedure files only.
sub clustering_and_medoiding {
    return clustering_and_finding_medoids(@_);
}

sub reduce_scope        { return { op => 'reduce_scope',        @_ }; }
sub enlarge_scope       { return { op => 'enlarge_scope',       @_ }; }
sub increase_resolution { return { op => 'increase_resolution', @_ }; }
sub decrease_resolution { return { op => 'decrease_resolution', @_ }; }
sub pan                 { return { op => 'pan',                  @_ }; }
sub maintain_resolution { return { op => 'maintain_resolution', @_ }; }

sub incumbent { return { ref => 'incumbent', step => $_[0] }; }
sub result_of { return { ref => 'result',    step => $_[0], key => $_[1] }; }

sub procedure_language_version { return $LANGUAGE_VERSION; }
sub procedure_schema           { return $PROCEDURE_SCHEMA; }

# -------------------------------------------------------------------------
# Loading and manifest helpers
# -------------------------------------------------------------------------

sub load_procedure {
    my ($file) = @_;
    die "load_procedure: procedure file required\n" unless defined($file) && length($file);
    my $abs = File::Spec->rel2abs($file);
    die "Procedure file not found: $abs\n" unless -f $abs;
    my $p = do $abs;
    die "Cannot load procedure $abs: $@\n" if $@;
    die "Cannot read procedure $abs: $!\n" unless defined $p;
    die "Procedure $abs did not return a HASH reference\n" unless ref($p) eq 'HASH';
    die "Unsupported procedure schema\n" unless ($p->{schema} || '') eq $PROCEDURE_SCHEMA;
    $p->{_procedure_file} = $abs;
    return $p;
}

sub _json { return JSON::PP->new->canonical(1)->pretty(1); }
sub _now  { return localtime->datetime . localtime->strftime('%z'); }

sub _step_id {
    my ($s, $i) = @_;
    return $s->{id} if defined($s->{id}) && length($s->{id});
    return sprintf('%03d_%s_%s', $i + 1, $s->{type} || 'step', $s->{name} || 'unnamed');
}

sub _step_signature {
    my ($s) = @_;
    my %copy = %$s;
    delete $copy{_runtime};
    return sha256_hex(JSON::PP->new->canonical(1)->encode(\%copy));
}

sub _read_json {
    my ($path) = @_;
    return {} unless -f $path;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $txt = <$fh>;
    close $fh;
    return JSON::PP->new->decode($txt);
}

sub _write_json {
    my ($path, $data) = @_;
    make_path(dirname($path)) unless -d dirname($path);
    my $tmp = "$path.tmp.$$";
    open my $fh, '>', $tmp or die "Cannot write $tmp: $!\n";
    print {$fh} _json()->encode($data);
    close $fh or die "Cannot close $tmp: $!\n";
    rename $tmp, $path or die "Cannot rename $tmp -> $path: $!\n";
}

sub _manifest_path {
    my ($p) = @_;
    return File::Spec->rel2abs($p->{manifest}) if defined($p->{manifest}) && length($p->{manifest});
    return File::Spec->catfile($p->{root_dir}, '.structuredesign', $p->{name} . '.json');
}

# A run manifest is only reusable when both the declared procedure and the
# installed StructureDesign runtime that gives those declarations meaning are
# unchanged.  Step signatures alone are insufficient: a change in the zoom,
# re-embedding, launch, or reconstruction implementation can alter the meaning
# of an otherwise identical procedure step.
sub _file_sha256 {
    my ($path) = @_;
    return undef unless defined($path) && -f $path;
    open my $fh, '<', $path or die "Cannot read $path for signature: $!\n";
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;
    return $sha->hexdigest;
}

sub _find_inc_file {
    my ($rel) = @_;
    for my $base (@INC) {
        next if ref($base);
        my $p = File::Spec->catfile($base, split m{/}, $rel);
        return $p if -f $p;
    }
    return undef;
}

sub _procedure_signature {
    my ($p) = @_;
    my @steps;
    my $i = 0;
    for my $s (@{ $p->{steps} || [] }) {
        my $sid = _step_id($s, $i++);
        next unless $s->{enabled};
        push @steps, {
            id        => $sid,
            signature => _step_signature($s),
        };
    }
    return sha256_hex(JSON::PP->new->canonical(1)->encode({
        schema    => $p->{schema},
        name      => $p->{name},
        root_dir  => File::Spec->rel2abs($p->{root_dir}),
        steps     => \@steps,
    }));
}

sub _runtime_signature {
    my @parts = ("StructureDesignProcedure-version=$VERSION");
    my $self_hash = _file_sha256(__FILE__);
    push @parts, "StructureDesignProcedure-file=$self_hash" if defined $self_hash;
    my $sd = _find_inc_file('Sim/OPT/StructureDesign.pm');
    my $sd_hash = _file_sha256($sd);
    push @parts, "StructureDesign-file=$sd_hash" if defined $sd_hash;
    my $cm = _find_inc_file('Sim/OPT/ClusterMedoid.pm');
    my $cm_hash = _file_sha256($cm);
    push @parts, "ClusterMedoid-file=$cm_hash" if defined $cm_hash;
    return sha256_hex(join("\n", @parts));
}

sub _generated_state_names {
    my ($p) = @_;
    my %seen;
    my @names;
    for my $s (@{ $p->{steps} || [] }) {
        next unless $s->{enabled};
        my $type = $s->{type} || '';
        my $generated = ($type =~ /^(?:derive|reembed|merge|reconstruct_memory)$/)
            || ($type eq 'state' && !$s->{existing});
        next unless $generated;
        my $name = $s->{name};
        next unless defined($name) && length($name) && !$seen{$name}++;
        push @names, $name;
    }
    return @names;
}

sub _archive_stale_run {
    my (%a) = @_;
    my $p = $a{procedure} or die "archive stale run: procedure required\n";
    my $manifest_path = $a{manifest_path} or die "archive stale run: manifest_path required\n";
    my $stamp = localtime->strftime('%Y%m%d-%H%M%S');
    my $archive = File::Spec->catdir(
        $p->{root_dir}, '.structuredesign', 'archive',
        $p->{name} . '-' . $stamp . '-' . $$,
    );
    make_path(File::Spec->catdir($archive, 'states'));

    if (-f $manifest_path) {
        my $dst = File::Spec->catfile($archive, 'manifest.json');
        rename $manifest_path, $dst
            or die "Cannot archive stale manifest $manifest_path -> $dst: $!\n";
    }

    my @moved;
    for my $name (_generated_state_names($p)) {
        my $src = _state_dir($p, $name);
        next unless -e $src;
        my $dst = File::Spec->catdir($archive, 'states', $name);
        rename $src, $dst
            or die "Cannot archive stale generated state $src -> $dst: $!\n";
        push @moved, $name;
    }

    my $record = {
        schema => 'Sim::OPT::StructureDesign/stale-run-archive-1',
        archived_at => _now(),
        procedure => $p->{name},
        reason => $a{reason},
        old_procedure_signature => $a{old_procedure_signature},
        new_procedure_signature => $a{new_procedure_signature},
        old_runtime_signature => $a{old_runtime_signature},
        new_runtime_signature => $a{new_runtime_signature},
        generated_states_archived => \@moved,
    };
    _write_json(File::Spec->catfile($archive, 'archive.json'), $record);
    return ($archive, \@moved);
}

sub _prepare_manifest {
    my (%a) = @_;
    my $p = $a{procedure} or die "prepare manifest: procedure required\n";
    my $path = $a{manifest_path} or die "prepare manifest: manifest_path required\n";
    my $commit = $a{commit} ? 1 : 0;
    my $old = _read_json($path);
    my $proc_sig = _procedure_signature($p);
    my $runtime_sig = _runtime_signature();

    my @reasons;
    if (-f $path) {
        push @reasons, 'manifest schema differs'
            if ($old->{schema} || '') ne 'Sim::OPT::StructureDesign/procedure-run-1';
        push @reasons, 'procedure name differs'
            if defined($old->{procedure}) && ($old->{procedure} || '') ne ($p->{name} || '');
        push @reasons, 'root directory differs'
            if defined($old->{root_dir})
                && File::Spec->rel2abs($old->{root_dir}) ne File::Spec->rel2abs($p->{root_dir});
        push @reasons, 'procedure declaration changed'
            if !defined($old->{procedure_signature}) || $old->{procedure_signature} ne $proc_sig;
        push @reasons, 'StructureDesign runtime changed'
            if !defined($old->{runtime_signature}) || $old->{runtime_signature} ne $runtime_sig;
    }

    if (@reasons) {
        my $reason = join('; ', @reasons);

        # A narrowly-scoped repair resume is safe when the procedure declaration
        # itself is unchanged and only the StructureDesign runtime changed. The
        # caller must opt in explicitly and resume from a named step; normal stale
        # handling remains conservative. Prerequisite step signatures are still
        # checked by run_procedure before execution reaches --from.
        my $runtime_only = (@reasons == 1 && $reasons[0] eq 'StructureDesign runtime changed') ? 1 : 0;
        my %tail_allowed = map { $_ => 1 } ('procedure declaration changed', 'StructureDesign runtime changed');
        my $has_proc_change = scalar grep { $_ eq 'procedure declaration changed' } @reasons;
        my $tail_change = $has_proc_change && !grep { !$tail_allowed{$_} } @reasons;
        if ($a{accept_runtime_change} && $a{from} && $runtime_only) {
            print "[StructureDesign] ACCEPT runtime-only change for explicit --from resume: $a{from}\n";
            print "[StructureDesign] PRESERVE completed prerequisite states; step signatures will be revalidated.\n";
        } elsif ($a{accept_tail_change} && $a{from} && $tail_change) {
            print "[StructureDesign] ACCEPT procedure tail change for explicit --from resume: $a{from}\n";
            print "[StructureDesign] PRESERVE completed prerequisite states; every prerequisite step signature will be revalidated.\n";
        } elsif ($a{from} || $a{only}) {
            die "Run manifest is stale ($reason). A partial --from/--only execution is unsafe. For an intentional runtime-only bugfix use --accept-runtime-change with --from. If only the selected step or later procedure declarations changed, use --accept-tail-change with --from; completed prerequisite step signatures will be checked. Otherwise run once without --from/--only so stale generated states are archived.\n";
        } elsif ($commit) {
            my ($archive, $moved) = _archive_stale_run(
                procedure => $p,
                manifest_path => $path,
                reason => $reason,
                old_procedure_signature => $old->{procedure_signature},
                new_procedure_signature => $proc_sig,
                old_runtime_signature => $old->{runtime_signature},
                new_runtime_signature => $runtime_sig,
            );
            print "[StructureDesign] STALE run manifest: $reason\n";
            print "[StructureDesign] ARCHIVED stale run at $archive\n";
            print "[StructureDesign] ARCHIVED generated states: " . join(', ', @$moved) . "\n" if @$moved;
            $old = {};
        } else {
            print "[StructureDesign] PLAN stale manifest would be archived before execution: $reason\n";
        }
    }

    $old->{schema} = 'Sim::OPT::StructureDesign/procedure-run-1';
    $old->{procedure} = $p->{name};
    $old->{procedure_file} = $p->{_procedure_file} if $p->{_procedure_file};
    $old->{root_dir} = $p->{root_dir};
    $old->{procedure_signature} = $proc_sig;
    $old->{runtime_signature} = $runtime_sig;
    $old->{runtime_version} = $VERSION;
    $old->{steps} ||= {};
    $old->{updated_at} = _now();
    return $old;
}

# -------------------------------------------------------------------------
# Filesystem/config helpers
# -------------------------------------------------------------------------

sub _state_dir {
    my ($p, $name) = @_;
    die "State name required\n" unless defined($name) && length($name);
    return File::Spec->catdir($p->{root_dir}, $name);
}

sub _state_config {
    my ($p, $state_name, $config) = @_;
    $config ||= $state_name . '.pl';
    return File::Spec->catfile(_state_dir($p, $state_name), $config);
}

sub _read_text_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $txt = <$fh>;
    close $fh;
    return $txt;
}

sub _write_text_file {
    my ($path, $txt) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} $txt;
    close $fh or die "Cannot close $path: $!\n";
}

sub _config_quote {
    my ($v) = @_;
    $v = '' unless defined $v;
    $v =~ s/\\/\\\\/g;
    $v =~ s/"/\\"/g;
    return '"' . $v . '"';
}

sub _format_sweeps_assignment {
    my ($cases) = @_;
    die "config variant: sweeps must be an ARRAY reference\n"
        unless ref($cases) eq 'ARRAY' && @$cases;
    my @out;
    for my $case (@$cases) {
        die "config variant: each sweep case must be an ARRAY reference\n"
            unless ref($case) eq 'ARRAY' && @$case;
        my @atoms;
        for my $v (@$case) {
            die "config variant: sweep atom must be scalar\n" if ref($v);
            push @atoms, (defined($v) && "$v" =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/)
                ? "$v" : _config_quote($v);
        }
        push @out, '[ [ ' . join(' , ', @atoms) . ' ] ]';
    }
    return '@sweeps = ( ' . join(', ', @out) . ' );';
}

sub _set_dowhat_string {
    my ($txt, $key, $value) = @_;
    die "config variant: invalid dowhat key '$key'\n" unless defined($key) && $key =~ /^\w+$/;
    my $q = _config_quote($value);

    my $n = ($txt =~ s/^(\s*)\Q$key\E\s*=>\s*["'][^"']*["']\s*,[^\n]*$/$1$key => $q,/m);
    return $txt if $n == 1;
    die "config variant: multiple active '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/^\s*#\s*\Q$key\E\s*=>[^\n]*$/$key => $q,/m);
    return $txt if $n == 1;
    die "config variant: multiple commented '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/(%dowhat\s*=\s*\(.*?)(^\s*\);[^\n]*$)/$1$key => $q,\n$2/ms);
    die "config variant: could not insert '$key' into %dowhat\n" unless $n == 1;
    return $txt;
}


sub _format_starpositions_value {
    my ($positions) = @_;
    die "config variant: starpositions must be an ARRAY reference\n"
        unless ref($positions) eq 'ARRAY';
    my @rows;
    for my $h (@$positions) {
        die "config variant: each starposition must be a HASH reference\n"
            unless ref($h) eq 'HASH';
        my @pairs;
        for my $v (sort { $a <=> $b } keys %$h) {
            my $lev = $h->{$v};
            die "config variant: starposition variable '$v' or level '$lev' is not an integer\n"
                unless "$v" =~ /^\d+$/ && defined($lev) && "$lev" =~ /^\d+$/;
            push @pairs, "$v => $lev";
        }
        push @rows, '        { ' . join(', ', @pairs) . ' }';
    }
    return "[\n" . join(",\n", @rows) . "\n    ]";
}

sub _set_dowhat_perl_value {
    my ($txt, $key, $value_text) = @_;
    die "config variant: perl value text required for '$key'\n"
        unless defined($value_text) && length($value_text);

    my $n = ($txt =~ s/^(\s*)\Q$key\E\s*=>\s*[^,\n]+\s*,[^\n]*$/$1$key => $value_text,/m);
    return $txt if $n == 1;
    die "config variant: multiple active '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/^\s*#\s*\Q$key\E\s*=>[^\n]*$/$key => $value_text,/m);
    return $txt if $n == 1;
    die "config variant: multiple commented '$key' entries\n" if $n > 1;

    $n = ($txt =~ s/(%dowhat\s*=\s*\(.*?)(^\s*\);[^\n]*$)/$1$key => $value_text,\n$2/ms);
    die "config variant: could not insert '$key' into %dowhat\n" unless $n == 1;
    return $txt;
}

sub _read_active_dowhat_string {
    my ($source, $key) = @_;
    die "config inheritance: source configuration required\n"
        unless defined($source) && length($source);
    die "config inheritance: key required\n"
        unless defined($key) && length($key);
    die "config inheritance: source configuration not found: $source\n"
        unless -f $source;

    my $txt = _read_text_file($source);
    my ($body) = $txt =~ /%dowhat\s*=\s*\((.*?)^\s*\);[^\n]*$/ms;
    die "config inheritance: cannot locate %dowhat in $source\n"
        unless defined $body;

    my @values = $body =~ /^(?!\s*#)\s*\Q$key\E\s*=>\s*["']([^"']*)["']\s*,/mg;
    die "config inheritance: multiple active '$key' entries in $source\n"
        if @values > 1;
    return @values ? (1, $values[0]) : (0, undef);
}

sub _resolve_inherited_dowhat {
    my (%a) = @_;
    my $step = $a{step} || {};
    my $procedure = $a{procedure} || {};
    my $inherit = $step->{inherit_dowhat};
    return {} unless defined $inherit;
    die "config inheritance: inherit_dowhat must be a HASH reference\n"
        unless ref($inherit) eq 'HASH';

    my $from_state = $inherit->{from_state};
    die "config inheritance: from_state required\n"
        unless defined($from_state) && length($from_state);
    my $config = $inherit->{config} || "$from_state.pl";
    my $keys = $inherit->{keys};
    die "config inheritance: keys must be a non-empty ARRAY reference\n"
        unless ref($keys) eq 'ARRAY' && @$keys;

    my $source_dir = _state_dir($procedure, $from_state);
    my $source = File::Spec->file_name_is_absolute($config)
        ? $config : File::Spec->catfile($source_dir, $config);

    my %values;
    for my $key (@$keys) {
        die "config inheritance: keys must contain non-empty strings\n"
            unless defined($key) && !ref($key) && length($key);
        my ($found, $value) = _read_active_dowhat_string($source, $key);
        $values{$key} = $value if $found;
    }
    return \%values;
}

sub _experience_config_variant {
    my (%a) = @_;
    my $step = $a{step} || {};
    my $base = $step->{config_variant} || {};
    die "experience config variant: config_variant must be a HASH reference\n"
        unless ref($base) eq 'HASH';

    # Clone only the variant structure that we may extend.  The procedure
    # declaration remains immutable for signature/checkpoint purposes.
    my $variant = JSON::PP->new->decode(JSON::PP->new->encode($base));
    my $inherited = _resolve_inherited_dowhat(%a);
    return $variant unless keys %$inherited;

    $variant->{dowhat} ||= {};
    die "experience config inheritance: config_variant.dowhat must be a HASH reference\n"
        unless ref($variant->{dowhat}) eq 'HASH';

    for my $key (keys %$inherited) {
        # An explicit stage override wins over an inherited user preference.
        $variant->{dowhat}{$key} = $inherited->{$key}
            unless exists $variant->{dowhat}{$key};
    }
    return $variant;
}

sub _render_config_variant {
    my (%a) = @_;
    my $source = $a{source} or die "config variant: source required\n";
    my $variant = $a{variant} || {};
    die "config variant: variant must be a HASH reference\n" unless ref($variant) eq 'HASH';
    my $txt = _read_text_file($source);

    if (defined($a{mypath}) && length($a{mypath})) {
        my $q = _config_quote($a{mypath});
        my $n = ($txt =~ s/^(?!\s*#)(\s*\$mypath\s*=\s*)["'][^"']+["']/$1$q/m);
        die "config variant: could not patch \$mypath in $source\n" unless $n == 1;
    }

    if (exists $variant->{sweeps}) {
        my $assignment = _format_sweeps_assignment($variant->{sweeps});
        my $n = ($txt =~ s/^(?!\s*#)\s*\@sweeps\s*=\s*[^;]+;/$assignment/m);
        die "config variant: could not patch active \@sweeps in $source\n" unless $n == 1;
    }

    if (exists $variant->{starpositions}) {
        my $v = _format_starpositions_value($variant->{starpositions});
        $txt = _set_dowhat_perl_value($txt, 'starpositions', $v);
    }

    if (exists $variant->{dowhat}) {
        die "config variant: dowhat must be a HASH reference\n"
            unless ref($variant->{dowhat}) eq 'HASH';
        for my $key (sort keys %{ $variant->{dowhat} }) {
            $txt = _set_dowhat_string($txt, $key, $variant->{dowhat}{$key});
        }
    }

    return "# Generated config variant by Sim::OPT::StructureDesignProcedure $VERSION\n" . $txt;
}

sub _validate_config_variant_text {
    my ($txt, $variant) = @_;
    $variant ||= {};
    die "config variant validation: text required\n" unless defined $txt;
    die "config variant validation: variant must be a HASH reference\n"
        unless ref($variant) eq 'HASH';

    if (exists $variant->{sweeps}) {
        my $want = _format_sweeps_assignment($variant->{sweeps});
        my ($got_rhs) = $txt =~ /^(?!\s*#)\s*\@sweeps\s*=\s*([^;]+);/m;
        die "config variant validation: cannot parse active \@sweeps\n" unless defined $got_rhs;
        my $got = '@sweeps = ' . $got_rhs . ';';
        (my $gc = $got) =~ s/\s+//g;
        (my $wc = $want) =~ s/\s+//g;
        die "config variant validation: active \@sweeps differs (got $got, expected $want)\n"
            unless $gc eq $wc;
    }

    if (exists $variant->{starpositions}) {
        die "config variant validation: starpositions must be an ARRAY reference\n"
            unless ref($variant->{starpositions}) eq 'ARRAY';
        my ($body) = $txt =~ /^(?!\s*#)\s*starpositions\s*=>\s*\[(.*?)\]\s*,/ms;
        die "config variant validation: cannot parse active starpositions in %dowhat\n"
            unless defined $body;
        my $count = () = $body =~ /\{[^{}]*\}/g;
        die "config variant validation: starposition count differs (got $count, expected "
            . scalar(@{ $variant->{starpositions} }) . ")\n"
            unless $count == @{ $variant->{starpositions} };
    }

    if (exists $variant->{dowhat}) {
        die "config variant validation: dowhat must be a HASH reference\n"
            unless ref($variant->{dowhat}) eq 'HASH';
        for my $key (sort keys %{ $variant->{dowhat} }) {
            my ($got) = $txt =~ /^(?!\s*#)\s*\Q$key\E\s*=>\s*["']([^"']*)["']/m;
            die "config variant validation: cannot parse active '$key' in %dowhat\n"
                unless defined $got;
            my $want = defined($variant->{dowhat}{$key}) ? "$variant->{dowhat}{$key}" : '';
            die "config variant validation: '$key' differs (got '$got', expected '$want')\n"
                unless $got eq $want;
        }
    }
    return 1;
}

sub _materialize_config_variant {
    my (%a) = @_;
    my $source = $a{source} or die "config variant: source required\n";
    my $target = $a{target} or die "config variant: target required\n";
    die "config variant: source configuration not found: $source\n" unless -f $source;
    my $variant = $a{variant} || {};
    my $txt = _render_config_variant(
        source => $source,
        mypath => $a{mypath},
        variant => $variant,
    );
    _validate_config_variant_text($txt, $variant);
    if (defined($a{geometry_manifest}) && length($a{geometry_manifest})) {
        my $gm = $a{geometry_manifest};
        die "config variant: geometry manifest not found: $gm\n" unless -f $gm;
        my $plan = _read_json($gm);
        require Sim::OPT::StructureDesign;
        Sim::OPT::StructureDesign::validate_enlarge_pan_config_text(
            $txt, $plan, target_dir => ($a{mypath} || dirname($target)),
        );
    }
    _write_text_file($target, $txt);
    return $target;
}

sub _materialize_cloned_scope_manifest {
    my (%a) = @_;
    my $source = $a{source} or die "cloned scope manifest: source required\n";
    my $target = $a{target} or die "cloned scope manifest: target required\n";
    my $source_config = $a{source_config} or die "cloned scope manifest: source_config required\n";
    my $target_config = $a{target_config} or die "cloned scope manifest: target_config required\n";
    my $source_dir = $a{source_dir} or die "cloned scope manifest: source_dir required\n";
    my $target_dir = $a{target_dir} or die "cloned scope manifest: target_dir required\n";
    die "cloned scope manifest: source not found: $source\n" unless -f $source;
    die "cloned scope manifest: source config not found: $source_config\n" unless -f $source_config;
    die "cloned scope manifest: target config not found: $target_config\n" unless -f $target_config;

    my $plan = _read_json($source);
    require Sim::OPT::StructureDesign;
    my $source_text = _read_text_file($source_config);
    Sim::OPT::StructureDesign::validate_enlarge_pan_config_text(
        $source_text, $plan, target_dir => $source_dir,
    );

    # Deep-copy the structural plan and retarget only the state identity.  The
    # target lattice, physical operations and maintained resolution remain
    # unchanged because btre is a sibling experience on btrd's design space.
    my $copy = JSON::PP->new->decode(JSON::PP->new->encode($plan));
    $copy->{child_dir} = $target_dir;
    $copy->{child_config} = basename($target_config);
    $copy->{state_clone_from} = {
        state_dir => $source_dir,
        config => basename($source_config),
        geometry_manifest => $source,
    };
    $copy->{geometry_role} = 'cloned_design_space';

    my $target_text = _read_text_file($target_config);
    Sim::OPT::StructureDesign::validate_enlarge_pan_config_text(
        $target_text, $copy, target_dir => $target_dir,
    );
    _write_json($target, $copy);
    return $target;
}


sub _copy_tree_exact {
    my ($src, $dst) = @_;
    die "copy_tree: source directory does not exist: $src\n" unless -d $src;
    die "copy_tree: destination already exists: $dst\n" if -e $dst;
    make_path($dst);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            return if $path eq $src;
            my $rel = File::Spec->abs2rel($path, $src);
            my $out = File::Spec->catfile($dst, $rel);
            if (-l $path) {
                my $link = readlink($path);
                die "Cannot read symlink $path: $!\n" unless defined $link;
                symlink($link, $out) or die "Cannot create symlink $out: $!\n";
                return;
            }
            if (-d $path) {
                make_path($out) unless -d $out;
                my $mode = (stat($path))[2];
                chmod($mode & 07777, $out) if defined $mode;
                return;
            }
            copy($path, $out) or die "Cannot copy $path -> $out: $!\n";
            my $mode = (stat($path))[2];
            chmod($mode & 07777, $out) if defined $mode;
        },
    }, $src);
}

sub _cryptolink_rows {
    my (%a) = @_;
    my $source = $a{source};
    my $root = $a{root};
    die "cryptolink_rows: source HASH required\n" unless ref($source) eq 'HASH';
    die "cryptolink_rows: model root required\n" unless defined($root) && length($root);

    my %by_short;
    my $add = sub {
        my ($short, $clear) = @_;
        return unless defined($short) && defined($clear);
        if (exists $by_short{$short} && $by_short{$short} ne $clear) {
            die "Conflicting cryptolink mappings for short id $short: '$by_short{$short}' vs '$clear'\n";
        }
        $by_short{$short} = $clear;
    };

    for my $k (keys %$source) {
        my $v = $source->{$k};
        next if ref($v) || !defined($v);

        # Compatibility with numeric short-id => clear-id maps, if encountered.
        if ($k =~ /^(\d+)$/) {
            my $short = 0 + $1;
            if ($v =~ /^((?:\d+-\d+)(?:_\d+-\d+)+)$/) {
                my $clear = $1;
                $add->($short, $clear);
                next;
            }
        }

        # Sim::OPT's native cryptolinks are absolute-path pairs in both directions:
        #   .../bt_7 <=> .../bt_1-1_2-3_...
        my $kb = basename($k);
        my $vb = basename("$v");
        if ($kb =~ /^\Q$root\E_(\d+)$/) {
            my $short = 0 + $1;
            if ($vb =~ /^\Q$root\E_((?:\d+-\d+)(?:_\d+-\d+)+)$/) {
                my $clear = $1;
                $add->($short, $clear);
                next;
            }
        }
        if ($vb =~ /^\Q$root\E_(\d+)$/) {
            my $short = 0 + $1;
            if ($kb =~ /^\Q$root\E_((?:\d+-\d+)(?:_\d+-\d+)+)$/) {
                my $clear = $1;
                $add->($short, $clear);
                next;
            }
        }
    }

    die "No Sim::OPT short-id/clear-id mappings found in source cryptolinks\n" unless keys %by_short;
    return [ map { { short => 0 + $_, local => $by_short{$_} } }
             sort { $a <=> $b } keys %by_short ];
}

sub _write_reembedded_cryptolinks {
    my (%a) = @_;
    my $path = $a{path};
    my $rows = $a{rows};
    my $target_dir = $a{target_dir};
    my $root = $a{root};
    my $mapper = $a{mapper};
    die "write_reembedded_cryptolinks: rows ARRAY required\n" unless ref($rows) eq 'ARRAY';
    die "write_reembedded_cryptolinks: mapper CODE required\n" unless ref($mapper) eq 'CODE';

    my %out;
    my @mapped;
    for my $row (@$rows) {
        my $short = $row->{short};
        my $local = $row->{local};
        my $global = $mapper->($local);
        my $short_path = File::Spec->catfile($target_dir, $root . '_' . $short);
        my $clear_path = File::Spec->catfile($target_dir, $root . '_' . $global);
        die "Re-embedding collision on clear instance '$global'\n" if exists $out{$clear_path};
        $out{$short_path} = $clear_path;
        $out{$clear_path} = $short_path;
        push @mapped, { short => 0 + $short, local => $local, global => $global };
    }
    die "No cryptolink mappings to write\n" unless @mapped;

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} "{\n";
    for my $k (sort keys %out) {
        my $v = $out{$k};
        (my $qk = $k) =~ s/([\\\"])/\\$1/g;
        (my $qv = $v) =~ s/([\\\"])/\\$1/g;
        print {$fh} qq{  "$qk" => "$qv",\n};
    }
    print {$fh} "}\n";
    close $fh or die "Cannot close $path: $!\n";
    return \@mapped;
}

sub _rewrite_totres_clear_names {
    my (%a) = @_;
    my $source = $a{source};
    my $target = $a{target};
    my $mapper = $a{mapper};
    die "rewrite_totres: source file not found: $source\n" unless -f $source;
    die "rewrite_totres: mapper CODE required\n" unless ref($mapper) eq 'CODE';
    open my $in, '<', $source or die "Cannot read $source: $!\n";
    open my $out, '>', $target or die "Cannot write $target: $!\n";
    my ($rows, %seen) = (0);
    while (my $line = <$in>) {
        if ($line =~ /^((?:\d+-\d+)(?:_\d+-\d+)+)(,.*)$/s) {
            my ($local, $rest) = ($1, $2);
            my $global = $mapper->($local);
            die "Re-embedding collision in result file on '$global'\n" if $seen{$global}++;
            print {$out} $global, $rest;
            $rows++;
        } elsif ($line =~ /\S/) {
            die "Unexpected non-result line in $source: $line";
        } else {
            print {$out} $line;
        }
    }
    close $in;
    close $out or die "Cannot close $target: $!\n";
    die "No result rows found in $source\n" unless $rows;
    return $rows;
}

sub _execute_reembed {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};

    my $from = $s->{from} or die "reembed '$s->{name}': from required\n";
    my $to = $s->{name} or die "reembed: target state name required\n";
    my $source_dir = _state_dir($p, $from);
    my $target_dir = _state_dir($p, $to);
    die "reembed '$to': source state directory not found: $source_dir\n" unless -d $source_dir;

    my $zoom_file = $s->{zoom_plan} || 'structuredesign-zoom.json';
    my $zoom_path = File::Spec->file_name_is_absolute($zoom_file)
        ? $zoom_file : File::Spec->catfile($source_dir, $zoom_file);
    die "reembed '$to': zoom plan not found: $zoom_path\n" unless -f $zoom_path;
    my $zoom = _read_json($zoom_path);
    die "reembed '$to': source plan is not a zoom_in plan\n"
        unless ref($zoom) eq 'HASH' && ($zoom->{operation} || '') eq 'zoom_in';

    require Sim::OPT::StructureDesign;
    my $root = $s->{model_root} || $zoom->{model_root} || 'bt';
    my $config_name = $s->{config} || "$to.pl";
    my $config_path = File::Spec->catfile($target_dir, $config_name);
    my $config_text = Sim::OPT::StructureDesign::render_refined_parent_config(
        $zoom,
        target_dir => $target_dir,
    );
    Sim::OPT::StructureDesign::validate_refined_parent_config_text(
        $config_text,
        $zoom,
        target_dir => $target_dir,
    );

    my $totres_name = $s->{totres} || $root . '-0_totres.csv';
    my $crypt_name = $s->{cryptolinks} || $root . '_0_cryptolinks.pl';
    my $source_totres = File::Spec->catfile($source_dir, $totres_name);
    my $source_crypt = File::Spec->catfile($source_dir, $crypt_name);
    die "reembed '$to': source result file not found: $source_totres\n" unless -f $source_totres;
    die "reembed '$to': source cryptolinks not found: $source_crypt\n" unless -f $source_crypt;

    my $mapper = sub {
        return Sim::OPT::StructureDesign::map_local_instance_to_global($_[0], $zoom);
    };
    my $inc_local = exists($s->{incumbent}) ? _resolve_reference($s->{incumbent}, $manifest) : undef;
    my $inc_global = defined($inc_local) ? $mapper->($inc_local) : undef;

    return {
        state => $to,
        from => $from,
        operation => 'reembed',
        source_totres => $source_totres,
        target_totres => File::Spec->catfile($target_dir, $totres_name),
        config => $config_path,
        incumbent_local => $inc_local,
        incumbent_global => $inc_global,
    } unless $commit;

    die "reembed '$to': refusing to overwrite existing target directory $target_dir\n" if -e $target_dir;
    my $crypt = _load_cryptolinks($source_crypt);
    die "reembed '$to': cannot parse $source_crypt\n" unless ref($crypt) eq 'HASH' && keys %$crypt;
    my $crypt_rows = _cryptolink_rows(source => $crypt, root => $root);

    make_path($target_dir);
    _write_text_file($config_path, $config_text);
    my $base_model = File::Spec->catdir($zoom->{parent_dir} || $source_dir, $root);
    _copy_tree_exact($base_model, File::Spec->catdir($target_dir, $root)) if -d $base_model;

    for my $row (@$crypt_rows) {
        my $short = $row->{short};
        my $src_model = File::Spec->catdir($source_dir, $root . '_' . $short);
        die "reembed '$to': model directory referenced by cryptolinks is missing: $src_model\n" unless -d $src_model;
        _copy_tree_exact($src_model, File::Spec->catdir($target_dir, $root . '_' . $short));
    }

    my $rows = _rewrite_totres_clear_names(
        source => $source_totres,
        target => File::Spec->catfile($target_dir, $totres_name),
        mapper => $mapper,
    );
    my $mappings = _write_reembedded_cryptolinks(
        path => File::Spec->catfile($target_dir, $crypt_name),
        rows => $crypt_rows,
        target_dir => $target_dir,
        root => $root,
        mapper => $mapper,
    );
    die "reembed '$to': result-row count ($rows) differs from cryptolink mapping count (" . scalar(@$mappings) . ")\n"
        unless $rows == @$mappings;

    my $record = {
        schema => 'Sim::OPT::StructureDesign/reembed-state-1',
        operation => 'reembed',
        from_state => $from,
        to_state => $to,
        source_dir => $source_dir,
        target_dir => $target_dir,
        model_root => $root,
        zoom_plan => $zoom_path,
        variables => $zoom->{variables},
        global_counts => $zoom->{refined_counts},
        windows => $zoom->{windows},
        result_file => $totres_name,
        cryptolinks_file => $crypt_name,
        config_file => $config_name,
        result_rows => $rows,
        incumbent_local => $inc_local,
        incumbent_global => $inc_global,
        mappings => $mappings,
    };
    _write_json(File::Spec->catfile($target_dir, 'structuredesign-reembed.json'), $record);

    return {
        state => $to,
        from => $from,
        operation => 'reembed',
        result_rows => $rows,
        incumbent => $inc_global,
        manifest => File::Spec->catfile($target_dir, 'structuredesign-reembed.json'),
        totres => File::Spec->catfile($target_dir, $totres_name),
        cryptolinks => File::Spec->catfile($target_dir, $crypt_name),
        config => $config_path,
    };
}

sub _simopt_payload_base {
    my ($payload) = @_;
    my @f = split /,/, $payload, -1;
    die "Cannot interpret empty Sim::OPT result payload\n" unless @f;

    # A finalized Sim::OPT totres row has, after the clear instance id:
    #   name,value ... (k pairs), normalized_value ... (k), weighted_sum
    # i.e. 3*k+1 payload fields.  We deliberately recover only the
    # invariant name/value pairs here; normalization is landscape-relative.
    die "Cannot infer Sim::OPT objective layout from payload '$payload'\n"
        unless @f >= 4 && ((@f - 1) % 3) == 0;
    my $k = int((@f - 1) / 3);
    die "Cannot infer Sim::OPT objective layout from payload '$payload'\n" unless $k >= 1;

    my $num = qr/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
    my (@names, @raw_text, @raw);
    for my $i (0 .. $k - 1) {
        my $name = $f[2 * $i];
        my $val  = $f[2 * $i + 1];
        die "Missing objective name in payload '$payload'\n" unless defined($name) && length($name);
        die "Non-numeric raw objective '$val' in payload '$payload'\n" unless defined($val) && $val =~ $num;
        push @names, $name;
        push @raw_text, $val;
        push @raw, 0 + $val;
    }
    return {
        objective_count => $k,
        names => \@names,
        raw_text => \@raw_text,
        raw => \@raw,
    };
}

sub _result_payloads_compatible {
    my ($a, $b, $tol) = @_;
    $tol = 1e-9 unless defined $tol;
    my $aa = _simopt_payload_base($a);
    my $bb = _simopt_payload_base($b);
    return 0 unless $aa->{objective_count} == $bb->{objective_count};
    for my $i (0 .. $aa->{objective_count} - 1) {
        return 0 unless $aa->{names}[$i] eq $bb->{names}[$i];
        my ($x, $y) = ($aa->{raw}[$i], $bb->{raw}[$i]);
        my $scale = abs($x) > abs($y) ? abs($x) : abs($y);
        $scale = 1 if $scale < 1;
        return 0 if abs($x - $y) > $tol * $scale;
    }
    return 1;
}

sub _weights_from_config {
    my ($path, $k) = @_;
    die "Cannot read merge parent config $path: $!\n" unless -f $path;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $txt = <$fh>;
    close $fh;
    my ($body) = $txt =~ /\@weights\s*=\s*\((.*?)\)\s*;/s;
    die "Cannot find active \@weights in $path\n" unless defined $body;
    $body =~ s/#.*$//mg;
    my @w;
    for my $part (split /,/, $body) {
        $part =~ s/^\s+|\s+$//g;
        next unless length $part;
        die "Non-numeric weight '$part' in $path\n"
            unless $part =~ /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
        push @w, 0 + $part;
    }
    die "Weight count in $path (" . scalar(@w) . ") does not match objective count $k\n"
        unless @w == $k;
    return \@w;
}

sub _renormalize_merged_payloads {
    my (%a) = @_;
    my $merged = $a{merged};
    my $order = $a{order};
    my $weights = $a{weights};
    die "renormalize_merged_payloads: merged HASH required\n" unless ref($merged) eq 'HASH';
    die "renormalize_merged_payloads: order ARRAY required\n" unless ref($order) eq 'ARRAY' && @$order;

    my $first = _simopt_payload_base($merged->{$order->[0]}{payload});
    my $k = $first->{objective_count};
    die "renormalize_merged_payloads: weights ARRAY required\n"
        unless ref($weights) eq 'ARRAY' && @$weights == $k;

    my @absmax = (0) x $k;
    my %base;
    for my $clear (@$order) {
        my $b = _simopt_payload_base($merged->{$clear}{payload});
        die "Merged objective count differs at '$clear'\n" unless $b->{objective_count} == $k;
        for my $i (0 .. $k - 1) {
            die "Merged objective name differs at '$clear'\n"
                unless $b->{names}[$i] eq $first->{names}[$i];
            my $av = abs($b->{raw}[$i]);
            $absmax[$i] = $av if $av > $absmax[$i];
        }
        $base{$clear} = $b;
    }

    for my $clear (@$order) {
        my $b = $base{$clear};
        my @norm;
        for my $i (0 .. $k - 1) {
            push @norm, $absmax[$i] ? ($b->{raw}[$i] / $absmax[$i]) : '';
        }
        my $wsum = 0;
        for my $i (0 .. $k - 1) {
            next if $norm[$i] eq '';
            $wsum += $norm[$i] * abs($weights->[$i]);
        }
        my @payload;
        for my $i (0 .. $k - 1) {
            push @payload, $b->{names}[$i], $b->{raw_text}[$i];
        }
        push @payload, @norm, $wsum;
        $merged->{$clear}{payload} = join(',', @payload);
    }
    return { objective_count => $k, absmaxes => \@absmax, weights => [ @$weights ] };
}

sub _read_totres_rows {
    my (%a) = @_;
    my $source = $a{source};
    my $mapper = $a{mapper};
    my $label = $a{label} || $source;
    die "read_totres_rows: source file not found: $source\n" unless -f $source;
    die "read_totres_rows: mapper CODE required\n" unless ref($mapper) eq 'CODE';
    open my $fh, '<', $source or die "Cannot read $source: $!\n";
    my (@rows, %seen);
    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next unless length($line);
        die "Unexpected non-result line in $source: $line\n"
            unless $line =~ /^((?:\d+-\d+)(?:_\d+-\d+)+),(.*)$/s;
        my ($local, $payload) = ($1, $2);
        my $clear = $mapper->($local);
        die "Duplicate mapped result '$clear' in $label\n" if $seen{$clear}++;
        push @rows, { source_clear => $local, clear => $clear, payload => $payload };
    }
    close $fh;
    die "No result rows found in $source\n" unless @rows;
    return \@rows;
}

sub _write_native_cryptolinks {
    my (%a) = @_;
    my $path = $a{path};
    my $rows = $a{rows};
    my $target_dir = $a{target_dir};
    my $root = $a{root};
    die "write_native_cryptolinks: rows ARRAY required\n" unless ref($rows) eq 'ARRAY';
    my %out;
    for my $row (@$rows) {
        my ($short, $clear) = @{$row}{qw(short clear)};
        die "write_native_cryptolinks: short and clear required\n"
            unless defined($short) && defined($clear);
        my $short_path = File::Spec->catfile($target_dir, $root . '_' . $short);
        my $clear_path = File::Spec->catfile($target_dir, $root . '_' . $clear);
        die "Cryptolink collision on '$clear'\n" if exists $out{$clear_path};
        $out{$short_path} = $clear_path;
        $out{$clear_path} = $short_path;
    }
    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} "{\n";
    for my $k (sort keys %out) {
        my $v = $out{$k};
        (my $qk = $k) =~ s/([\\\"])/\\$1/g;
        (my $qv = $v) =~ s/([\\\"])/\\$1/g;
        print {$fh} qq{  "$qk" => "$qv",\n};
    }
    print {$fh} "}\n";
    close $fh or die "Cannot close $path: $!\n";
}

sub _payload_weighted_scalar {
    my ($payload) = @_;
    die "Cannot extract weighted scalar from undefined payload\n" unless defined $payload;
    my @f = split /,/, $payload, -1;
    die "Cannot extract weighted scalar from payload '$payload'\n" unless @f;
    my $x = $f[-1];
    my $num = qr/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
    die "Non-numeric weighted scalar '$x' in payload '$payload'\n"
        unless defined($x) && $x =~ $num;
    return 0 + $x;
}

sub _best_merged_scalar_incumbent {
    my (%a) = @_;
    my $merged = $a{merged};
    my $order = $a{order};
    die "best_merged_scalar: merged HASH required\n" unless ref($merged) eq 'HASH';
    die "best_merged_scalar: order ARRAY required\n" unless ref($order) eq 'ARRAY' && @$order;
    my ($best, $best_score);
    for my $clear (@$order) {
        my $score = _payload_weighted_scalar($merged->{$clear}{payload});
        if (!defined($best) || $score > $best_score) {
            ($best, $best_score) = ($clear, $score);
        }
    }
    return ($best, $best_score);
}

sub _execute_merge {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};

    my $to = $s->{name} or die "merge: target state name required\n";
    my $parent = $s->{parent} or die "merge '$to': parent state required\n";
    my $refined = $s->{refined} or die "merge '$to': refined state required\n";
    my $parent_dir = _state_dir($p, $parent);
    my $refined_dir = _state_dir($p, $refined);
    my $target_dir = _state_dir($p, $to);
    die "merge '$to': parent state directory not found: $parent_dir\n" unless -d $parent_dir;
    die "merge '$to': refined state directory not found: $refined_dir\n" unless -d $refined_dir;

    my $zoom_file = $s->{zoom_plan} || File::Spec->catfile('btra', 'structuredesign-zoom.json');
    my $zoom_path = File::Spec->file_name_is_absolute($zoom_file)
        ? $zoom_file : File::Spec->catfile($p->{root_dir}, $zoom_file);
    die "merge '$to': zoom plan not found: $zoom_path\n" unless -f $zoom_path;
    my $zoom = _read_json($zoom_path);
    die "merge '$to': invalid zoom plan\n"
        unless ref($zoom) eq 'HASH' && ($zoom->{operation} || '') eq 'zoom_in';

    my $root = $s->{model_root} || $zoom->{model_root} || 'bt';
    my $totres_name = $s->{totres} || $root . '-0_totres.csv';
    my $crypt_name = $s->{cryptolinks} || $root . '_0_cryptolinks.pl';
    my $parent_totres = File::Spec->catfile($parent_dir, $totres_name);
    my $refined_totres = File::Spec->catfile($refined_dir, $totres_name);
    my $parent_crypt_path = File::Spec->catfile($parent_dir, $crypt_name);
    my $refined_crypt_path = File::Spec->catfile($refined_dir, $crypt_name);
    for my $f ($parent_totres, $refined_totres, $parent_crypt_path, $refined_crypt_path) {
        die "merge '$to': required source file not found: $f\n" unless -f $f;
    }

    require Sim::OPT::StructureDesign;

    # A merge changes accumulated experience, not state geometry.  The merged
    # state therefore receives an exact clone of the refined state's canonical
    # configuration, with only $mypath changed to the target directory.
    my $refined_cfg_name = $s->{refined_config} || "$refined.pl";
    my $refined_cfg_path = File::Spec->catfile($refined_dir, $refined_cfg_name);
    die "merge '$to': refined canonical config not found: $refined_cfg_path\n"
        unless -f $refined_cfg_path;
    my $refined_cfg_text = _read_text_file($refined_cfg_path);
    Sim::OPT::StructureDesign::validate_refined_parent_config_text(
        $refined_cfg_text,
        $zoom,
        target_dir => $refined_dir,
    );

    my $config_name = $s->{config} || "$to.pl";
    my $config_path = File::Spec->catfile($target_dir, $config_name);
    my $config_text = Sim::OPT::StructureDesign::render_cloned_state_config(
        $refined_cfg_path,
        target_dir => $target_dir,
    );
    Sim::OPT::StructureDesign::validate_cloned_state_config_text(
        $config_text,
        $refined_cfg_path,
        target_dir => $target_dir,
    );
    Sim::OPT::StructureDesign::validate_refined_parent_config_text(
        $config_text,
        $zoom,
        target_dir => $target_dir,
    );

    my %active = map { $_ => 1 } @{ $zoom->{variables} || [] };
    my $parent_mapper = sub {
        my ($clear) = @_;
        my $h = Sim::OPT::StructureDesign::parse_instance($clear);
        my %out = %$h;
        for my $v (keys %out) {
            next unless $active{$v};
            my $factor = 1;
            if (ref($zoom->{resolution_factors}) eq 'HASH' && exists $zoom->{resolution_factors}{$v}) {
                $factor = $zoom->{resolution_factors}{$v};
            } elsif (ref($zoom->{per_variable_axes}) eq 'HASH'
                     && ref($zoom->{per_variable_axes}{$v}) eq 'HASH'
                     && exists $zoom->{per_variable_axes}{$v}{resolution_factor}) {
                $factor = $zoom->{per_variable_axes}{$v}{resolution_factor};
            }
            my $offset = 0;
            if (ref($zoom->{parent_level_offsets}) eq 'HASH' && exists $zoom->{parent_level_offsets}{$v}) {
                $offset = 0 + $zoom->{parent_level_offsets}{$v};
            } elsif (ref($zoom->{per_variable_axes}) eq 'HASH'
                     && ref($zoom->{per_variable_axes}{$v}) eq 'HASH'
                     && exists $zoom->{per_variable_axes}{$v}{parent_level_offset}) {
                $offset = 0 + $zoom->{per_variable_axes}{$v}{parent_level_offset};
            }
            $out{$v} = $offset + Sim::OPT::StructureDesign::rescale_level($out{$v}, $factor);
        }
        return Sim::OPT::StructureDesign::format_instance(\%out);
    };
    my $identity = sub { return $_[0] };

    my $parent_rows = _read_totres_rows(source => $parent_totres, mapper => $parent_mapper, label => $parent);
    my $refined_rows = _read_totres_rows(source => $refined_totres, mapper => $identity, label => $refined);
    my $parent_crypt = _load_cryptolinks($parent_crypt_path);
    my $refined_crypt = _load_cryptolinks($refined_crypt_path);
    my $parent_links = _cryptolink_rows(source => $parent_crypt, root => $root);
    my $refined_links = _cryptolink_rows(source => $refined_crypt, root => $root);

    my (%parent_short, %refined_short);
    my $parent_max = 0;
    for my $r (@$parent_links) {
        my $g = $parent_mapper->($r->{local});
        die "merge '$to': parent cryptolink collision on '$g'\n" if exists $parent_short{$g};
        $parent_short{$g} = 0 + $r->{short};
        $parent_max = $r->{short} if $r->{short} > $parent_max;
    }
    for my $r (@$refined_links) {
        my $g = $r->{local};
        die "merge '$to': refined cryptolink collision on '$g'\n" if exists $refined_short{$g};
        $refined_short{$g} = 0 + $r->{short};
    }
    die "merge '$to': parent result/cryptolink counts differ\n" unless @$parent_rows == keys(%parent_short);
    die "merge '$to': refined result/cryptolink counts differ\n" unless @$refined_rows == keys(%refined_short);

    my (%merged, @order, @out_links, @overlaps, @copies);
    for my $r (@$parent_rows) {
        my $clear = $r->{clear};
        die "merge '$to': no parent model mapping for '$clear'\n" unless exists $parent_short{$clear};
        $merged{$clear} = { %$r, target_short => $parent_short{$clear}, source_state => $parent };
        push @order, $clear;
        push @out_links, { short => $parent_short{$clear}, clear => $clear };
        push @copies, { source_state => $parent, source_short => $parent_short{$clear}, target_short => $parent_short{$clear}, clear => $clear };
    }

    my $next_short = $parent_max;
    my $tol = exists($s->{overlap_tolerance}) ? 0 + $s->{overlap_tolerance} : 1e-9;
    for my $r (@$refined_rows) {
        my $clear = $r->{clear};
        die "merge '$to': no refined model mapping for '$clear'\n" unless exists $refined_short{$clear};
        if (exists $merged{$clear}) {
            die "merge '$to': overlapping point '$clear' has incompatible results\n"
                unless _result_payloads_compatible($merged{$clear}{payload}, $r->{payload}, $tol);
            push @overlaps, {
                clear => $clear,
                parent_short => $merged{$clear}{target_short},
                refined_short => $refined_short{$clear},
            };
            next;
        }
        my $target_short = ++$next_short;
        $merged{$clear} = { %$r, target_short => $target_short, source_state => $refined };
        push @order, $clear;
        push @out_links, { short => $target_short, clear => $clear };
        push @copies, { source_state => $refined, source_short => $refined_short{$clear}, target_short => $target_short, clear => $clear };
    }

    die "merge '$to': specify either incumbent or incumbent_policy, not both\n"
        if exists($s->{incumbent}) && defined($s->{incumbent_policy});
    my $inc = exists($s->{incumbent}) ? _resolve_reference($s->{incumbent}, $manifest) : undef;
    die "merge '$to': requested incumbent '$inc' is not in merged landscape\n"
        if defined($inc) && !exists($merged{$inc});
    my $incumbent_policy = $s->{incumbent_policy};

    # The model root names the physical model family (for example 'bt');
    # it is not necessarily the parent state's canonical configuration name.
    # For btr, for example, model_root is 'bt' while the state config is btr.pl.
    my $parent_cfg_name = $s->{parent_config} || ($parent . '.pl');
    my $parent_cfg = File::Spec->file_name_is_absolute($parent_cfg_name)
        ? $parent_cfg_name
        : File::Spec->catfile($parent_dir, $parent_cfg_name);
    my $first_base = _simopt_payload_base($merged{$order[0]}{payload});
    my $weights = ref($s->{weights}) eq 'ARRAY'
        ? [ @{ $s->{weights} } ]
        : _weights_from_config($parent_cfg, $first_base->{objective_count});
    my $normalization = _renormalize_merged_payloads(
        merged => \%merged, order => \@order, weights => $weights,
    );

    my $incumbent_score;
    if (defined($incumbent_policy)) {
        die "merge '$to': unsupported incumbent_policy '$incumbent_policy'\n"
            unless $incumbent_policy eq 'best_merged_scalar';
        ($inc, $incumbent_score) = _best_merged_scalar_incumbent(
            merged => \%merged, order => \@order,
        );
    } elsif (defined($inc)) {
        $incumbent_score = _payload_weighted_scalar($merged{$inc}{payload});
    }

    my $summary = {
        state => $to,
        operation => 'merge',
        parent => $parent,
        refined => $refined,
        parent_rows => scalar(@$parent_rows),
        refined_rows => scalar(@$refined_rows),
        overlap_rows => scalar(@overlaps),
        result_rows => scalar(@order),
        incumbent => $inc,
        incumbent_policy => $incumbent_policy,
        incumbent_score => $incumbent_score,
        overlap_comparison => 'objective_names_and_raw_values',
        normalization => $normalization,
        config => $config_path,
        geometry_source_config => $refined_cfg_path,
        target_totres => File::Spec->catfile($target_dir, $totres_name),
    };
    return $summary unless $commit;

    die "merge '$to': refusing to overwrite existing target directory $target_dir\n" if -e $target_dir;
    make_path($target_dir);
    _write_text_file($config_path, $config_text);
    my $base_model = File::Spec->catdir($parent_dir, $root);
    _copy_tree_exact($base_model, File::Spec->catdir($target_dir, $root)) if -d $base_model;

    for my $c (@copies) {
        my $src_dir = $c->{source_state} eq $parent ? $parent_dir : $refined_dir;
        my $src_model = File::Spec->catdir($src_dir, $root . '_' . $c->{source_short});
        my $dst_model = File::Spec->catdir($target_dir, $root . '_' . $c->{target_short});
        die "merge '$to': source model directory missing: $src_model\n" unless -d $src_model;
        _copy_tree_exact($src_model, $dst_model);
    }

    my $target_totres = File::Spec->catfile($target_dir, $totres_name);
    open my $tfh, '>', $target_totres or die "Cannot write $target_totres: $!\n";
    for my $clear (@order) {
        print {$tfh} $clear, ',', $merged{$clear}{payload}, "\n";
    }
    close $tfh or die "Cannot close $target_totres: $!\n";

    my $target_crypt = File::Spec->catfile($target_dir, $crypt_name);
    _write_native_cryptolinks(
        path => $target_crypt,
        rows => \@out_links,
        target_dir => $target_dir,
        root => $root,
    );

    my $record = {
        schema => 'Sim::OPT::StructureDesign/merge-state-1',
        operation => 'merge',
        parent_state => $parent,
        refined_state => $refined,
        to_state => $to,
        parent_dir => $parent_dir,
        refined_dir => $refined_dir,
        target_dir => $target_dir,
        zoom_plan => $zoom_path,
        model_root => $root,
        global_counts => $zoom->{refined_counts},
        parent_level_rule => 'new_level = parent_level_offset + 1 + resolution_factor * (old_level - 1)',
        parent_rows => scalar(@$parent_rows),
        refined_rows => scalar(@$refined_rows),
        overlap_rows => scalar(@overlaps),
        added_refined_rows => scalar(@$refined_rows) - scalar(@overlaps),
        result_rows => scalar(@order),
        overlap_tolerance => $tol,
        overlap_comparison => 'objective_names_and_raw_values',
        normalization => $normalization,
        incumbent => $inc,
        incumbent_policy => $incumbent_policy,
        incumbent_score => $incumbent_score,
        overlaps => \@overlaps,
        mappings => \@out_links,
        config_file => $config_name,
        geometry_source_config => $refined_cfg_path,
        result_file => $totres_name,
        cryptolinks_file => $crypt_name,
    };
    my $record_path = File::Spec->catfile($target_dir, 'structuredesign-merge.json');
    _write_json($record_path, $record);

    return {
        %$summary,
        config => $config_path,
        totres => $target_totres,
        cryptolinks => $target_crypt,
        manifest => $record_path,
    };
}

sub _perl_sq {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    return "'$s'";
}

sub _infer_fixed_levels_from_totres {
    my (%a) = @_;
    my $path = $a{path};
    my $counts = $a{counts};
    die "infer_fixed_levels: results file required\n" unless defined($path) && -f $path;
    die "infer_fixed_levels: counts HASH required\n" unless ref($counts) eq 'HASH' && keys %$counts;

    my %seen;
    my %seen_clear;
    my $rows = 0;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        my ($clear) = split /,/, $line, 2;
        die "Cannot read clear instance id from $path row " . ($rows + 1) . "\n"
            unless defined($clear) && length($clear);
        die "Duplicate clear instance '$clear' in $path\n" if $seen_clear{$clear}++;
        my %coord;
        while ($clear =~ /(?:^|_)(\d+)-(\d+)(?=_|$)/g) {
            $coord{0 + $1} = 0 + $2;
        }
        my @vars = sort { $a <=> $b } keys %$counts;
        my @missing = grep { !exists $coord{$_} } @vars;
        my @extra = grep { !exists $counts->{$_} && !exists $counts->{"$_"} } keys %coord;
        die "Results row " . ($rows + 1) . " variable mismatch; missing=[@missing], extra=[@extra]\n"
            if @missing || @extra;
        for my $v (@vars) {
            my $max = exists($counts->{$v}) ? $counts->{$v} : $counts->{"$v"};
            my $lev = $coord{$v};
            die "Results row " . ($rows + 1) . ": variable $v level $lev outside 1..$max\n"
                if $lev < 1 || $lev > $max;
            $seen{$v}{$lev} = 1;
        }
        $rows++;
    }
    close $fh;
    die "Results file is empty: $path\n" unless $rows;

    my %fixed;
    for my $v (sort { $a <=> $b } keys %$counts) {
        my @lev = sort { $a <=> $b } keys %{ $seen{$v} || {} };
        $fixed{$v} = $lev[0] if @lev == 1;
    }
    return (\%fixed, $rows);
}

sub _write_clustermedoid_config {
    my (%a) = @_;
    my $path = $a{path};
    my $state_dir = $a{state_dir};
    my $root = $a{root};
    my $counts = $a{counts};
    my $fixed = $a{fixed};
    my $cluster = ref($a{clustering}) eq 'HASH' ? $a{clustering} : {};
    die "write_clustermedoid_config: path required\n" unless defined($path) && length($path);
    die "write_clustermedoid_config: counts HASH required\n" unless ref($counts) eq 'HASH';
    die "write_clustermedoid_config: fixed HASH required\n" unless ref($fixed) eq 'HASH';

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} "# Generated by Sim::OPT::StructureDesignProcedure for abstraction only.\n";
    print {$fh} '$mypath = ', _perl_sq($state_dir), ";\n";
    print {$fh} '$file = ', _perl_sq($root), ";\n";
    print {$fh} "\@varinumbers = ({\n";
    for my $v (sort { $a <=> $b } keys %$counts) {
        my $L = exists($counts->{$v}) ? $counts->{$v} : $counts->{"$v"};
        print {$fh} "    $v => $L,\n";
    }
    print {$fh} "});\n";
    print {$fh} "%landscapecluster = (\n";
    print {$fh} "    sweep_index => 0,\n";
    print {$fh} "    combination_column => 0,\n";
    print {$fh} "    performance_column => 2,\n";
    print {$fh} "    header => 0,\n";
    print {$fh} "    fixed_levels => {\n";
    for my $v (sort { $a <=> $b } keys %$fixed) {
        print {$fh} "        $v => $fixed->{$v},\n";
    }
    print {$fh} "    },\n";
    print {$fh} "    context_variables => [],\n";
    print {$fh} "    lambda => 0.5,\n";
    print {$fh} "    performance => { divisions => 100 },\n";
    my $selection = $cluster->{selection} || 'silhouette';
    my $clusters = exists($cluster->{clusters}) ? $cluster->{clusters}
        : ($selection eq 'hierarchical_distortion' ? 'hierarchical' : 'auto');
    my $k_min = exists($cluster->{k_min}) ? int($cluster->{k_min}) : 2;
    my $k_max = exists($cluster->{k_max}) ? int($cluster->{k_max}) : 12;
    my $max_iterations = exists($cluster->{max_iterations}) ? int($cluster->{max_iterations}) : 50;
    my $silhouette_sample = exists($cluster->{silhouette_sample}) ? int($cluster->{silhouette_sample}) : 600;
    print {$fh} "    clustering => {\n";
    if (defined($clusters) && $clusters =~ /^\d+$/) {
        print {$fh} "        clusters => $clusters,\n";
    } else {
        print {$fh} "        clusters => ", _perl_sq($clusters), ",\n";
    }
    print {$fh} "        k_min => $k_min,\n";
    print {$fh} "        k_max => $k_max,\n";
    print {$fh} "        max_iterations => $max_iterations,\n";
    print {$fh} "        silhouette_sample => $silhouette_sample,\n";
    if (exists $cluster->{algorithm}) {
        print {$fh} "        algorithm => ", _perl_sq(lc($cluster->{algorithm})), ",\n";
    }
    for my $key (qw(max_exact_matrix_bytes clara_samples clara_sample_size clara_validation_sample random_seed)) {
        next unless exists $cluster->{$key};
        my $v = 0 + $cluster->{$key};
        print {$fh} "        $key => $v,\n";
    }
    if ($selection eq 'hierarchical_distortion') {
        my $hs = exists($cluster->{hierarchy_samples}) ? int($cluster->{hierarchy_samples}) : 3;
        my $hss = exists($cluster->{hierarchy_sample_size}) ? int($cluster->{hierarchy_sample_size}) : 512;
        my $hvs = exists($cluster->{hierarchy_validation_sample}) ? int($cluster->{hierarchy_validation_sample}) : 1024;
        my $hws = exists($cluster->{hierarchy_working_sample}) ? int($cluster->{hierarchy_working_sample}) : 4096;
        print {$fh} "        hierarchy_samples => $hs,\n";
        print {$fh} "        hierarchy_sample_size => $hss,\n";
        print {$fh} "        hierarchy_validation_sample => $hvs,\n";
        print {$fh} "        hierarchy_working_sample => $hws,\n";
    }
    print {$fh} "    },\n";
    print {$fh} ");\n1;\n";
    close $fh or die "Cannot close $path: $!\n";
}

sub _execute_abstract {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $commit = $a{commit};
    my $state = $s->{name} || $s->{state} or die "abstract: state required\n";
    my $using = $s->{using};
    my $kind = ref($using) eq 'HASH' ? ($using->{kind} || '') : '';
    die "abstract '$state': installed executor supports clustering_and_finding_medoids only\n"
        unless $kind eq 'clustering_and_finding_medoids' || $kind eq 'medoids';

    my $state_dir = _state_dir($p, $state);
    die "abstract '$state': state directory not found: $state_dir\n" unless -d $state_dir;
    my $root = $s->{model_root} || 'bt';
    my $results = File::Spec->catfile($state_dir, $s->{results_file} || ($root . '-0_totres.csv'));
    die "abstract '$state': results file not found: $results\n" unless -f $results;

    my $lattice_manifest = $s->{lattice_manifest};
    if (!defined($lattice_manifest) || !length($lattice_manifest)) {
        for my $candidate ('structuredesign-merge.json', 'structuredesign-reembed.json') {
            my $path = File::Spec->catfile($state_dir, $candidate);
            if (-f $path) { $lattice_manifest = $path; last; }
        }
    } elsif (!File::Spec->file_name_is_absolute($lattice_manifest)) {
        $lattice_manifest = File::Spec->catfile($state_dir, $lattice_manifest);
    }
    die "abstract '$state': no lattice manifest found\n"
        unless defined($lattice_manifest) && -f $lattice_manifest;
    my $lattice = _read_json($lattice_manifest);
    my $counts = $lattice->{global_counts} || $lattice->{target_counts} || $lattice->{lattice_counts};
    die "abstract '$state': lattice manifest has no global_counts, target_counts, or lattice_counts\n"
        unless ref($counts) eq 'HASH' && keys %$counts;

    my ($fixed, $rows) = _infer_fixed_levels_from_totres(path => $results, counts => $counts);
    if (defined($lattice->{result_rows})) {
        die "abstract '$state': source row count $rows differs from lattice manifest result_rows $lattice->{result_rows}\n"
            unless $rows == 0 + $lattice->{result_rows};
    }
    my $rel = $s->{output_dir} || 'abstract';
    my $out_dir = File::Spec->catdir($state_dir, $rel);
    my $prefix_name = $s->{output_prefix} || $state;
    my $prefix = File::Spec->catfile($out_dir, $prefix_name);
    my $cfg = File::Spec->catfile($out_dir, $prefix_name . '-clustermedoid.pl');

    my $summary = {
        state => $state,
        operation => 'abstract',
        method => 'clustering_and_finding_medoids',
        rows => $rows,
        fixed_levels => { %$fixed },
        results_file => $results,
        lattice_manifest => $lattice_manifest,
        output_dir => $out_dir,
        output_prefix => $prefix,
    };
    return $summary unless $commit;

    die "abstract '$state': refusing to overwrite existing output directory $out_dir\n" if -e $out_dir;
    make_path($out_dir);
    _write_clustermedoid_config(
        path => $cfg, state_dir => $state_dir, root => $root,
        counts => $counts, fixed => $fixed, clustering => $using,
    );

    require Sim::OPT::ClusterMedoid;
    my $res = Sim::OPT::ClusterMedoid::cluster_medoid(
        search_config => $cfg,
        results_file => $results,
        output_prefix => $prefix,
        verbose => $s->{verbose} ? 1 : 0,
    );
    die "abstract '$state': ClusterMedoid returned no result hash\n" unless ref($res) eq 'HASH';
    die "abstract '$state': ClusterMedoid row count $res->{rows} does not match source row count $rows\n"
        unless defined($res->{rows}) && $res->{rows} == $rows;

    my $record = {
        schema => 'Sim::OPT::StructureDesign/abstraction-1',
        operation => 'abstract',
        method => 'clustering_and_finding_medoids',
        state => $state,
        source => $s->{source} || 'experienced_landscape',
        rows => 0 + $res->{rows},
        clusters => 0 + $res->{clusters},
        silhouette => 0 + $res->{silhouette},
        lambda => 0 + $res->{lambda},
        fixed_levels => { %$fixed },
        fixed_variables => $res->{fixed_variables},
        context_variables => $res->{context_variables},
        problem_variables => $res->{problem_variables},
        performance_column => $res->{performance_column},
        lattice_manifest => $lattice_manifest,
        clustering_config => $cfg,
        results_file => $results,
        files => $res->{files},
        medoids => $res->{medoids},
        silhouette_scores => $res->{silhouette_scores},
        selection_method => $res->{selection_method},
        target_clusters => $res->{target_clusters},
        distortion_curve => $res->{distortion_curve},
        hierarchy => $res->{hierarchy},
        metric => $res->{metric},
    };
    my $record_path = File::Spec->catfile($out_dir, 'structuredesign-abstraction.json');
    _write_json($record_path, $record);

    return {
        %$summary,
        clusters => 0 + $res->{clusters},
        silhouette => 0 + $res->{silhouette},
        medoid_count => scalar(@{ $res->{medoids} || [] }),
        files => $res->{files},
        config => $cfg,
        manifest => $record_path,
    };
}

sub _read_cluster_membership_for_memory {
    my ($path) = @_;
    die "retain_memory: clustered file not found: $path\n" unless defined($path) && -f $path;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary=>1, auto_diag=>1 });
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my $header = $csv->getline($fh) or die "retain_memory: clustered file is empty: $path\n";
    my %ix = map { $header->[$_] => $_ } 0 .. $#$header;
    die "retain_memory: clustered file lacks cluster/is_medoid columns: $path\n"
        unless exists($ix{cluster}) && exists($ix{is_medoid});
    my (%membership, %medoid_flag);
    while (my $r = $csv->getline($fh)) {
        next unless @$r;
        my $id = $r->[0];
        next unless defined($id) && length($id);
        die "retain_memory: duplicate clustered instance '$id' in $path\n" if exists $membership{$id};
        $membership{$id} = 0 + $r->[$ix{cluster}];
        $medoid_flag{$id} = 0 + ($r->[$ix{is_medoid}] || 0);
    }
    close $fh;
    return (\%membership, \%medoid_flag);
}

sub _read_experience_rows_for_memory {
    my ($path) = @_;
    die "retain_memory: experience file not found: $path\n" unless defined($path) && -f $path;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary=>1, auto_diag=>1 });
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my (%rows, %line_number);
    my $n = 0;
    while (my $line = <$fh>) {
        $n++;
        $line =~ s/\r?\n\z//;
        next unless length($line);
        die "retain_memory: cannot parse CSV row $n in $path\n" unless $csv->parse($line);
        my @f = $csv->fields;
        my $id = $f[0];
        next unless defined($id) && $id =~ /(?:^|_)\d+-\d+(?:_|$)/;
        if (exists $rows{$id}) {
            die "retain_memory: conflicting duplicate experience row for '$id' in $path\n"
                if $rows{$id} ne $line;
            next;
        }
        $rows{$id} = $line;
        $line_number{$id} = $n;
    }
    close $fh;
    return (\%rows, \%line_number);
}

sub _execute_retain_memory {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $state = $s->{name} || $s->{state} or die "retain_memory: state required\n";
    my $state_dir = _state_dir($p, $state);
    die "retain_memory '$state': state directory not found: $state_dir\n" unless -d $state_dir;

    my $abs_ref = $s->{abstraction} or die "retain_memory '$state': abstraction reference required\n";
    my $abs_path = _resolve_reference($abs_ref, $manifest);
    die "retain_memory '$state': abstraction manifest not found: $abs_path\n" unless -f $abs_path;
    my $abs = _read_json($abs_path);
    die "retain_memory '$state': invalid abstraction schema\n"
        unless ref($abs) eq 'HASH' && ($abs->{schema} || '') eq 'Sim::OPT::StructureDesign/abstraction-1';
    die "retain_memory '$state': abstraction has no retained medoids\n"
        unless ref($abs->{medoids}) eq 'ARRAY' && @{ $abs->{medoids} };
    my $clustered = $abs->{files}{clustered};
    die "retain_memory '$state': abstraction does not identify its clustered file\n" unless defined($clustered);
    # Completed manifests can contain absolute paths from the production tree.
    # Prefer them when valid, otherwise resolve the basename under the current
    # abstraction directory so uploaded/relocated states remain inspectable.
    if (!-f $clustered) {
        my $candidate = File::Spec->catfile(dirname($abs_path), basename($clustered));
        $clustered = $candidate if -f $candidate;
    }
    die "retain_memory '$state': clustered file not found: $clustered\n" unless -f $clustered;

    my $exp_name = $s->{experience_file} or die "retain_memory '$state': experience_file required\n";
    my $exp_path = File::Spec->file_name_is_absolute($exp_name) ? $exp_name : File::Spec->catfile($state_dir, $exp_name);
    die "retain_memory '$state': experience file not found: $exp_path\n" unless -f $exp_path;
    my $kind = $s->{experience_kind} || 'direct_simulation';

    my ($membership, $medoid_flag) = _read_cluster_membership_for_memory($clustered);
    my ($experience, $line_number) = _read_experience_rows_for_memory($exp_path);

    my @support;
    my %by_cluster;
    for my $id (sort keys %$experience) {
        die "retain_memory '$state': experienced instance '$id' has no membership in frozen abstraction\n"
            unless exists $membership->{$id};
        my $cluster = 0 + $membership->{$id};
        push @support, {
            cluster=>$cluster, instance=>$id, row=>$experience->{$id},
            source_line=>0+$line_number->{$id}, provenance=>$kind,
        };
        $by_cluster{$cluster}++;
    }

    my @medoids;
    for my $m (@{ $abs->{medoids} }) {
        die "retain_memory '$state': malformed medoid record\n"
            unless ref($m) eq 'HASH' && defined($m->{cluster}) && defined($m->{instance});
        my $cluster = 0 + $m->{cluster};
        push @medoids, {
            cluster=>$cluster,
            instance=>$m->{instance},
            (defined($m->{performance}) ? (performance=>0+$m->{performance}) : ()),
            support_count=>0+($by_cluster{$cluster} || 0),
            medoid_is_direct_experience=>(exists($experience->{$m->{instance}}) ? JSON::PP::true : JSON::PP::false),
        };
    }

    my $rel = $s->{output_dir} || 'memory';
    my $out_dir = File::Spec->catdir($state_dir, $rel);
    my $packet_path = File::Spec->catfile($out_dir, 'structuredesign-memory-packet.json');
    my $packet = {
        schema=>'Sim::OPT::StructureDesign/memory-packet-1',
        operation=>'retain_memory',
        semantics=>'retained archetypes with cluster-conditioned direct experiential support',
        state=>$state,
        abstraction_manifest=>$abs_path,
        clustered_file=>$clustered,
        experience_file=>$exp_path,
        experience_kind=>$kind,
        assignment_basis=>'exact instance membership in the frozen antecedent clustering',
        cluster_count=>0+($abs->{clusters} || scalar(@medoids)),
        medoid_count=>scalar(@medoids),
        support_count=>scalar(@support),
        support_by_cluster=>{ map { ("$_", 0+($by_cluster{$_}||0)) } map { 0+$_->{cluster} } @medoids },
        medoids=>\@medoids,
        support=>\@support,
    };

    return {
        state=>$state, operation=>'retain_memory', abstraction=>$abs_path,
        experience_file=>$exp_path, medoid_count=>scalar(@medoids),
        support_count=>scalar(@support), support_by_cluster=>$packet->{support_by_cluster},
        manifest=>$packet_path, planned=>1,
    } unless $commit;

    die "retain_memory '$state': refusing to overwrite existing output directory $out_dir\n" if -e $out_dir;
    make_path($out_dir);
    _write_json($packet_path, $packet);
    return {
        state=>$state, operation=>'retain_memory', abstraction=>$abs_path,
        experience_file=>$exp_path, medoid_count=>scalar(@medoids),
        support_count=>scalar(@support), support_by_cluster=>$packet->{support_by_cluster},
        manifest=>$packet_path,
    };
}


sub _write_fixed_partition_medoid_config {
    my (%a) = @_;
    my $path = $a{path};
    my $metric = $a{metric};
    my $work_dir = $a{work_dir};
    die "fixed_partition_medoid_config: path required\n" unless defined($path) && length($path);
    die "fixed_partition_medoid_config: metric HASH required\n" unless ref($metric) eq 'HASH';
    my $levels = $metric->{variable_levels};
    die "fixed_partition_medoid_config: metric variable_levels HASH required\n"
        unless ref($levels) eq 'HASH' && keys %$levels;
    my $fixed = ref($metric->{fixed_levels}) eq 'HASH' ? $metric->{fixed_levels} : {};
    my $ctx = ref($metric->{context_variables}) eq 'ARRAY' ? $metric->{context_variables} : [];
    my $vw = ref($metric->{variable_weights}) eq 'HASH' ? $metric->{variable_weights} : {};
    my $cw = ref($metric->{component_weights}) eq 'HASH' ? $metric->{component_weights} : {};
    my $pc = ref($metric->{performance}) eq 'HASH' ? $metric->{performance} : {};
    for my $k (qw(best worst divisions)) {
        die "fixed_partition_medoid_config: frozen metric performance.$k required\n"
            unless exists $pc->{$k};
    }

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print {$fh} "# Generated for medoid extraction inside one frozen antecedent partition.\n";
    print {$fh} '$mypath = ', _perl_sq($work_dir), ";\n";
    print {$fh} '$file = ', _perl_sq('bt'), ";\n";
    print {$fh} "\@varinumbers = ({\n";
    for my $v (sort { $a <=> $b } keys %$levels) {
        print {$fh} "    $v => ", 0 + $levels->{$v}, ",\n";
    }
    print {$fh} "});\n";
    print {$fh} "%landscapecluster = (\n";
    print {$fh} "    sweep_index => 0,\n";
    print {$fh} "    combination_column => 0,\n";
    print {$fh} "    performance_column => 2,\n";
    print {$fh} "    header => 0,\n";
    print {$fh} "    fixed_levels => {\n";
    for my $v (sort { $a <=> $b } keys %$fixed) {
        print {$fh} "        $v => ", 0 + $fixed->{$v}, ",\n";
    }
    print {$fh} "    },\n";
    print {$fh} "    context_variables => [", join(', ', map {0+$_} @$ctx), "],\n";
    print {$fh} "    lambda => ", 0 + ($metric->{lambda} // 0.5), ",\n";
    print {$fh} "    variable_weights => {\n";
    for my $v (sort { $a <=> $b } keys %$vw) {
        print {$fh} "        $v => ", 0 + $vw->{$v}, ",\n";
    }
    print {$fh} "    },\n";
    print {$fh} "    component_weights => {\n";
    for my $k (qw(context problem performance)) {
        next unless exists $cw->{$k};
        print {$fh} "        $k => ", 0 + $cw->{$k}, ",\n";
    }
    print {$fh} "    },\n";
    print {$fh} "    performance => { best => ", 0 + $pc->{best}, ", worst => ", 0 + $pc->{worst}, ", divisions => ", 0 + $pc->{divisions}, " },\n";
    # k=1 means ClusterMedoid performs no partition discovery here.  It only
    # selects the represented case minimizing within-partition dissimilarity.
    print {$fh} "    clustering => { clusters => 1, algorithm => 'auto', max_iterations => 50 },\n";
    print {$fh} ");\n1;\n";
    close $fh or die "Cannot close $path: $!\n";
}

sub _compute_secondary_medoids_from_applied_partitions {
    my (%a) = @_;
    my $members = $a{members};
    my $metric = $a{metric};
    my $out_dir = $a{out_dir};
    my $prefix = $a{prefix} || 'secondary';
    die "secondary_medoids: members HASH required\n" unless ref($members) eq 'HASH';
    die "secondary_medoids: metric HASH required\n" unless ref($metric) eq 'HASH';
    my $work_root = File::Spec->catdir($out_dir, 'secondary-medoid-work');
    make_path($work_root);
    require Text::CSV;
    require Sim::OPT::ClusterMedoid;
    my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
    my @secondary;
    for my $cluster (sort { $a <=> $b } keys %$members) {
        my $rows = $members->{$cluster};
        next unless ref($rows) eq 'ARRAY' && @$rows;
        my $cdir = File::Spec->catdir($work_root, "cluster-$cluster");
        make_path($cdir);
        my $dataset = File::Spec->catfile($cdir, 'partition.csv');
        open my $dfh, '>', $dataset or die "Cannot write $dataset: $!\n";
        my %by_source;
        for my $r (@$rows) {
            $csv->print($dfh, [$r->{source_instance}, $r->{local_instance}, $r->{performance}]);
            $by_source{$r->{source_instance}} = $r;
        }
        close $dfh or die "Cannot close $dataset: $!\n";
        my $cfg = File::Spec->catfile($cdir, 'medoid-config.pl');
        _write_fixed_partition_medoid_config(path=>$cfg, metric=>$metric, work_dir=>$cdir);
        my $oprefix = File::Spec->catfile($cdir, 'fixed-partition');
        my $res = Sim::OPT::ClusterMedoid::cluster_medoid(
            search_config => $cfg,
            results_file => $dataset,
            output_prefix => $oprefix,
        );
        die "secondary_medoids: ClusterMedoid returned no single medoid for cluster $cluster\n"
            unless ref($res) eq 'HASH' && ref($res->{medoids}) eq 'ARRAY' && @{$res->{medoids}} == 1;
        my $m = $res->{medoids}[0];
        my $src = $m->{instance};
        my $orig = $by_source{$src} or die "secondary_medoids: selected medoid $src not found in partition $cluster\n";
        push @secondary, {
            cluster => 0 + $cluster,
            local_instance => $orig->{local_instance},
            source_instance => $src,
            performance => 0 + $orig->{performance},
            partition_size => scalar(@$rows),
            algorithm => $res->{clustering_algorithm},
            criterion => 'minimum total frozen-metric dissimilarity within fixed antecedent partition',
        };
    }
    return \@secondary;
}

sub _execute_apply_abstraction {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $state = $s->{name} || $s->{state} or die "apply_abstraction: state required\n";

    my $source_abs_path = _resolve_reference($s->{abstraction} // $s->{source_abstraction}, $manifest);
    die "apply_abstraction '$state': antecedent abstraction manifest required\n"
        unless defined($source_abs_path) && length($source_abs_path);
    die "apply_abstraction '$state': antecedent abstraction manifest not found: $source_abs_path\n"
        unless -f $source_abs_path;
    my $model = _read_json($source_abs_path);
    die "apply_abstraction '$state': invalid antecedent abstraction schema\n"
        unless ($model->{schema} || '') eq 'Sim::OPT::StructureDesign/abstraction-1';
    die "apply_abstraction '$state': antecedent abstraction does not persist its metric; frozen recall cannot be guaranteed\n"
        unless ref($model->{metric}) eq 'HASH';
    die "apply_abstraction '$state': antecedent abstraction has no retained medoids\n"
        unless ref($model->{medoids}) eq 'ARRAY' && @{$model->{medoids}};

    my $state_dir = _state_dir($p, $state);
    die "apply_abstraction '$state': state directory not found: $state_dir\n" unless -d $state_dir;
    my $root = $s->{model_root} || 'btmed';
    my $results = $s->{results_file} || ($root . '-report-0-0.csv_sortm.csv_weightordmeta.csv');
    $results = File::Spec->catfile($state_dir, $results) unless File::Spec->file_name_is_absolute($results);
    die "apply_abstraction '$state': results file not found: $results\n" unless -f $results;
    my $performance_column = exists($s->{performance_column})
        ? $s->{performance_column}
        : $model->{performance_column};
    die "apply_abstraction '$state': no performance column is defined by the step or antecedent abstraction\n"
        unless defined $performance_column;

    my $map_name = $s->{memory_manifest};
    my $map_path = defined($map_name) && length($map_name)
        ? (File::Spec->file_name_is_absolute($map_name) ? $map_name : File::Spec->catfile($state_dir, $map_name))
        : undef;
    my ($mapper, $memory_plan) = _memory_mapper_stats($map_path);
    my ($rows, $row_count) = _read_landscape_index_stats(
        path => $results, performance_column => $performance_column, mapper => $mapper,
    );
    die "apply_abstraction '$state': reconstructed landscape is empty\n" unless $row_count;

    my $rel = $s->{output_dir} || 'applied';
    my $out_dir = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($state_dir, $rel);
    my $prefix_name = $s->{output_prefix} || ($state . '-retained-categories');
    my $assignments_path = File::Spec->catfile($out_dir, $prefix_name . '.assignments.csv');
    my $record_path = File::Spec->catfile($out_dir, 'structuredesign-applied-abstraction.json');

    my $summary = {
        state => $state,
        operation => 'apply_abstraction',
        source_abstraction => $source_abs_path,
        rows => 0 + $row_count,
        clusters => 0 + ($model->{clusters} || scalar(@{$model->{medoids}})),
        retained_medoid_count => scalar(@{$model->{medoids}}),
        results_file => $results,
        performance_column => 0 + $performance_column,
        memory_manifest => $map_path,
        output_dir => $out_dir,
        assignments => $assignments_path,
    };
    return $summary unless $commit;

    die "apply_abstraction '$state': refusing to overwrite existing output directory $out_dir\n" if -e $out_dir;
    make_path($out_dir);
    require Sim::OPT::StructureDesign;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
    open my $fh, '>', $assignments_path or die "Cannot write $assignments_path: $!\n";
    $csv->print($fh, [qw(local_instance source_instance performance cluster retained_medoid_source_instance retained_medoid_performance distance_to_retained_medoid partition_semantics)]);
    my (%cluster_size, %members_by_cluster, %partition_semantics);
    for my $source_instance (sort keys %$rows) {
        my $r = $rows->{$source_instance};
        my $applied = Sim::OPT::StructureDesign::apply_abstraction_model(
            model => $model,
            instance => $source_instance,
            performance => $r->{performance},
        );
        $cluster_size{$applied->{cluster}}++;
        my $partition_semantics = $applied->{partition_semantics} || 'unspecified';
        $partition_semantics{$partition_semantics}++;
        push @{$members_by_cluster{$applied->{cluster}}}, {
            local_instance => $r->{local_instance}, source_instance => $source_instance,
            performance => 0 + $r->{performance},
        };
        $csv->print($fh, [
            $r->{local_instance}, $source_instance, $r->{performance}, $applied->{cluster},
            $applied->{medoid_instance}, $applied->{medoid_performance}, $applied->{distance}, $partition_semantics,
        ]);
    }
    close $fh or die "Cannot close $assignments_path: $!\n";

    my $secondary = _compute_secondary_medoids_from_applied_partitions(
        members => \%members_by_cluster, metric => $model->{metric}, out_dir => $out_dir, prefix => $prefix_name,
    );
    my $secondary_path = File::Spec->catfile($out_dir, $prefix_name . '.secondary-medoids.csv');
    open my $smfh, '>', $secondary_path or die "Cannot write $secondary_path: $!\n";
    $csv->print($smfh, [qw(cluster local_instance source_instance performance partition_size algorithm criterion)]);
    for my $m (@$secondary) {
        $csv->print($smfh, [$m->{cluster},$m->{local_instance},$m->{source_instance},$m->{performance},$m->{partition_size},$m->{algorithm},$m->{criterion}]);
    }
    close $smfh or die "Cannot close $secondary_path: $!\n";

    my %cluster_sizes;
    for my $c (sort { $a <=> $b } keys %cluster_size) {
        $cluster_sizes{$c} = 0 + $cluster_size{$c};
    }
    my $record = {
        schema => 'Sim::OPT::StructureDesign/applied-abstraction-2',
        operation => 'apply_abstraction',
        semantics => 'route regenerated states through the frozen antecedent partition and regenerate one medoid inside each resulting reconstructed partition',
        state => $state,
        source_abstraction => $source_abs_path,
        rows => 0 + $row_count,
        clusters => 0 + ($model->{clusters} || scalar(@{$model->{medoids}})),
        metric => $model->{metric},
        medoids => $model->{medoids},
        retained_medoid_count => scalar(@{$model->{medoids}}),
        secondary_medoids => $secondary,
        secondary_medoid_count => scalar(@$secondary),
        partition_semantics => { %partition_semantics },
        cluster_sizes => { %cluster_sizes },
        results_file => $results,
        performance_column => 0 + $performance_column,
        memory_manifest => $map_path,
        files => { assignments => $assignments_path, secondary_medoids => $secondary_path },
    };
    _write_json($record_path, $record);
    return { %$summary, manifest => $record_path, files => $record->{files}, cluster_sizes => $record->{cluster_sizes} };
}

sub _resolve_executable {
    my ($state_dir, $requested, $root_dir) = @_;
    $requested ||= 'opt';
    if (!File::Spec->file_name_is_absolute($requested)) {
        my $local = File::Spec->catfile($state_dir, $requested);
        return $local if -f $local && -x $local;
        # A blank-slate procedure commonly has the launcher only in the initial
        # bt workspace. Reuse that launcher for generated sibling states.
        if (defined($root_dir) && length($root_dir)) {
            my $initial = File::Spec->catfile($root_dir, 'bt', $requested);
            return $initial if -f $initial && -x $initial;
        }
    }
    return $requested; # exec will resolve via PATH when appropriate
}

sub _load_cryptolinks {
    my ($path) = @_;
    return {} unless -f $path;
    my $data = do $path;
    return $data if ref($data) eq 'HASH';
    open my $fh, '<', $path or return {};
    local $/; my $txt = <$fh>; close $fh;
    my %h;
    while ($txt =~ /["']([^"']+)["']\s*=>\s*(?:["']([^"']*)["']|(\d+))/g) {
        $h{$1} = defined($2) ? $2 : $3;
    }
    return \%h;
}

sub _clear_from_token {
    my (%a) = @_;
    my $token = $a{token};
    return unless defined $token;
    if ($token =~ /((?:\d+-\d+)(?:_\d+-\d+)+)/) {
        return $1;
    }
    my $short;
    if ($token =~ /^\s*(\d+)\s*$/) {
        $short = $1;
    } elsif ($token =~ /\Q$a{root}\E_(\d+)/) {
        $short = $1;
    }
    return unless defined $short;
    my $crypt = _load_cryptolinks($a{cryptolinks});
    for my $clear (keys %$crypt) {
        return $clear if defined($crypt->{$clear}) && "$crypt->{$clear}" eq "$short";
    }
    return;
}

sub _detect_winner {
    my (%a) = @_;
    my $dir  = $a{state_dir};
    my $root = $a{model_root} || 'bt';
    my $crypt = File::Spec->catfile($dir, $root . '_0_cryptolinks.pl');

    # Preferred durable source: Descend's response.txt.
    my $response = File::Spec->catfile($dir, 'response.txt');
    if (-f $response) {
        open my $fh, '<', $response or die "Cannot read $response: $!\n";
        my @candidates;
        while (my $line = <$fh>) {
            if ($line =~ /#Optimal option for case\s+\d+\s*:\s*(.*?)\.?\s*$/) {
                push @candidates, $1;
            }
        }
        close $fh;
        for my $tok (reverse @candidates) {
            my $clear = _clear_from_token(token => $tok, root => $root, cryptolinks => $crypt);
            return $clear if defined $clear;
        }
    }

    # Fallback: newest tofile/debug log, looking only for winner-labelled lines.
    opendir my $dh, $dir or die "Cannot open $dir: $!\n";
    my @logs = map { File::Spec->catfile($dir, $_) }
               grep { /tofile.*\.txt$/ && -f File::Spec->catfile($dir, $_) } readdir($dh);
    closedir $dh;
    @logs = sort { (stat($b))[9] <=> (stat($a))[9] } @logs;
    for my $log (@logs) {
        open my $fh, '<', $log or next;
        my $last;
        while (my $line = <$fh>) {
            next unless $line =~ /winner/i;
            if ($line =~ /((?:\d+-\d+)(?:_\d+-\d+)+)/) {
                $last = $1;
            } elsif ($line =~ /winneritem[^0-9]*(\d+)/i) {
                $last = $1;
            }
        }
        close $fh;
        if (defined $last) {
            my $clear = _clear_from_token(token => $last, root => $root, cryptolinks => $crypt);
            return $clear if defined $clear;
        }
    }

    return;
}

sub _read_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    local $/;
    my $txt = <$fh>;
    close $fh;
    return $txt;
}

sub _write_text_atomic {
    my ($path, $txt) = @_;
    my $tmp = "$path.tmp.$$";
    open my $fh, '>', $tmp or die "Cannot write $tmp: $!\n";
    print {$fh} $txt;
    close $fh or die "Cannot close $tmp: $!\n";
    rename $tmp, $path or die "Cannot rename $tmp -> $path: $!\n";
}

sub _replace_active_sweeps {
    my (%a) = @_;
    my $text = $a{text};
    my $replacement = $a{replacement};
    die "replace_active_sweeps: text required\n" unless defined $text;
    die "replace_active_sweeps: replacement required\n" unless defined $replacement;

    my @lines = split /(?<=\n)/, $text;
    my ($start, $end);
    for (my $i = 0; $i < @lines; $i++) {
        next unless $lines[$i] =~ /^\s*\@sweeps\s*=/;
        $start = $i;
        for (my $j = $i; $j < @lines; $j++) {
            if ($lines[$j] =~ /;/) { $end = $j; last; }
        }
        last;
    }
    die "Could not find active \@sweeps assignment in acquisition source config\n"
        unless defined($start) && defined($end);
    splice @lines, $start, ($end - $start + 1), $replacement . "\n";
    return join('', @lines);
}

sub _force_dowhat_setting {
    my (%a) = @_;
    my $text = $a{text};
    my $key = $a{key};
    my $value = $a{value};
    die "force_dowhat_setting: text required\n" unless defined $text;
    die "force_dowhat_setting: key required\n" unless defined($key) && length($key);
    die "force_dowhat_setting: value required\n" unless defined $value;

    my @lines = split /(?<=\n)/, $text;
    my ($start, $end);
    for (my $i = 0; $i < @lines; $i++) {
        next unless $lines[$i] =~ /^\s*%dowhat\s*=\s*\(/;
        $start = $i;
        for (my $j = $i + 1; $j < @lines; $j++) {
            if ($lines[$j] =~ /^\s*\)\s*;\s*(?:#.*)?$/) { $end = $j; last; }
        }
        last;
    }
    die "Could not find active %dowhat assignment in acquisition source config\n"
        unless defined($start) && defined($end);

    my $replacement = qq{${key} => "$value",\n};
    for (my $i = $start + 1; $i < $end; $i++) {
        next if $lines[$i] =~ /^\s*#/;
        if ($lines[$i] =~ /^\s*\Q$key\E\s*=>/) {
            my ($indent) = $lines[$i] =~ /^(\s*)/;
            $lines[$i] = $indent . $replacement;
            return join('', @lines);
        }
    }

    my ($indent) = $lines[$start] =~ /^(\s*)/;
    splice @lines, $start + 1, 0, $indent . $replacement;
    return join('', @lines);
}

sub _compile_star_experience {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $commit = $a{commit};
    my $state = $s->{name} || $s->{state} or die "star experience: state required\n";
    my $using = $s->{using};
    die "star experience '$state': using HASH required\n" unless ref($using) eq 'HASH';

    my $divisions = $using->{divisions};
    die "star experience '$state': divisions must be a positive integer\n"
        unless defined($divisions) && $divisions =~ /^\d+$/ && $divisions >= 1;
    die "star experience '$state': sparse real-simulation acquisition currently requires divisions => 1. In Sim::OPT, divisions > 1 creates multiple star centres and launches an axial block search from every centre; it is not a count of sampled designs.\n"
        unless $divisions == 1;

    my $vars = $using->{variables};
    die "star experience '$state': variables must be a non-empty ARRAY\n"
        unless ref($vars) eq 'ARRAY' && @$vars;
    my @vars = map {
        die "star experience '$state': variable ids must be positive integers\n"
            unless defined($_) && /^\d+$/ && $_ >= 1;
        0 + $_;
    } @$vars;
    my %seen;
    die "star experience '$state': variable ids must be unique\n"
        if grep { $seen{$_}++ } @vars;

    my $dir = _state_dir($p, $state);
    die "star experience '$state': state directory not found: $dir\n" unless -d $dir;
    my $base_name = $s->{config} || "$state.pl";
    my $base_cfg = File::Spec->catfile($dir, $base_name);
    die "star experience '$state': source config not found: $base_cfg\n" unless -f $base_cfg;

    my $compiled_name = $using->{compiled_config} || ($state . '-star.pl');
    my $compiled_cfg = File::Spec->catfile($dir, $compiled_name);
    my $marker = '1>' . $vars[0];
    my @sweep_items = ('"' . $marker . '"', map { "$_" } @vars[1 .. $#vars]);
    my $sweep_assignment = '\@sweeps = ( [ [ ' . join(' , ', @sweep_items) . ' ] ] );';
    $sweep_assignment =~ s/^\\@/@/;

    my $scope_path = File::Spec->catfile($dir, 'structuredesign-scope.json');
    die "star experience '$state': scope manifest not found: $scope_path\n" unless -f $scope_path;
    my $scope = _read_json($scope_path);
    my $counts = $scope->{target_counts};
    die "star experience '$state': scope manifest has no target_counts\n" unless ref($counts) eq 'HASH';

    my %active_counts;
    my $expected_rows = 1; # common centre is shared by every axial line
    for my $v (@vars) {
        my $L = exists($counts->{$v}) ? $counts->{$v} : $counts->{"$v"};
        die "star experience '$state': target count missing for variable $v\n" unless defined($L) && $L =~ /^\d+$/ && $L >= 1;
        $active_counts{$v} = 0 + $L;
        $expected_rows += $L - 1;
    }

    my $plan = {
        schema => 'Sim::OPT::StructureDesign/star-experience-2',
        operation => 'experience',
        acquisition => 'star',
        star_mode => 'single_centre_axial',
        state => $state,
        source_config => $base_cfg,
        acquisition_config => $compiled_cfg,
        divisions => 1,
        variables => \@vars,
        active_counts => \%active_counts,
        encoded_sweep => $sweep_assignment,
        star_centres => 1,
        expected_result_rows => 0 + $expected_rows,
        metamodel => 'n',
        outstarmode => 'n',
    };
    return $plan unless $commit;

    my $txt = _read_text($base_cfg);
    my $compiled = _replace_active_sweeps(text => $txt, replacement => $sweep_assignment);
    $compiled = _force_dowhat_setting(text => $compiled, key => 'metamodel', value => 'n');
    $compiled = _force_dowhat_setting(text => $compiled, key => 'outstarmode', value => 'n');
    _write_text_atomic($compiled_cfg, $compiled);
    return $plan;
}

sub _count_result_rows {
    my ($path) = @_;
    die "Results file not found: $path\n" unless -f $path;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my $n = 0;
    while (my $line = <$fh>) {
        $n++ if $line =~ /\S/;
    }
    close $fh;
    return $n;
}

# Detect exactly one plain numeric sweep block, e.g. [ [ 2, 4 ] ]. Encoded
# sparse/star sweep atoms such as "2>2" deliberately do not match.
sub _plain_full_factorial_variables {
    my ($config_path) = @_;
    return undef unless defined($config_path) && -f $config_path;
    my $txt = _read_text_file($config_path);
    my ($rhs) = $txt =~ /^(?!\s*#)\s*\@sweeps\s*=\s*([^;]+);/m;
    return undef unless defined $rhs;
    return undef unless $rhs =~ /^\s*\(\s*\[\s*\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]\s*\]\s*\)\s*$/;
    my @vars = map { 0 + $_ } split /\s*,\s*/, $1;
    return @vars ? \@vars : undef;
}

sub _validate_expected_factorial {
    my (%a) = @_;
    my ($state, $vars, $counts, $results) = @a{qw(state variables counts results)};
    die "experience '$state': factorial variables must be a non-empty ARRAY reference\n"
        unless ref($vars) eq 'ARRAY' && @$vars;
    die "experience '$state': factorial counts must be a HASH reference\n"
        unless ref($counts) eq 'HASH' && keys %$counts;
    my $expected = 1;
    for my $v (@$vars) {
        die "experience '$state': lattice/config lacks variable $v\n"
            unless exists($counts->{$v}) || exists($counts->{"$v"});
        my $L = exists($counts->{$v}) ? $counts->{$v} : $counts->{"$v"};
        die "experience '$state': variable $v has invalid level count '$L'\n"
            unless defined($L) && "$L" =~ /^\d+$/ && $L >= 1;
        $expected *= 0 + $L;
    }
    my $rows = _count_result_rows($results);
    die "experience '$state': expected full-factorial "
        . join('x', map { exists($counts->{$_}) ? $counts->{$_} : $counts->{"$_"} } @$vars)
        . " = $expected result rows but found $rows in $results\n"
        unless $rows == $expected;
    return ($expected, $rows);
}

sub _ensure_local_opt_launcher {
    my (%a) = @_;
    my $dir = $a{state_dir};
    my $resolved = $a{resolved};
    die "local OPT launcher: state directory required\n" unless defined($dir) && -d $dir;

    my $local = File::Spec->catfile($dir, 'opt');
    if (-e $local || -l $local) {
        die "local OPT launcher exists but is not executable: $local\n" unless -x $local;
        return $local;
    }

    # For generated StructureDesign states, preserve the user's normal launch
    # convention: every simulation is entered through a local ./opt.  The
    # configured source launcher remains authoritative; a symlink avoids
    # creating stale independent copies.  Fall back to a byte-for-byte copy on
    # filesystems where symlinks are unavailable.
    my $source = $resolved;
    $source = abs_path($source) if defined($source) && -e $source;
    die "Cannot stage local ./opt in $dir: resolved launcher '$resolved' is not an executable file\n"
        unless defined($source) && -f $source && -x $source;

    if (!symlink($source, $local)) {
        copy($source, $local) or die "Cannot copy OPT launcher $source -> $local: $!\n";
        my $mode = (stat($source))[2] & 07777;
        chmod($mode, $local) or die "Cannot chmod local OPT launcher $local: $!\n";
    }
    die "Staged local OPT launcher is not executable: $local\n" unless -x $local;
    return $local;
}

sub _run_opt {
    my (%a) = @_;
    my $dir = $a{state_dir};
    my $config = $a{config};
    die "run_opt: state directory does not exist: $dir\n" unless -d $dir;
    die "run_opt: configuration filename contains a newline\n"
        if !defined($config) || $config =~ /[\r\n]/;
    my $cfg = File::Spec->catfile($dir, $config);
    die "run_opt: configuration does not exist: $cfg\n" unless -f $cfg;
    my $resolved = _resolve_executable($dir, $a{executable}, $a{root_dir});
    _ensure_local_opt_launcher(state_dir => $dir, resolved => $resolved);

    my $cwd = getcwd();
    chdir $dir or die "Cannot chdir to $dir: $!\n";
    print "[StructureDesign] launching ./opt by heredoc in $dir with $config\n";

    # Use the same interactive entry point as a manual run:
    #
    #   ./opt <<XXX
    #   ./config.pl
    #   XXX
    #
    # The quoted delimiter prevents shell expansion of the configuration line.
    # Invoking the state-local ./opt is intentional: launch wrappers that create
    # timestamped tofile_.txt diagnostics relative to their invocation directory
    # now see exactly the same launch form as a manual run.
    my $script = "./opt <<'STRUCTUREDESIGN_OPT_CONFIG'\n"
               . "./$config\n"
               . "STRUCTUREDESIGN_OPT_CONFIG\n";
    my $rc = system('/bin/sh', '-c', $script);
    my $status = $?;
    chdir $cwd or die "Cannot restore cwd $cwd: $!\n";

    if ($rc == -1) {
        die "Cannot launch local './opt' for state $a{state}: $!\n";
    }
    if ($status & 127) {
        die "OPT failed for state $a{state} (signal " . ($status & 127) . ")\n";
    }
    my $exit = $status >> 8;
    die "OPT failed for state $a{state} (status $exit)\n" unless $exit == 0;
    return { exit_status => 0, launcher => './opt', input_mode => 'heredoc' };
}

sub _resolve_reference {
    my ($ref, $manifest) = @_;
    return $ref unless ref($ref) eq 'HASH' && $ref->{ref};
    my $sid = $ref->{step} or die "Reference has no step id\n";
    my $rec = $manifest->{steps}{$sid} or die "Reference points to unknown step '$sid'\n";
    die "Referenced step '$sid' is not COMPLETE\n" unless ($rec->{status} || '') eq 'COMPLETE';
    my $key = $ref->{ref} eq 'incumbent' ? 'incumbent' : ($ref->{key} || 'result');
    die "Referenced step '$sid' has no '$key' result\n" unless exists $rec->{result}{$key};
    return $rec->{result}{$key};
}

sub _compile_zoom {
    my (%a) = @_;
    my $step = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $from = $step->{from} or die "derive '$step->{name}': from required\n";
    my $to   = $step->{name} or die "derive: target state name required\n";
    my $by = $step->{by} || [];
    die "derive '$to': by must be ARRAY\n" unless ref($by) eq 'ARRAY';

    my ($scope, $res);
    for my $op (@$by) {
        $scope = $op if ($op->{op} || '') eq 'reduce_scope';
        $res   = $op if ($op->{op} || '') eq 'increase_resolution';
    }
    die "derive '$to': the installed executor currently supports reduce_scope + optional increase_resolution; requested procedure remains valid but needs another StructureDesign executor\n"
        unless $scope;

    my @vars = @{ $scope->{variables} || [] };
    die "derive '$to': reduce_scope.variables required\n" unless @vars;
    my $levels = $scope->{levels} // 3;
    my %factors = map { $_ => 1 } @vars;
    my %strides = map { $_ => 1 } @vars;
    if ($res) {
        my $factor = $res->{factor} // 2;
        for my $v (@{ $res->{variables} || [] }) {
            $factors{$v} = (ref($res->{factors}) eq 'HASH' && exists $res->{factors}{$v})
                ? $res->{factors}{$v} : $factor;
            $strides{$v} = (ref($res->{local_strides}) eq 'HASH' && exists $res->{local_strides}{$v})
                ? $res->{local_strides}{$v} : 1;
        }
    }
    my %local = map { $_ => $levels } @vars;

    my $around = _resolve_reference($step->{around}, $manifest);
    die "derive '$to': around/incumbent required\n" unless defined($around) && length($around);

    my $parent_cfg = _state_config($p, $from, $step->{parent_config} || "$from.pl");
    my $child_dir  = _state_dir($p, $to);
    my $child_cfg  = $step->{config} || "$to.pl";

    require Sim::OPT::StructureDesign;
    my $plan = Sim::OPT::StructureDesign::plan_zoom_in(
        parent_config => $parent_cfg,
        incumbent => $around,
        variables => \@vars,
        resolution_factors => \%factors,
        local_levels => \%local,
        local_strides => \%strides,
        (exists($step->{mediumiters}) ? (mediumiters => $step->{mediumiters}) : ()),
        (exists($step->{refined_mediumiters})
            ? (refined_mediumiters => $step->{refined_mediumiters}) : ()),
        child_dir => $child_dir,
        child_config => $child_cfg,
    );
    return $plan;
}

sub _compile_enlarge_pan {
    my (%a) = @_;
    my $step = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $from = $step->{from} or die "derive '$step->{name}': from required\n";
    my $to = $step->{name} or die "derive: target state name required\n";
    my $by = $step->{by} || [];
    die "derive '$to': by must be ARRAY\n" unless ref($by) eq 'ARRAY';

    my ($enlarge, $maintain, $pan);
    for my $op (@$by) {
        $enlarge = $op if ($op->{op} || '') eq 'enlarge_scope';
        $maintain = $op if ($op->{op} || '') eq 'maintain_resolution';
        $pan = $op if ($op->{op} || '') eq 'pan';
    }
    die "derive '$to': enlarge_scope + maintain_resolution + pan required by this executor\n"
        unless $enlarge && $maintain && $pan;

    my @vars = @{ $enlarge->{variables} || [] };
    die "derive '$to': enlarge_scope.variables required\n" unless @vars;
    if (ref($maintain->{variables}) eq 'ARRAY' && @{ $maintain->{variables} }) {
        my $vars_a = join(',', sort { $a <=> $b } @vars);
        my $vars_b = join(',', sort { $a <=> $b } @{ $maintain->{variables} });
        die "derive '$to': maintain_resolution.variables must match enlarge_scope.variables\n"
            unless $vars_a eq $vars_b;
    }

    my $around_ref = exists($pan->{around}) ? $pan->{around} : $step->{around};
    my $around = _resolve_reference($around_ref, $manifest);
    die "derive '$to': pan.around/incumbent required\n"
        unless defined($around) && length($around);

    my $source_dir = _state_dir($p, $from);
    die "derive '$to': source state directory not found: $source_dir\n" unless -d $source_dir;
    my $lm_name = $step->{lattice_manifest} || 'structuredesign-merge.json';
    my $lm_path = File::Spec->file_name_is_absolute($lm_name)
        ? $lm_name : File::Spec->catfile($source_dir, $lm_name);
    die "derive '$to': lattice manifest not found: $lm_path\n" unless -f $lm_path;
    my $lm = _read_json($lm_path);
    die "derive '$to': lattice manifest has no global_counts\n"
        unless ref($lm->{global_counts}) eq 'HASH' && keys %{ $lm->{global_counts} };
    if (defined($lm->{incumbent}) && length($lm->{incumbent}) && $lm->{incumbent} ne $around) {
        die "derive '$to': requested pan incumbent '$around' differs from source lattice incumbent '$lm->{incumbent}'\n";
    }

    my $template_name = $step->{template_config} || $step->{parent_config} || 'bt.pl';
    my $template = File::Spec->file_name_is_absolute($template_name)
        ? $template_name : File::Spec->catfile($source_dir, $template_name);
    $template = abs_path($template) || $template;
    die "derive '$to': template config not found: $template\n" unless -f $template;

    my $child_dir = _state_dir($p, $to);
    my $child_cfg = $step->{config} || "$to.pl";
    my $factor = exists($enlarge->{factor}) ? $enlarge->{factor} : 2;

    require Sim::OPT::StructureDesign;
    return Sim::OPT::StructureDesign::plan_enlarge_pan(
        template_config => $template,
        source_dir => $source_dir,
        source_counts => $lm->{global_counts},
        source_incumbent => $around,
        variables => \@vars,
        scope_factor => $factor,
        (exists($step->{mediumiters}) ? (mediumiters => $step->{mediumiters}) : ()),
        child_dir => $child_dir,
        child_config => $child_cfg,
        model_root => $step->{model_root} || $lm->{model_root} || 'bt',
        lattice_manifest => $lm_path,
    );
}


sub _reconstruct_memory_artifacts_ok {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $old = $a{old} || {};
    if (($s->{type} || '') eq 'compare') {
        my $left = $s->{left} || return 0;
        my $dir = _state_dir($p, $left);
        my $name = $s->{output_file} || 'structuredesign-comparison.json';
        my $path = File::Spec->file_name_is_absolute($name) ? $name : File::Spec->catfile($dir, $name);
        return -f $path && -s $path ? 1 : 0;
    }
    if (($s->{type} || '') eq 'abstract') {
        my $state = $s->{name} || $s->{state} || return 0;
        my $dir = _state_dir($p, $state);
        return 0 unless -d $dir;
        my $rel = $s->{output_dir} || 'abstract';
        my $out_dir = File::Spec->catdir($dir, $rel);
        return 0 unless -d $out_dir;

        my $r = ref($old->{result}) eq 'HASH' ? $old->{result} : {};
        my $mp = $r->{manifest} || File::Spec->catfile($out_dir, 'structuredesign-abstraction.json');
        return 0 unless -f $mp && -s $mp;
        my $m = eval { _read_json($mp) };
        return 0 if $@ || ref($m) ne 'HASH';
        return 0 unless ($m->{schema} || '') eq 'Sim::OPT::StructureDesign/abstraction-1';
        return 0 unless ($m->{operation} || '') eq 'abstract';
        return 0 unless defined($m->{clusters}) && 0 + $m->{clusters} >= 1;
        return 0 unless ref($m->{medoids}) eq 'ARRAY' && @{$m->{medoids}};

        # Validate every clustering product declared by the manifest.  This is
        # intentionally generic: legacy abstractions declare clustered/medoids/
        # silhouette/info, while hierarchical-distortion abstractions additionally
        # declare distortion and hierarchy.  Future declared files are checked
        # automatically without teaching the checkpoint layer their names.
        my $files = $m->{files};
        return 0 unless ref($files) eq 'HASH' && keys %$files;
        for my $path (values %$files) {
            return 0 unless defined($path) && !ref($path) && -f $path && -s $path;
        }
        if (defined($m->{clustering_config}) && length($m->{clustering_config})) {
            return 0 unless -f $m->{clustering_config} && -s $m->{clustering_config};
        }
        return 1;
    }
    if (($s->{type} || '') eq 'retain_memory') {
        my $state = $s->{name} || $s->{state} || return 0;
        my $dir = _state_dir($p, $state);
        return 0 unless -d $dir;
        my $rel = $s->{output_dir} || 'memory';
        my $out_dir = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($dir, $rel);
        my $r = ref($old->{result}) eq 'HASH' ? $old->{result} : {};
        my $mp = $r->{manifest} || File::Spec->catfile($out_dir, 'structuredesign-memory-packet.json');
        return 0 unless -f $mp && -s $mp;
        my $m = eval { _read_json($mp) };
        return 0 if $@ || ref($m) ne 'HASH';
        return 0 unless ($m->{schema} || '') eq 'Sim::OPT::StructureDesign/memory-packet-1';
        return 0 unless ($m->{operation} || '') eq 'retain_memory';
        return 0 unless ref($m->{medoids}) eq 'ARRAY' && @{$m->{medoids}};
        return 0 unless ref($m->{support}) eq 'ARRAY';
        return 0 unless defined($m->{support_count}) && 0 + $m->{support_count} == scalar(@{$m->{support}});
        return 1;
    }
    if (($s->{type} || '') eq 'apply_abstraction') {
        my $state = $s->{name} || $s->{state} || return 0;
        my $dir = _state_dir($p, $state);
        return 0 unless -d $dir;
        my $rel = $s->{output_dir} || 'applied';
        my $out_dir = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($dir, $rel);
        my $r = ref($old->{result}) eq 'HASH' ? $old->{result} : {};
        my $mp = $r->{manifest} || File::Spec->catfile($out_dir, 'structuredesign-applied-abstraction.json');
        return 0 unless -f $mp && -s $mp;
        my $m = eval { _read_json($mp) };
        return 0 if $@ || ref($m) ne 'HASH';
        return 0 unless ($m->{schema} || '') =~ /^Sim::OPT::StructureDesign\/applied-abstraction-[12]$/;
        return 0 unless ($m->{operation} || '') eq 'apply_abstraction';
        return 0 unless ref($m->{metric}) eq 'HASH';
        return 0 unless ref($m->{medoids}) eq 'ARRAY' && @{$m->{medoids}};
        return 0 unless defined($m->{rows}) && 0 + $m->{rows} >= 1;
        my $files = $m->{files};
        return 0 unless ref($files) eq 'HASH' && defined($files->{assignments});
        return 0 unless -f $files->{assignments} && -s $files->{assignments};
        return 1;
    }
    if (($s->{type} || '') eq 'statistics') {
        my $r = ref($old->{result}) eq 'HASH' ? $old->{result} : {};
        my $mp = $r->{manifest};
        return 0 unless defined($mp) && -f $mp && -s $mp;
        my $m = eval { _read_json($mp) };
        return 0 if $@ || ref($m) ne 'HASH';
        return 0 unless ($m->{schema} || '') =~ /^Sim::OPT::StructureDesign\/landscape-statistics-[12]$/;
        my $files = $m->{files};
        return 0 unless ref($files) eq 'HASH' && keys %$files;
        for my $path (values %$files) {
            return 0 unless defined($path) && !ref($path) && -f $path && -s $path;
        }
        return 1;
    }
    return 1 unless ($s->{type} || '') eq 'reconstruct_memory';
    my $dir = _state_dir($p, $s->{name});
    return 0 unless -d $dir;
    my $r = ref($old->{result}) eq 'HASH' ? $old->{result} : {};
    my $mp = $r->{manifest} || File::Spec->catfile($dir, 'structuredesign-memory.json');
    return 0 unless -f $mp && -s $mp;
    my $m = eval { _read_json($mp) };
    return 0 if $@ || ref($m) ne 'HASH';
    my $reconstruction_mode = _reconstruction_mode_for_step($s);
    if ($reconstruction_mode eq 'legacy_medoid_only') {
        return 0 unless ($m->{schema} || '') eq 'Sim::OPT::StructureDesign/memory-reconstruction-3';
        return 0 unless ($m->{mode} || '') eq 'shared_multistar_compressed';
    } else {
        return 0 unless ($m->{schema} || '') eq 'Sim::OPT::StructureDesign/memory-reconstruction-4';
        return 0 unless ($m->{mode} || '') eq 'shared_multistar_experiential_memory';
    }
    my $tot = $m->{totres};
    my $w = $m->{weightordmeta};
    return 0 unless defined($tot) && -f $tot && -s $tot;
    return 0 unless defined($w) && -f $w && -s $w;
    return 0 unless defined($m->{sampled_rows}) && defined($m->{expected_sample_rows})
        && 0 + $m->{sampled_rows} == 0 + $m->{expected_sample_rows};
    return 0 unless defined($m->{reconstructed_rows}) && defined($m->{expected_lattice_rows})
        && 0 + $m->{reconstructed_rows} == 0 + $m->{expected_lattice_rows};
    return 1;
}

sub _write_memory_seed_files {
    my (%a) = @_;
    my $plan = $a{plan};
    my $target_dir = $a{target_dir};
    my $memory_root = $a{memory_root};
    die "memory seed: plan HASH required\n" unless ref($plan) eq 'HASH';
    my $support = $plan->{retained_support};
    die "memory seed: retained_support ARRAY required\n" unless ref($support) eq 'ARRAY';
    my $totres = File::Spec->catfile($target_dir, $memory_root . '-0_totres.csv');
    my $audit = File::Spec->catfile($target_dir, 'structuredesign-memory-seed.csv');
    require Text::CSV;
    my $parse = Text::CSV->new({ binary=>1, auto_diag=>1 });
    my $write = Text::CSV->new({ binary=>1, eol=>"\n" });
    open my $tfh, '>', $totres or die "Cannot write $totres: $!\n";
    open my $afh, '>', $audit or die "Cannot write $audit: $!\n";
    $write->print($afh, [qw(local_instance source_instance cluster provenance source_line)]);
    my %seen;
    for my $r (@$support) {
        die "memory seed: malformed retained support record\n"
            unless ref($r) eq 'HASH' && defined($r->{row}) && defined($r->{local_instance}) && defined($r->{instance});
        die "memory seed: duplicate local instance '$r->{local_instance}'\n" if $seen{$r->{local_instance}}++;
        die "memory seed: cannot parse retained result row for '$r->{instance}'\n" unless $parse->parse($r->{row});
        my @f = $parse->fields;
        die "memory seed: retained result row is empty for '$r->{instance}'\n" unless @f;
        $f[0] = $r->{local_instance};
        $write->print($tfh, \@f);
        $write->print($afh, [
            $r->{local_instance}, $r->{instance}, 0+$r->{cluster},
            ($r->{provenance} || 'direct_simulation'), 0+($r->{source_line} || 0),
        ]);
    }
    close $tfh or die "Cannot close $totres: $!\n";
    close $afh or die "Cannot close $audit: $!\n";
    return { totres=>$totres, audit=>$audit, rows=>scalar(@$support) };
}

sub _reconstruction_mode_for_step {
    my ($s) = @_;
    die "reconstruct_memory: step HASH required\n" unless ref($s) eq 'HASH';
    my $mode = $s->{reconstruction_mode};
    if (!defined($mode) || !length($mode)) {
        # Historical procedure files have no retained-memory dependency.  The
        # experiential procedure does.  Preserve both meanings when old files
        # are replayed under a newer module.
        return exists($s->{memory}) && defined($s->{memory})
            ? 'experiential_cloud'
            : 'legacy_medoid_only';
    }
    die "reconstruct_memory '$s->{name}': reconstruction_mode must be 'legacy_medoid_only' or 'experiential_cloud'\n"
        unless $mode eq 'legacy_medoid_only' || $mode eq 'experiential_cloud';
    return $mode;
}

sub _execute_reconstruct_memory {
    my (%a) = @_;
    my $mode = _reconstruction_mode_for_step($a{step});
    return _execute_reconstruct_memory_legacy(%a)
        if $mode eq 'legacy_medoid_only';
    return _execute_reconstruct_memory_experiential(%a);
}

sub _execute_reconstruct_memory_legacy {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $to = $s->{name} or die "reconstruct_memory: target state name required\n";
    my $from = $s->{from} or die "reconstruct_memory '$to': from required\n";
    my $source_dir = _state_dir($p, $from);
    my $target_dir = _state_dir($p, $to);
    my $source_root = $s->{model_root} || 'bt';
    my $memory_root = $s->{memory_model_root} || 'btmed';
    die "reconstruct_memory '$to': memory_model_root must be a simple model-directory name\n"
        unless $memory_root =~ /^[A-Za-z0-9_.-]+$/;
    my $source_cfg_name = $s->{source_config} || "$from.pl";
    my $source_cfg = File::Spec->file_name_is_absolute($source_cfg_name)
        ? $source_cfg_name : File::Spec->catfile($source_dir, $source_cfg_name);
    die "reconstruct_memory '$to': source config not found: $source_cfg\n" unless -f $source_cfg;

    my $abs_ref = $s->{abstraction} or die "reconstruct_memory '$to': abstraction reference required\n";
    my $abs_path = _resolve_reference($abs_ref, $manifest);
    die "reconstruct_memory '$to': abstraction manifest not found: $abs_path\n" unless -f $abs_path;
    my $abs = _read_json($abs_path);
    die "reconstruct_memory '$to': unsupported abstraction manifest\n"
        unless ref($abs) eq 'HASH'
            && ($abs->{schema} || '') eq 'Sim::OPT::StructureDesign/abstraction-1'
            && ref($abs->{medoids}) eq 'ARRAY'
            && @{ $abs->{medoids} };

    my $vars = $s->{variables};
    $vars = $abs->{problem_variables} unless ref($vars) eq 'ARRAY' && @$vars;
    die "reconstruct_memory '$to': no problem variables available\n"
        unless ref($vars) eq 'ARRAY' && @$vars;
    my @vars = sort { $a <=> $b } map { 0 + $_ } @$vars;

    my @medoid_records = @{ $abs->{medoids} };
    if (defined $s->{medoid_limit}) {
        my $lim = 0 + $s->{medoid_limit};
        die "reconstruct_memory '$to': medoid_limit must be >= 1\n" if $lim < 1;
        @medoid_records = @medoid_records[0 .. ($lim - 1)] if @medoid_records > $lim;
    }
    my @medoids;
    for my $i (0 .. $#medoid_records) {
        my $m = $medoid_records[$i];
        die "reconstruct_memory '$to': malformed medoid record at index $i\n"
            unless ref($m) eq 'HASH' && defined($m->{instance});
        push @medoids, $m->{instance};
    }

    my $star_divisions;
    if (exists $s->{star_divisions}) {
        $star_divisions = $s->{star_divisions};
    } elsif (exists $s->{cloud_star_divisions}) {
        # Allows the same procedure declaration to change only
        # reconstruction_mode when comparing legacy and experiential recall.
        $star_divisions = $s->{cloud_star_divisions};
        die "reconstruct_memory '$to': star_divisions must be an integer >= 2\n"
            unless defined($star_divisions)
                && "$star_divisions" =~ /^\d+$/
                && $star_divisions >= 2;
    }

    require Sim::OPT::StructureDesign;
    my $inherited_dowhat = _resolve_inherited_dowhat(
        step => $s, procedure => $p,
    );
    my $plan = Sim::OPT::StructureDesign::plan_memory_reconstruction(
        source_config => $source_cfg,
        medoids => \@medoids,
        variables => \@vars,
        child_dir => $target_dir,
        child_config => ($s->{config} || 'memory.pl'),
        memory_model_root => $memory_root,
        (defined($star_divisions) ? (star_divisions => $star_divisions) : ()),
        (exists($s->{mediumiters}) ? (mediumiters => $s->{mediumiters}) : ()),
        dowhat_inherit => $inherited_dowhat,
    );

    return {
        state => $to, from => $from, operation => 'reconstruct_memory',
        reconstruction_mode => 'legacy_medoid_only',
        mode => $plan->{mode}, abstraction => $abs_path,
        medoids => scalar(@medoids), variables => \@vars,
        (defined($plan->{star_divisions}) ? (star_divisions => $plan->{star_divisions}) : ()),
        medoid_star_count => $plan->{medoid_star_count},
        subdivision_star_count => $plan->{subdivision_star_count},
        effective_star_count => $plan->{effective_star_count},
        expected_sample_rows => $plan->{expected_sample_rows},
        expected_lattice_rows => $plan->{expected_lattice_rows},
        source_model_root => $source_root, memory_model_root => $memory_root,
        target_dir => $target_dir, planned => 1,
    } unless $commit;

    die "reconstruct_memory '$to': refusing to overwrite existing target directory $target_dir\n"
        if -e $target_dir;

    # One canonical source root, one target workspace, one multi-star search.
    # The medoids are sampling centres, not separate root workspaces.
    my $root_model = File::Spec->catdir($source_dir, $source_root);
    die "reconstruct_memory '$to': canonical source root not found: $root_model\n"
        unless -d $root_model;

    Sim::OPT::StructureDesign::create_memory_workspace(
        plan => $plan, commit => 1, root_model_dir => $root_model,
    );
    my $run = _run_opt(
        state => $to,
        state_dir => $target_dir,
        config => $plan->{child_config},
        executable => $s->{executable}, root_dir => $p->{root_dir},
    );

    my $totres = File::Spec->catfile($target_dir, $memory_root . '-0_totres.csv');
    my $weight = File::Spec->catfile(
        $target_dir, $memory_root . '-report-0-0.csv_sortm.csv_weightordmeta.csv'
    );
    die "reconstruct_memory '$to': sampled totres missing or empty: $totres\n"
        unless -f $totres && -s $totres;
    die "reconstruct_memory '$to': reconstructed surrogate missing or empty: $weight\n"
        unless -f $weight && -s $weight;

    my $sample_rows = _count_result_rows($totres);
    my $reconstructed_rows = _count_result_rows($weight);
    die "reconstruct_memory '$to': multi-star totres has $sample_rows rows; expected exactly $plan->{expected_sample_rows} unique sampled instances\n"
        unless $sample_rows == $plan->{expected_sample_rows};
    die "reconstruct_memory '$to': surrogate reconstruction is incomplete: $reconstructed_rows rows in weightordmeta, expected full $plan->{expected_lattice_rows}-row lattice\n"
        unless $reconstructed_rows == $plan->{expected_lattice_rows};

    my @manifest_medoids;
    for my $i (0 .. $#medoid_records) {
        my $m = $medoid_records[$i];
        push @manifest_medoids, {
            medoid_index => $i + 1,
            cluster => (defined($m->{cluster}) ? 0 + $m->{cluster} : $i + 1),
            medoid => $m->{instance},
            (exists($m->{performance}) ? (performance => 0 + $m->{performance}) : ()),
        };
    }

    my $record = {
        schema => 'Sim::OPT::StructureDesign/memory-reconstruction-3',
        operation => 'reconstruct_memory',
        reconstruction_mode => 'legacy_medoid_only',
        mode => $plan->{mode},
        state => $to,
        from_state => $from,
        source_dir => $source_dir,
        source_config => $source_cfg,
        abstraction_manifest => $abs_path,
        source_model_root => $source_root,
        model_root => $memory_root,
        variables => \@vars,
        medoid_count => scalar(@manifest_medoids),
        medoids => \@manifest_medoids,
        source_starpositions => $plan->{source_starpositions},
        medoid_starpositions => $plan->{medoid_starpositions},
        subdivision_source_starpositions => $plan->{subdivision_source_starpositions},
        subdivision_starpositions => $plan->{subdivision_starpositions},
        starpositions => $plan->{starpositions},
        (defined($plan->{star_divisions}) ? (star_divisions => 0 + $plan->{star_divisions}) : ()),
        medoid_star_count => 0 + ($plan->{medoid_star_count} || 0),
        subdivision_star_count => 0 + ($plan->{subdivision_star_count} || 0),
        effective_star_count => 0 + ($plan->{effective_star_count} || 0),
        lattice_counts => $plan->{lattice_counts},
        per_variable_axes => $plan->{per_variable_axes},
        workspace => $target_dir,
        config => File::Spec->catfile($target_dir, $plan->{child_config}),
        local_manifest => File::Spec->catfile($target_dir, 'structuredesign-memory-local.json'),
        totres => $totres,
        weightordmeta => $weight,
        expected_sample_rows => 0 + $plan->{expected_sample_rows},
        sampled_rows => 0 + $sample_rows,
        expected_lattice_rows => 0 + $plan->{expected_lattice_rows},
        reconstructed_rows => 0 + $reconstructed_rows,
        exit_status => 0 + ($run->{exit_status} || 0),
    };
    my $record_path = File::Spec->catfile($target_dir, 'structuredesign-memory.json');
    _write_json($record_path, $record);
    return {
        state => $to, from => $from, operation => 'reconstruct_memory',
        reconstruction_mode => 'legacy_medoid_only',
        mode => $plan->{mode}, medoid_count => scalar(@manifest_medoids),
        variables => \@vars,
        (defined($plan->{star_divisions}) ? (star_divisions => $plan->{star_divisions}) : ()),
        medoid_star_count => $plan->{medoid_star_count},
        subdivision_star_count => $plan->{subdivision_star_count},
        effective_star_count => $plan->{effective_star_count},
        sampled_rows => $sample_rows,
        reconstructed_rows => $reconstructed_rows,
        manifest => $record_path, totres => $totres, weightordmeta => $weight,
    };
}

sub _execute_reconstruct_memory_experiential {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $to = $s->{name} or die "reconstruct_memory: target state name required\n";
    my $from = $s->{from} or die "reconstruct_memory '$to': from required\n";
    my $source_dir = _state_dir($p, $from);
    my $target_dir = _state_dir($p, $to);
    my $source_root = $s->{model_root} || 'bt';
    my $memory_root = $s->{memory_model_root} || 'btmed';
    die "reconstruct_memory '$to': memory_model_root must be a simple model-directory name\n"
        unless $memory_root =~ /^[A-Za-z0-9_.-]+$/;
    my $source_cfg_name = $s->{source_config} || "$from.pl";
    my $source_cfg = File::Spec->file_name_is_absolute($source_cfg_name)
        ? $source_cfg_name : File::Spec->catfile($source_dir, $source_cfg_name);
    die "reconstruct_memory '$to': source config not found: $source_cfg\n" unless -f $source_cfg;

    my $abs_ref = $s->{abstraction} or die "reconstruct_memory '$to': abstraction reference required\n";
    my $abs_path = _resolve_reference($abs_ref, $manifest);
    die "reconstruct_memory '$to': abstraction manifest not found: $abs_path\n" unless -f $abs_path;
    my $abs = _read_json($abs_path);
    die "reconstruct_memory '$to': unsupported abstraction manifest\n"
        unless ref($abs) eq 'HASH'
            && ($abs->{schema} || '') eq 'Sim::OPT::StructureDesign/abstraction-1'
            && ref($abs->{medoids}) eq 'ARRAY' && @{ $abs->{medoids} };

    my $memory_ref = $s->{memory} or die "reconstruct_memory '$to': retained memory packet reference required\n";
    my $memory_path = _resolve_reference($memory_ref, $manifest);
    die "reconstruct_memory '$to': retained memory packet not found: $memory_path\n" unless -f $memory_path;
    my $memory = _read_json($memory_path);
    die "reconstruct_memory '$to': invalid retained memory packet\n"
        unless ref($memory) eq 'HASH'
            && ($memory->{schema} || '') eq 'Sim::OPT::StructureDesign/memory-packet-1'
            && ref($memory->{medoids}) eq 'ARRAY'
            && ref($memory->{support}) eq 'ARRAY';

    my $vars = $s->{variables};
    $vars = $abs->{problem_variables} unless ref($vars) eq 'ARRAY' && @$vars;
    die "reconstruct_memory '$to': no problem variables available\n" unless ref($vars) eq 'ARRAY' && @$vars;
    my @vars = sort { $a <=> $b } map { 0 + $_ } @$vars;

    my @medoid_records = @{ $abs->{medoids} };
    if (defined $s->{medoid_limit}) {
        my $lim = 0 + $s->{medoid_limit};
        die "reconstruct_memory '$to': medoid_limit must be >= 1\n" if $lim < 1;
        @medoid_records = @medoid_records[0 .. ($lim - 1)] if @medoid_records > $lim;
    }
    my @medoids;
    my %selected_cluster;
    for my $i (0 .. $#medoid_records) {
        my $m = $medoid_records[$i];
        die "reconstruct_memory '$to': malformed medoid record at index $i\n"
            unless ref($m) eq 'HASH' && defined($m->{instance}) && defined($m->{cluster});
        push @medoids, $m->{instance};
        $selected_cluster{0+$m->{cluster}} = 1;
    }
    my %memory_medoid = map { (defined($_->{instance}) ? ($_->{instance}=>1) : ()) } @{ $memory->{medoids} };
    for my $mid (@medoids) {
        die "reconstruct_memory '$to': retained memory packet does not contain antecedent medoid '$mid'\n" unless $memory_medoid{$mid};
    }
    my $memory_for_plan = {
        %$memory,
        medoids=>[ grep { $selected_cluster{0+$_->{cluster}} } @{ $memory->{medoids} } ],
        support=>[ grep { $selected_cluster{0+$_->{cluster}} } @{ $memory->{support} } ],
    };

    my $cloud_star_divisions;
    if (exists $s->{cloud_star_divisions}) {
        $cloud_star_divisions = $s->{cloud_star_divisions};
    } elsif (exists $s->{star_divisions}) {
        $cloud_star_divisions = $s->{star_divisions};
    }
    if (defined $cloud_star_divisions) {
        die "reconstruct_memory '$to': cloud_star_divisions must be an integer >= 2\n"
            unless "$cloud_star_divisions" =~ /^\d+$/ && $cloud_star_divisions >= 2;
    }

    require Sim::OPT::StructureDesign;
    my $inherited_dowhat = _resolve_inherited_dowhat(step=>$s, procedure=>$p);
    my $plan = Sim::OPT::StructureDesign::plan_memory_reconstruction(
        source_config=>$source_cfg,
        medoids=>\@medoids,
        memory_packet=>$memory_for_plan,
        variables=>\@vars,
        child_dir=>$target_dir,
        child_config=>($s->{config} || 'memory.pl'),
        memory_model_root=>$memory_root,
        (defined($cloud_star_divisions) ? (cloud_star_divisions=>$cloud_star_divisions) : ()),
        (exists($s->{mediumiters}) ? (mediumiters=>$s->{mediumiters}) : ()),
        dowhat_inherit=>$inherited_dowhat,
    );

    return {
        state=>$to, from=>$from, operation=>'reconstruct_memory', reconstruction_mode=>'experiential_cloud', mode=>$plan->{mode},
        abstraction=>$abs_path, memory=>$memory_path,
        medoids=>scalar(@medoids), variables=>\@vars,
        (defined($plan->{cloud_star_divisions}) ? (cloud_star_divisions=>$plan->{cloud_star_divisions}) : ()),
        medoid_star_count=>$plan->{medoid_star_count}, cloud_star_count=>$plan->{cloud_star_count},
        effective_star_count=>$plan->{effective_star_count},
        retained_support_total=>$plan->{retained_support_total},
        retained_support_in_scope=>$plan->{retained_support_in_scope},
        retained_support_in_scope_by_cluster=>$plan->{retained_support_in_scope_by_cluster},
        expected_star_sample_rows=>$plan->{expected_star_sample_rows},
        expected_sample_rows=>$plan->{expected_sample_rows},
        expected_lattice_rows=>$plan->{expected_lattice_rows},
        source_model_root=>$source_root, memory_model_root=>$memory_root,
        target_dir=>$target_dir, planned=>1,
    } unless $commit;

    die "reconstruct_memory '$to': refusing to overwrite existing target directory $target_dir\n" if -e $target_dir;
    my $root_model = File::Spec->catdir($source_dir, $source_root);
    die "reconstruct_memory '$to': canonical source root not found: $root_model\n" unless -d $root_model;

    Sim::OPT::StructureDesign::create_memory_workspace(plan=>$plan, commit=>1, root_model_dir=>$root_model);
    my $seed = _write_memory_seed_files(plan=>$plan, target_dir=>$target_dir, memory_root=>$memory_root);
    my $run = _run_opt(
        state=>$to, state_dir=>$target_dir, config=>$plan->{child_config},
        executable=>$s->{executable}, root_dir=>$p->{root_dir},
    );

    my $totres = File::Spec->catfile($target_dir, $memory_root . '-0_totres.csv');
    my $weight = File::Spec->catfile($target_dir, $memory_root . '-report-0-0.csv_sortm.csv_weightordmeta.csv');
    die "reconstruct_memory '$to': sampled/remembered totres missing or empty: $totres\n" unless -f $totres && -s $totres;
    die "reconstruct_memory '$to': reconstructed surrogate missing or empty: $weight\n" unless -f $weight && -s $weight;

    my $sample_rows = _count_result_rows($totres);
    my $reconstructed_rows = _count_result_rows($weight);
    die "reconstruct_memory '$to': sampled+remembered totres has $sample_rows rows; expected exactly $plan->{expected_sample_rows} unique instances\n"
        unless $sample_rows == $plan->{expected_sample_rows};
    die "reconstruct_memory '$to': surrogate reconstruction is incomplete: $reconstructed_rows rows in weightordmeta, expected full $plan->{expected_lattice_rows}-row lattice\n"
        unless $reconstructed_rows == $plan->{expected_lattice_rows};

    my @manifest_medoids;
    for my $i (0 .. $#medoid_records) {
        my $m = $medoid_records[$i];
        push @manifest_medoids, {
            medoid_index=>$i+1, cluster=>0+$m->{cluster}, medoid=>$m->{instance},
            (exists($m->{performance}) ? (performance=>0+$m->{performance}) : ()),
        };
    }

    my $record = {
        schema=>'Sim::OPT::StructureDesign/memory-reconstruction-4',
        operation=>'reconstruct_memory', reconstruction_mode=>'experiential_cloud', mode=>$plan->{mode},
        semantics=>'medoid-anchored experiential-memory reactivation',
        scope_basis=>$plan->{scope_basis}, scope_expansions=>$plan->{scope_expansions},
        state=>$to, from_state=>$from,
        source_dir=>$source_dir, source_config=>$source_cfg,
        abstraction_manifest=>$abs_path, memory_packet=>$memory_path,
        source_model_root=>$source_root, model_root=>$memory_root,
        variables=>\@vars, medoid_count=>scalar(@manifest_medoids), medoids=>\@manifest_medoids,
        source_starpositions=>$plan->{source_starpositions},
        medoid_starpositions=>$plan->{medoid_starpositions},
        cloud_source_starpositions=>$plan->{cloud_source_starpositions},
        cloud_starpositions=>$plan->{cloud_starpositions},
        starpositions=>$plan->{starpositions},
        (defined($plan->{cloud_star_divisions}) ? (
            cloud_star_divisions=>0+$plan->{cloud_star_divisions},
            cloud_target_centres_per_cluster=>0+$plan->{cloud_target_centres_per_cluster},
        ) : ()),
        medoid_star_count=>0+($plan->{medoid_star_count}||0),
        cloud_star_count=>0+($plan->{cloud_star_count}||0),
        effective_star_count=>0+($plan->{effective_star_count}||0),
        retained_support_total=>0+$plan->{retained_support_total},
        retained_support_in_scope=>0+$plan->{retained_support_in_scope},
        retained_support_out_of_scope=>0+$plan->{retained_support_out_of_scope},
        retained_support_by_cluster=>$plan->{retained_support_by_cluster},
        retained_support_in_scope_by_cluster=>$plan->{retained_support_in_scope_by_cluster},
        lattice_counts=>$plan->{lattice_counts}, per_variable_axes=>$plan->{per_variable_axes},
        workspace=>$target_dir,
        config=>File::Spec->catfile($target_dir, $plan->{child_config}),
        local_manifest=>File::Spec->catfile($target_dir, 'structuredesign-memory-local.json'),
        seed_audit=>$seed->{audit}, totres=>$totres, weightordmeta=>$weight,
        seed_rows=>0+$seed->{rows},
        expected_star_sample_rows=>0+$plan->{expected_star_sample_rows},
        expected_sample_rows=>0+$plan->{expected_sample_rows}, sampled_rows=>0+$sample_rows,
        expected_lattice_rows=>0+$plan->{expected_lattice_rows}, reconstructed_rows=>0+$reconstructed_rows,
        exit_status=>0+($run->{exit_status}||0),
    };
    my $record_path = File::Spec->catfile($target_dir, 'structuredesign-memory.json');
    _write_json($record_path, $record);
    return {
        state=>$to, from=>$from, operation=>'reconstruct_memory', reconstruction_mode=>'experiential_cloud', mode=>$plan->{mode},
        medoid_count=>scalar(@manifest_medoids), variables=>\@vars,
        (defined($plan->{cloud_star_divisions}) ? (cloud_star_divisions=>$plan->{cloud_star_divisions}) : ()),
        medoid_star_count=>$plan->{medoid_star_count}, cloud_star_count=>$plan->{cloud_star_count},
        effective_star_count=>$plan->{effective_star_count},
        retained_support_in_scope=>$plan->{retained_support_in_scope},
        sampled_rows=>$sample_rows, reconstructed_rows=>$reconstructed_rows,
        manifest=>$record_path, totres=>$totres, weightordmeta=>$weight,
    };
}

sub _read_prediction_scores_for_ids {
    my (%a) = @_;
    my $path = $a{path};
    my $wanted = $a{wanted};
    die "prediction reader: file not found: $path\n" unless defined($path) && -f $path;
    die "prediction reader: wanted HASH required\n" unless ref($wanted) eq 'HASH';
    my %scores;
    my $num = qr/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next unless length($line);
        next unless $line =~ /^((?:\d+-\d+)(?:_\d+-\d+)+),(.*)$/s;
        my ($id, $rest) = ($1, $2);
        next unless exists $wanted->{$id};
        my @f = split /,/, $rest, -1;
        my $v = $f[-1];
        die "Non-numeric prediction for '$id' in $path: '$v'\n"
            unless defined($v) && $v =~ $num;
        die "Duplicate prediction for '$id' in $path\n" if exists $scores{$id};
        $scores{$id} = 0 + $v;
    }
    close $fh;
    return \%scores;
}

sub _reference_normalization_from_rows {
    my ($rows) = @_;
    die "reference normalization: rows ARRAY required\n" unless ref($rows) eq 'ARRAY' && @$rows;
    my $first = _simopt_payload_base($rows->[0]{payload});
    my $k = $first->{objective_count};
    my @absmax = (0) x $k;
    for my $r (@$rows) {
        my $b = _simopt_payload_base($r->{payload});
        die "Reference objective count differs at '$r->{clear}'\n" unless $b->{objective_count} == $k;
        for my $i (0 .. $k - 1) {
            die "Reference objective name differs at '$r->{clear}'\n"
                unless $b->{names}[$i] eq $first->{names}[$i];
            my $av = abs($b->{raw}[$i]);
            $absmax[$i] = $av if $av > $absmax[$i];
        }
    }
    return { names => [ @{$first->{names}} ], absmaxes => \@absmax, objective_count => $k };
}

sub _payload_score_on_reference_scale {
    my (%a) = @_;
    my $b = _simopt_payload_base($a{payload});
    my $reference = $a{reference};
    my $weights = $a{weights};
    die "payload score: reference HASH required\n" unless ref($reference) eq 'HASH';
    die "payload score: weights ARRAY required\n" unless ref($weights) eq 'ARRAY';
    my $k = $reference->{objective_count};
    die "payload score: objective count mismatch\n" unless $b->{objective_count} == $k && @$weights == $k;
    my $score = 0;
    for my $i (0 .. $k - 1) {
        die "payload score: objective name mismatch '$b->{names}[$i]' vs '$reference->{names}[$i]'\n"
            unless $b->{names}[$i] eq $reference->{names}[$i];
        my $den = $reference->{absmaxes}[$i];
        next unless $den;
        $score += ($b->{raw}[$i] / $den) * abs($weights->[$i]);
    }
    return $score;
}

sub _regression_metrics {
    my ($pairs) = @_;
    die "regression metrics: pairs ARRAY required\n" unless ref($pairs) eq 'ARRAY' && @$pairs;
    my $n = scalar(@$pairs);
    my ($sum_err, $sum_abs, $sum_sq, $max_abs, $sum_y) = (0,0,0,0,0);
    for my $p (@$pairs) {
        my $e = $p->{predicted} - $p->{actual};
        my $ae = abs($e);
        $sum_err += $e;
        $sum_abs += $ae;
        $sum_sq += $e * $e;
        $max_abs = $ae if $ae > $max_abs;
        $sum_y += $p->{actual};
    }
    my $mean_y = $sum_y / $n;
    my $sst = 0;
    for my $p (@$pairs) {
        my $d = $p->{actual} - $mean_y;
        $sst += $d * $d;
    }
    return {
        n => $n,
        mean_signed_error => $sum_err / $n,
        mae => $sum_abs / $n,
        mse => $sum_sq / $n,
        rmse => sqrt($sum_sq / $n),
        max_absolute_error => $max_abs,
        r_squared => $sst > 0 ? 1 - ($sum_sq / $sst) : undef,
    };
}

sub _clamp01_stats {
    my ($x) = @_;
    return 0 if $x < 0;
    return 1 if $x > 1;
    return $x;
}

sub _hybrid_stats {
    my ($values, $weights, $lambda) = @_;
    die "statistics hybrid: no values\n" unless ref($values) eq 'ARRAY' && @$values;
    my ($wsum, $asum, $logsum, $zero) = (0, 0, 0, 0);
    for my $i (0 .. $#$values) {
        my $v = _clamp01_stats(0 + $values->[$i]);
        my $w = 0 + $weights->[$i];
        $wsum += $w;
        $asum += $w * $v;
        if ($v <= 0) { $zero = 1; }
        else { $logsum += $w * log($v); }
    }
    die "statistics hybrid: non-positive total weight\n" unless $wsum > 0;
    my $A = $asum / $wsum;
    my $G = $zero ? 0 : exp($logsum / $wsum);
    return _clamp01_stats((1 - $lambda) * $A + $lambda * $G);
}

sub _metric_distance_from_spec {
    my (%a) = @_;
    require Sim::OPT::StructureDesign;
    return Sim::OPT::StructureDesign::abstraction_distance(%a);
}

sub _csv_column_index_stats {
    my ($spec, $n) = @_;
    $spec = 2 unless defined $spec;
    my $i = int($spec);
    $i = $n + $i if $i < 0;
    die "statistics: CSV column $spec outside row width $n\n" if $i < 0 || $i >= $n;
    return $i;
}

sub _read_landscape_index_stats {
    my (%a) = @_;
    my $path = $a{path};
    my $mapper = $a{mapper} || sub { $_[0] };
    my $wanted = $a{wanted};
    my $perfcol = $a{performance_column};
    die "statistics: landscape file not found: $path\n" unless -f $path;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my (%out, $rows);
    while (my $r = $csv->getline($fh)) {
        next unless @$r;
        my $local = $r->[0];
        next unless defined($local) && $local =~ /^(?:\d+-\d+)(?:_\d+-\d+)+$/;
        my $mapped = $mapper->($local);
        next unless defined $mapped;
        next if ref($wanted) eq 'HASH' && !$wanted->{$mapped};
        my $pi = _csv_column_index_stats($perfcol, scalar(@$r));
        my $v = $r->[$pi];
        die "statistics: non-numeric performance '$v' in $path for $local\n"
            unless defined($v) && $v =~ /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
        die "statistics: duplicate mapped instance '$mapped' in $path\n" if exists $out{$mapped};
        $out{$mapped} = { local_instance => $local, instance => $mapped, performance => 0 + $v };
        $rows++;
    }
    close $fh;
    return (\%out, 0 + ($rows || 0));
}

sub _read_sample_set_stats {
    my (%a) = @_;
    my $path = $a{path};
    return {} unless defined($path) && -f $path;
    my $mapper = $a{mapper} || sub { $_[0] };
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my %set;
    while (my $line = <$fh>) {
        if ($line =~ /^((?:\d+-\d+)(?:_\d+-\d+)+),/) {
            my $m = $mapper->($1);
            $set{$m} = 1 if defined $m;
        }
    }
    close $fh;
    return \%set;
}

sub _read_cluster_assignments_stats {
    my (%a) = @_;
    my $path = $a{path};
    my $mapper = $a{mapper} || sub { $_[0] };
    my $wanted = $a{wanted};
    die "statistics: clustered file not found: $path\n" unless -f $path;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my %out;
    my $first = 1;
    while (my $r = $csv->getline($fh)) {
        if ($first && defined($r->[0]) && $r->[0] eq 'col0') { $first = 0; next; }
        $first = 0;
        next unless @$r >= 2;
        my $local = $r->[0];
        next unless defined($local) && $local =~ /^(?:\d+-\d+)(?:_\d+-\d+)+$/;
        my $mapped = $mapper->($local);
        next unless defined $mapped;
        next if ref($wanted) eq 'HASH' && !$wanted->{$mapped};
        my $cluster = $r->[-2];
        next unless defined($cluster) && $cluster =~ /^\d+$/;
        $out{$mapped} = 0 + $cluster;
    }
    close $fh;
    return \%out;
}

sub _read_applied_assignments_stats {
    my (%a) = @_;
    my $path = $a{path};
    my $wanted = $a{wanted};
    die "statistics: applied assignments file not found: $path\n" unless defined($path) && -f $path;
    require Text::CSV;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
    open my $fh, '<', $path or die "Cannot read $path: $!\n";
    my $header = $csv->getline($fh);
    die "statistics: applied assignments file is empty: $path\n" unless ref($header) eq 'ARRAY';
    my %ix;
    $ix{$header->[$_]} = $_ for 0 .. $#$header;
    for my $name (qw(local_instance source_instance performance cluster retained_medoid_source_instance retained_medoid_performance distance_to_retained_medoid)) {
        die "statistics: applied assignments file lacks '$name': $path\n" unless exists $ix{$name};
    }
    my %out;
    while (my $r = $csv->getline($fh)) {
        my $source = $r->[$ix{source_instance}];
        next unless defined($source) && length($source);
        next if ref($wanted) eq 'HASH' && !$wanted->{$source};
        die "statistics: duplicate applied source instance '$source' in $path\n" if exists $out{$source};
        my $cluster = $r->[$ix{cluster}];
        my $distance = $r->[$ix{distance_to_retained_medoid}];
        die "statistics: non-numeric applied cluster '$cluster' for $source\n"
            unless defined($cluster) && $cluster =~ /^\d+$/;
        die "statistics: non-numeric applied distance '$distance' for $source\n"
            unless defined($distance) && $distance =~ /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][+-]?\d+)?$/;
        $out{$source} = {
            local_instance => $r->[$ix{local_instance}],
            source_instance => $source,
            performance => 0 + $r->[$ix{performance}],
            cluster => 0 + $cluster,
            retained_medoid_source_instance => $r->[$ix{retained_medoid_source_instance}],
            retained_medoid_performance => 0 + $r->[$ix{retained_medoid_performance}],
            distance => 0 + $distance,
        };
    }
    close $fh;
    return \%out;
}

sub _metric_from_abstraction_stats {
    my ($abs) = @_;
    return $abs->{metric} if ref($abs->{metric}) eq 'HASH';
    my $lm = _read_json($abs->{lattice_manifest});
    my $levels = $lm->{global_counts} || $lm->{target_counts} || $lm->{lattice_counts};
    die "statistics: cannot derive metric levels from abstraction manifest\n"
        unless ref($levels) eq 'HASH';
    my ($idx) = _read_landscape_index_stats(
        path => $abs->{results_file}, performance_column => $abs->{performance_column},
    );
    my @p = map { $_->{performance} } values %$idx;
    die "statistics: cannot derive performance range\n" unless @p;
    my ($best, $worst) = ($p[0], $p[0]);
    for (@p) { $best = $_ if $_ < $best; $worst = $_ if $_ > $worst; }
    my %vw = map { $_ => 1 } keys %$levels;
    return {
        schema => 'Sim::OPT::ClusterMedoid/hybrid-distance-1-fallback',
        variable_levels => { %$levels },
        fixed_levels => { %{ $abs->{fixed_levels} || {} } },
        context_variables => [ @{ $abs->{context_variables} || [] } ],
        problem_variables => [ @{ $abs->{problem_variables} || [] } ],
        lambda => 0 + ($abs->{lambda} // 0.5),
        variable_weights => \%vw,
        component_weights => { context => 1, problem => 1, performance => 1 },
        performance => { best => $best, worst => $worst, divisions => 100 },
    };
}

sub _memory_mapper_stats {
    my ($path) = @_;
    return (sub { $_[0] }, undef) unless defined($path) && length($path);
    die "statistics: memory mapping manifest not found: $path\n" unless -f $path;
    my $plan = _read_json($path);
    require Sim::OPT::StructureDesign;
    my $mapper = sub {
        return Sim::OPT::StructureDesign::map_memory_instance_to_source($_[0], $plan);
    };
    return ($mapper, $plan);
}

sub _optimal_medoid_matching_stats {
    my ($left, $right, $metric) = @_;
    my $nl = @$left; my $nr = @$right;
    return [] unless $nl && $nr;
    my ($small, $large, $swapped) = $nl <= $nr ? ($left, $right, 0) : ($right, $left, 1);
    my $ns = @$small; my $ng = @$large;
    my @cost;
    for my $i (0 .. $ns-1) {
        for my $j (0 .. $ng-1) {
            my ($L, $R) = $swapped ? ($large->[$j], $small->[$i]) : ($small->[$i], $large->[$j]);
            $cost[$i][$j] = _metric_distance_from_spec(
                metric => $metric,
                instance_a => $L->{source_instance}, performance_a => $L->{performance},
                instance_b => $R->{source_instance}, performance_b => $R->{performance},
            );
        }
    }
    my %dp = (0 => [0, []]);
    for my $i (0 .. $ns-1) {
        my %next;
        while (my ($mask, $state) = each %dp) {
            for my $j (0 .. $ng-1) {
                next if $mask & (1 << $j);
                my $nm = $mask | (1 << $j);
                my $nc = $state->[0] + $cost[$i][$j];
                if (!exists($next{$nm}) || $nc < $next{$nm}[0]) {
                    $next{$nm} = [$nc, [ @{$state->[1]}, $j ]];
                }
            }
        }
        %dp = %next;
    }
    my ($best) = sort { $dp{$a}[0] <=> $dp{$b}[0] } keys %dp;
    my @sel = @{ $dp{$best}[1] };
    my @pairs;
    for my $i (0 .. $#sel) {
        my $j = $sel[$i];
        my ($li, $ri) = $swapped ? ($j, $i) : ($i, $j);
        push @pairs, { left_index => $li, right_index => $ri, distance => 0 + $cost[$i][$j] };
    }
    return \@pairs;
}

sub _ari_stats {
    my ($pairs) = @_;
    return undef unless ref($pairs) eq 'ARRAY' && @$pairs >= 2;
    my (%a, %b, %ab);
    for my $p (@$pairs) {
        $a{$p->[0]}++; $b{$p->[1]}++; $ab{$p->[0]}{$p->[1]}++;
    }
    my $c2 = sub { my ($n)=@_; return $n < 2 ? 0 : $n*($n-1)/2; };
    my $sum_ab = 0; for my $x (keys %ab) { $sum_ab += $c2->($_) for values %{$ab{$x}}; }
    my $sum_a = 0; $sum_a += $c2->($_) for values %a;
    my $sum_b = 0; $sum_b += $c2->($_) for values %b;
    my $total = $c2->(scalar(@$pairs));
    return undef unless $total > 0;
    my $expected = ($sum_a * $sum_b) / $total;
    my $maxi = 0.5 * ($sum_a + $sum_b);
    return 1 if abs($maxi - $expected) < 1e-15 && abs($sum_ab - $expected) < 1e-15;
    return ($sum_ab - $expected) / ($maxi - $expected) if abs($maxi - $expected) >= 1e-15;
    return undef;
}

sub _median_stats {
    my (@v) = sort { $a <=> $b } @_;
    return undef unless @v;
    return $v[int(@v/2)] if @v % 2;
    return 0.5 * ($v[@v/2-1] + $v[@v/2]);
}

sub _write_csv_stats {
    my ($path, $header, $rows) = @_;
    require Text::CSV;
    make_path(dirname($path)) unless -d dirname($path);
    my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    $csv->print($fh, $header);
    for my $r (@$rows) { $csv->print($fh, [ map { defined($_) ? $_ : '' } @$r ]); }
    close $fh or die "Cannot close $path: $!\n";
}

sub _rewrite_statistics_aggregate {
    my ($root) = @_;
    return unless -d $root;
    opendir my $dh, $root or die "Cannot open statistics directory $root: $!\n";
    my @dirs = sort grep { $_ ne '.' && $_ ne '..' && -d File::Spec->catdir($root, $_) } readdir($dh);
    closedir $dh;
    my @records;
    for my $d (@dirs) {
        my $p = File::Spec->catfile($root, $d, 'summary.json');
        next unless -f $p;
        my $r = eval { _read_json($p) };
        next if $@ || ref($r) ne 'HASH' || ($r->{schema}||'') !~ /^Sim::OPT::StructureDesign\/landscape-statistics-[12]$/;
        push @records, $r;
    }
    my @header = qw(pair left_state right_state common_instances mae rmse mse mean_signed_error max_absolute_error r_squared surrogate_to_surrogate_n surrogate_to_surrogate_mae surrogate_to_surrogate_rmse recall_semantics retained_medoids category_ari direct_category_agreement category_changes source_mean_distance_to_retained_medoid recall_mean_distance_to_retained_medoid mean_distance_change secondary_medoid_count secondary_medoid_exact_matches secondary_medoid_mean_distance secondary_medoid_median_distance secondary_medoid_max_distance);
    my @rows;
    for my $r (@records) {
        my $lm = $r->{landscape_metrics} || {};
        my $ss = (ref($r->{category_metrics}) eq 'HASH' && ref($r->{category_metrics}{surrogate_to_surrogate}) eq 'HASH')
            ? $r->{category_metrics}{surrogate_to_surrogate} : {};
        my $rc = $r->{recall_category_metrics} || {};
        my $ret = $r->{retained_model_metrics} || {};
        my $legacy_cm = $r->{cluster_metrics} || {};
        my $legacy_mm = $r->{medoid_metrics} || {};
        my $sec = $r->{secondary_medoid_metrics} || {};
        push @rows, [
            $r->{pair}, $r->{left_state}, $r->{right_state}, $lm->{n}, $lm->{mae}, $lm->{rmse}, $lm->{mse},
            $lm->{mean_signed_error}, $lm->{max_absolute_error}, $lm->{r_squared},
            $ss->{n}, $ss->{mae}, $ss->{rmse},
            $r->{recall_semantics}, ($ret->{medoid_count} // $legacy_mm->{left_count}),
            ($rc->{adjusted_rand_index} // $legacy_cm->{adjusted_rand_index}),
            ($rc->{direct_agreement} // $legacy_cm->{aligned_agreement}), $rc->{changed},
            $rc->{source_mean_distance_to_retained_medoid}, $rc->{recall_mean_distance_to_retained_medoid}, $rc->{mean_distance_change},
            $sec->{secondary_medoid_count}, $sec->{exact_coordinate_matches}, $sec->{mean_hybrid_distance}, $sec->{median_hybrid_distance}, $sec->{max_hybrid_distance},
        ];
    }
    _write_csv_stats(File::Spec->catfile($root, 'structuredesign-summary.csv'), \@header, \@rows);
    _write_json(File::Spec->catfile($root, 'structuredesign-summary.json'), {
        schema => 'Sim::OPT::StructureDesign/statistics-summary-2',
        pairs => \@records,
    });
}

sub _execute_statistics_applied {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $left = $s->{left} or die "statistics: left state required\n";
    my $right = $s->{right} or die "statistics: right state required\n";
    my $pair = $s->{name} || "$left-$right";
    my $left_abs_path = _resolve_reference($s->{left_abstraction}, $manifest);
    my $right_app_path = _resolve_reference($s->{right_application}, $manifest);
    die "statistics '$pair': left abstraction manifest not found: $left_abs_path\n" unless defined($left_abs_path) && -f $left_abs_path;
    die "statistics '$pair': right applied-abstraction manifest not found: $right_app_path\n" unless defined($right_app_path) && -f $right_app_path;
    my $la = _read_json($left_abs_path);
    my $ra = _read_json($right_app_path);
    die "statistics '$pair': invalid left abstraction schema\n" unless ($la->{schema}||'') eq 'Sim::OPT::StructureDesign/abstraction-1';
    die "statistics '$pair': invalid right applied-abstraction schema\n" unless ($ra->{schema}||'') =~ /^Sim::OPT::StructureDesign\/applied-abstraction-[12]$/;

    my $json = JSON::PP->new->canonical(1);
    die "statistics '$pair': applied metric is not the frozen left abstraction metric\n"
        unless $json->encode($la->{metric}) eq $json->encode($ra->{metric});
    my @lm = map { { cluster=>0+$_->{cluster}, instance=>$_->{instance}, performance=>0+$_->{performance} } } @{ $la->{medoids} || [] };
    my @rm = map { { cluster=>0+$_->{cluster}, instance=>$_->{instance}, performance=>0+$_->{performance} } } @{ $ra->{medoids} || [] };
    die "statistics '$pair': retained medoid set changed during recall\n"
        unless $json->encode(\@lm) eq $json->encode(\@rm);
    die "statistics '$pair': abstraction has no retained medoids\n" unless @lm;

    my @secondary = map {
        { cluster=>0+$_->{cluster}, source_instance=>$_->{source_instance}, local_instance=>$_->{local_instance}, performance=>0+$_->{performance} }
    } @{ $ra->{secondary_medoids} || [] };
    my %secondary_by_cluster = map { $_->{cluster} => $_ } @secondary;
    my (@secondary_comparison, @secondary_distances);
    my $secondary_exact = 0;
    if (@secondary) {
        for my $pm (@lm) {
            my $sm = $secondary_by_cluster{$pm->{cluster}};
            next unless $sm;
            my $d = _metric_distance_from_spec(
                metric=>$la->{metric},
                instance_a=>$pm->{instance}, performance_a=>$pm->{performance},
                instance_b=>$sm->{source_instance}, performance_b=>$sm->{performance},
            );
            push @secondary_distances, $d;
            my $exact = ($pm->{instance} eq $sm->{source_instance}) ? 1 : 0;
            $secondary_exact += $exact;
            push @secondary_comparison, [
                $pm->{cluster}, $pm->{instance}, $pm->{performance},
                $sm->{local_instance}, $sm->{source_instance}, $sm->{performance}, $d, $exact,
            ];
        }
    }
    my $secondary_metrics;
    if (@secondary_distances) {
        my $sum=0; $sum += $_ for @secondary_distances;
        my $max=0; for (@secondary_distances) { $max=$_ if $_>$max; }
        $secondary_metrics = {
            compared_clusters => scalar(@secondary_distances),
            secondary_medoid_count => scalar(@secondary),
            exact_coordinate_matches => 0 + $secondary_exact,
            mean_hybrid_distance => $sum/@secondary_distances,
            median_hybrid_distance => _median_stats(@secondary_distances),
            max_hybrid_distance => $max,
            semantics => 'secondary medoids regenerated within frozen antecedent partitions; matched by inherited category identity',
        };
    }

    my $right_dir = _state_dir($p, $right);
    my $map_name = exists($s->{right_memory_manifest}) ? $s->{right_memory_manifest} : $ra->{memory_manifest};
    my $map_path = defined($map_name) && length($map_name)
        ? (File::Spec->file_name_is_absolute($map_name) ? $map_name : File::Spec->catfile($right_dir, $map_name))
        : undef;
    my ($right_mapper) = _memory_mapper_stats($map_path);
    my $left_mapper = sub { $_[0] };

    my ($right_rows) = _read_landscape_index_stats(
        path => $ra->{results_file}, performance_column => $ra->{performance_column}, mapper => $right_mapper,
    );
    my %wanted = map { $_ => 1 } keys %$right_rows;
    my ($left_rows) = _read_landscape_index_stats(
        path => $la->{results_file}, performance_column => $la->{performance_column}, mapper => $left_mapper, wanted => \%wanted,
    );
    my @common = sort grep { exists $left_rows->{$_} } keys %$right_rows;
    die "statistics '$pair': no physically common landscape instances\n" unless @common;

    my $left_dir = _state_dir($p, $left);
    my $left_tot = $s->{left_totres_file} || (($s->{left_model_root} || 'bt') . '-0_totres.csv');
    $left_tot = File::Spec->catfile($left_dir, $left_tot) unless File::Spec->file_name_is_absolute($left_tot);
    my $right_tot = $s->{right_totres_file} || (($s->{right_model_root} || 'btmed') . '-0_totres.csv');
    $right_tot = File::Spec->catfile($right_dir, $right_tot) unless File::Spec->file_name_is_absolute($right_tot);
    my $left_sampled = _read_sample_set_stats(path => $left_tot, mapper => $left_mapper);
    my $right_sampled = _read_sample_set_stats(path => $right_tot, mapper => $right_mapper);

    my (@reg, %cat_pairs);
    for my $id (@common) {
        my $lv = $left_rows->{$id}{performance};
        my $rv = $right_rows->{$id}{performance};
        my $ls = $left_sampled->{$id} ? 1 : 0;
        my $rs = $right_sampled->{$id} ? 1 : 0;
        my $cat = ($ls ? 'sampled' : 'surrogate') . '_to_' . ($rs ? 'sampled' : 'surrogate');
        push @reg, { actual => $lv, predicted => $rv };
        push @{$cat_pairs{$cat}}, { actual => $lv, predicted => $rv };
    }
    my $metrics = _regression_metrics(\@reg);
    $metrics->{mse} = $metrics->{rmse} * $metrics->{rmse};
    my %category_metrics;
    for my $cat (sort keys %cat_pairs) {
        my $m = _regression_metrics($cat_pairs{$cat});
        $m->{mse} = $m->{rmse} * $m->{rmse};
        $category_metrics{$cat} = $m;
    }

    my %common_wanted = map { $_=>1 } @common;
    my $lc = _read_cluster_assignments_stats(path=>$la->{files}{clustered}, mapper=>$left_mapper, wanted=>\%common_wanted);
    my $rc = _read_applied_assignments_stats(path=>$ra->{files}{assignments}, wanted=>\%common_wanted);
    my %medoid_by_cluster = map { $_->{cluster} => $_ } @lm;
    my (@cluster_pairs, %cont, @common_csv, @source_dist, @recall_dist);
    my ($agree,$cn)=(0,0);
    my $metric = $la->{metric};
    for my $id (@common) {
        die "statistics '$pair': source category missing for common instance $id\n" unless exists $lc->{$id};
        die "statistics '$pair': recalled category missing for common instance $id\n" unless exists $rc->{$id};
        my ($a1,$b1)=($lc->{$id},$rc->{$id}{cluster});
        my $med = $medoid_by_cluster{$a1} or die "statistics '$pair': no retained medoid for source cluster $a1\n";
        my $sd = _metric_distance_from_spec(
            metric=>$metric, instance_a=>$id, performance_a=>$left_rows->{$id}{performance},
            instance_b=>$med->{instance}, performance_b=>$med->{performance},
        );
        my $rd = $rc->{$id}{distance};
        push @source_dist,$sd; push @recall_dist,$rd;
        push @cluster_pairs,[$a1,$b1]; $cont{$a1}{$b1}++; $cn++; $agree++ if $a1==$b1;
        my $ls = $left_sampled->{$id} ? 1 : 0; my $rs = $right_sampled->{$id} ? 1 : 0;
        my $cat = ($ls ? 'sampled' : 'surrogate') . '_to_' . ($rs ? 'sampled' : 'surrogate');
        push @common_csv,[$id,$right_rows->{$id}{local_instance},$left_rows->{$id}{performance},$right_rows->{$id}{performance},
            $right_rows->{$id}{performance}-$left_rows->{$id}{performance},abs($right_rows->{$id}{performance}-$left_rows->{$id}{performance}),
            $ls,$rs,$cat,$a1,$b1,($a1==$b1?1:0),$sd,$rd,$rd-$sd];
    }
    my $ari = _ari_stats(\@cluster_pairs);
    my $direct = $cn ? $agree/$cn : undef;
    my @cont_csv;
    for my $x (sort {$a<=>$b} keys %cont) { for my $y (sort {$a<=>$b} keys %{$cont{$x}}) { push @cont_csv,[$x,$y,$cont{$x}{$y}]; } }
    my $sum_sd=0; $sum_sd+=$_ for @source_dist; my $sum_rd=0; $sum_rd+=$_ for @recall_dist;
    my $mean_sd=@source_dist ? $sum_sd/@source_dist : undef; my $mean_rd=@recall_dist ? $sum_rd/@recall_dist : undef;
    my $max_sd=0; for (@source_dist) { $max_sd=$_ if $_>$max_sd; }
    my $max_rd=0; for (@recall_dist) { $max_rd=$_ if $_>$max_rd; }
    my $recall_cat = {
        common_classified_instances=>0+$cn, preserved=>0+$agree, changed=>0+($cn-$agree),
        direct_agreement=>$direct, adjusted_rand_index=>$ari,
        source_mean_distance_to_retained_medoid=>$mean_sd, recall_mean_distance_to_retained_medoid=>$mean_rd,
        mean_distance_change=>(defined($mean_sd)&&defined($mean_rd)?$mean_rd-$mean_sd:undef),
        source_median_distance_to_retained_medoid=>_median_stats(@source_dist), recall_median_distance_to_retained_medoid=>_median_stats(@recall_dist),
        source_max_distance_to_retained_medoid=>$max_sd, recall_max_distance_to_retained_medoid=>$max_rd,
    };

    my $stats_root = File::Spec->catdir($p->{root_dir}, $s->{statistics_dir} || 'statistics');
    my $rel = $s->{output_dir} || $pair;
    my $out = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($stats_root,$rel);
    my $summary_path = File::Spec->catfile($out,'summary.json');
    my $aggregate_csv = File::Spec->catfile($stats_root,'structuredesign-summary.csv');
    my $aggregate_json = File::Spec->catfile($stats_root,'structuredesign-summary.json');
    my $common_path = File::Spec->catfile($out,'common-instances.csv');
    my $transition_path = File::Spec->catfile($out,'category-transition.csv');
    my $categories_path = File::Spec->catfile($out,'category-metrics.csv');
    my $secondary_medoid_path = File::Spec->catfile($out,'secondary-medoid-comparison.csv');
    my $record = {
        schema=>'Sim::OPT::StructureDesign/landscape-statistics-2', operation=>'statistics', pair=>$pair,
        recall_semantics=>'frozen_antecedent_categories', left_state=>$left, right_state=>$right,
        left_abstraction=>$left_abs_path, right_application=>$right_app_path, right_memory_manifest=>$map_path,
        landscape_metrics=>$metrics, category_metrics=>\%category_metrics, recall_category_metrics=>$recall_cat,
        retained_model_metrics=>{ medoid_count=>scalar(@lm), medoids_fixed=>JSON::PP::true, metric_frozen=>JSON::PP::true },
        secondary_medoid_metrics=>$secondary_metrics,
        metric=>$metric,
        files=>{ summary=>$summary_path, common_instances=>$common_path, category_transition=>$transition_path,
                 category_metrics=>$categories_path, secondary_medoid_comparison=>$secondary_medoid_path, aggregate_csv=>$aggregate_csv, aggregate_json=>$aggregate_json },
    };
    return $record unless $commit;
    make_path($out) unless -d $out;
    _write_csv_stats($common_path,[qw(source_instance memory_instance source_performance memory_performance signed_error absolute_error source_sampled memory_sampled acquisition_category source_category recalled_category category_preserved source_distance_to_retained_medoid recall_distance_to_retained_medoid distance_change)],\@common_csv);
    _write_csv_stats($transition_path,[qw(source_category recalled_category common_instance_count)],\@cont_csv);
    my @category_csv;
    for my $cat (sort keys %category_metrics) { my $m=$category_metrics{$cat}; push @category_csv,[$cat,$m->{n},$m->{mean_signed_error},$m->{mae},$m->{mse},$m->{rmse},$m->{max_absolute_error},$m->{r_squared}]; }
    _write_csv_stats($categories_path,[qw(category n mean_signed_error mae mse rmse max_absolute_error r_squared)],\@category_csv);
    _write_csv_stats($secondary_medoid_path,[qw(category primary_medoid primary_performance secondary_local_instance secondary_source_instance secondary_performance hybrid_distance exact_coordinate_match)],\@secondary_comparison);
    _write_json($summary_path,$record);
    _rewrite_statistics_aggregate($stats_root);
    return { pair=>$pair, manifest=>$summary_path, files=>$record->{files}, landscape_metrics=>$metrics, recall_category_metrics=>$recall_cat, retained_model_metrics=>$record->{retained_model_metrics}, secondary_medoid_metrics=>$secondary_metrics };
}

sub _execute_statistics {
    my (%a) = @_;
    return _execute_statistics_applied(%a) if exists($a{step}{right_application});
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $left = $s->{left} or die "statistics: left state required\n";
    my $right = $s->{right} or die "statistics: right state required\n";
    my $pair = $s->{name} || "$left-$right";
    my $left_abs_path = _resolve_reference($s->{left_abstraction}, $manifest);
    my $right_abs_path = _resolve_reference($s->{right_abstraction}, $manifest);
    die "statistics '$pair': left abstraction manifest not found: $left_abs_path\n" unless defined($left_abs_path) && -f $left_abs_path;
    die "statistics '$pair': right abstraction manifest not found: $right_abs_path\n" unless defined($right_abs_path) && -f $right_abs_path;
    my $la = _read_json($left_abs_path);
    my $ra = _read_json($right_abs_path);
    die "statistics '$pair': invalid left abstraction schema\n" unless ($la->{schema}||'') eq 'Sim::OPT::StructureDesign/abstraction-1';
    die "statistics '$pair': invalid right abstraction schema\n" unless ($ra->{schema}||'') eq 'Sim::OPT::StructureDesign/abstraction-1';

    my $right_dir = _state_dir($p, $right);
    my $map_name = $s->{right_memory_manifest};
    my $map_path = defined($map_name) && length($map_name)
        ? (File::Spec->file_name_is_absolute($map_name) ? $map_name : File::Spec->catfile($right_dir, $map_name))
        : undef;
    my ($right_mapper, $memory_plan) = _memory_mapper_stats($map_path);
    my $left_mapper = sub { $_[0] };

    my ($right_rows) = _read_landscape_index_stats(
        path => $ra->{results_file}, performance_column => $ra->{performance_column}, mapper => $right_mapper,
    );
    my %wanted = map { $_ => 1 } keys %$right_rows;
    my ($left_rows) = _read_landscape_index_stats(
        path => $la->{results_file}, performance_column => $la->{performance_column}, mapper => $left_mapper, wanted => \%wanted,
    );
    my @common = sort grep { exists $left_rows->{$_} } keys %$right_rows;
    die "statistics '$pair': no physically common landscape instances\n" unless @common;

    my $left_dir = _state_dir($p, $left);
    my $left_tot = $s->{left_totres_file} || (($s->{left_model_root} || 'bt') . '-0_totres.csv');
    $left_tot = File::Spec->catfile($left_dir, $left_tot) unless File::Spec->file_name_is_absolute($left_tot);
    my $right_tot = $s->{right_totres_file} || (($s->{right_model_root} || 'btmed') . '-0_totres.csv');
    $right_tot = File::Spec->catfile($right_dir, $right_tot) unless File::Spec->file_name_is_absolute($right_tot);
    my $left_sampled = _read_sample_set_stats(path => $left_tot, mapper => $left_mapper);
    my $right_sampled = _read_sample_set_stats(path => $right_tot, mapper => $right_mapper);

    my (@reg, @common_csv, %cat_pairs);
    for my $id (@common) {
        my $lv = $left_rows->{$id}{performance};
        my $rv = $right_rows->{$id}{performance};
        my $ls = $left_sampled->{$id} ? 1 : 0;
        my $rs = $right_sampled->{$id} ? 1 : 0;
        my $cat = ($ls ? 'sampled' : 'surrogate') . '_to_' . ($rs ? 'sampled' : 'surrogate');
        push @reg, { actual => $lv, predicted => $rv };
        push @{$cat_pairs{$cat}}, { actual => $lv, predicted => $rv };
        push @common_csv, [$id, $right_rows->{$id}{local_instance}, $lv, $rv, $rv-$lv, abs($rv-$lv), $ls, $rs, $cat];
    }
    my $metrics = _regression_metrics(\@reg);
    $metrics->{mse} = $metrics->{rmse} * $metrics->{rmse};
    my %category_metrics;
    for my $cat (sort keys %cat_pairs) {
        my $m = _regression_metrics($cat_pairs{$cat});
        $m->{mse} = $m->{rmse} * $m->{rmse};
        $category_metrics{$cat} = $m;
    }

    my $metric = _metric_from_abstraction_stats($la);
    my @lm;
    for my $m (@{ $la->{medoids} || [] }) {
        push @lm, { cluster=>0+$m->{cluster}, source_instance=>$m->{instance}, local_instance=>$m->{instance}, performance=>0+$m->{performance} };
    }
    my @rm;
    for my $m (@{ $ra->{medoids} || [] }) {
        my $src = $right_mapper->($m->{instance});
        push @rm, { cluster=>0+$m->{cluster}, source_instance=>$src, local_instance=>$m->{instance}, performance=>0+$m->{performance} };
    }
    die "statistics '$pair': abstraction has no medoids\n" unless @lm && @rm;

    my %LS = map { $_->{source_instance} => 1 } @lm;
    my %RS = map { $_->{source_instance} => 1 } @rm;
    my @exact = grep { $RS{$_} } keys %LS;
    my %union = (%LS, %RS);
    my $matching = _optimal_medoid_matching_stats(\@lm, \@rm, $metric);
    my @md = map { $_->{distance} } @$matching;
    my $sumd = 0; $sumd += $_ for @md;
    my $maxd = 0; for (@md) { $maxd = $_ if $_ > $maxd; }

    my @left_near;
    for my $L (@lm) {
        my $best;
        for my $R (@rm) {
            my $d = _metric_distance_from_spec(metric=>$metric, instance_a=>$L->{source_instance},performance_a=>$L->{performance}, instance_b=>$R->{source_instance},performance_b=>$R->{performance});
            $best = $d if !defined($best) || $d < $best;
        }
        push @left_near, $best;
    }
    my @right_near;
    for my $R (@rm) {
        my $best;
        for my $L (@lm) {
            my $d = _metric_distance_from_spec(metric=>$metric, instance_a=>$L->{source_instance},performance_a=>$L->{performance}, instance_b=>$R->{source_instance},performance_b=>$R->{performance});
            $best = $d if !defined($best) || $d < $best;
        }
        push @right_near, $best;
    }
    my $haus = 0; for (@left_near,@right_near) { $haus = $_ if $_ > $haus; }

    my %right_to_left_cluster;
    my %matched_right;
    my @matching_csv;
    for my $q (@$matching) {
        my $L = $lm[$q->{left_index}]; my $R = $rm[$q->{right_index}];
        $right_to_left_cluster{$R->{cluster}} = $L->{cluster};
        $matched_right{$q->{right_index}} = 1;
        push @matching_csv, [$L->{cluster},$L->{source_instance},$L->{performance},$R->{cluster},$R->{local_instance},$R->{source_instance},$R->{performance},$q->{distance},($L->{source_instance} eq $R->{source_instance}?1:0)];
    }
    for my $ri (0 .. $#rm) {
        next if $matched_right{$ri};
        my $R=$rm[$ri]; my ($bestd,$bestc);
        for my $L (@lm) {
            my $d=_metric_distance_from_spec(metric=>$metric,instance_a=>$L->{source_instance},performance_a=>$L->{performance},instance_b=>$R->{source_instance},performance_b=>$R->{performance});
            if (!defined($bestd)||$d<$bestd) { $bestd=$d; $bestc=$L->{cluster}; }
        }
        $right_to_left_cluster{$R->{cluster}}=$bestc;
    }

    my $left_clustered = $la->{files}{clustered};
    my $right_clustered = $ra->{files}{clustered};
    my %common_wanted = map { $_=>1 } @common;
    my $lc = _read_cluster_assignments_stats(path=>$left_clustered, mapper=>$left_mapper, wanted=>\%common_wanted);
    my $rc = _read_cluster_assignments_stats(path=>$right_clustered, mapper=>$right_mapper, wanted=>\%common_wanted);
    my (@cluster_pairs,%cont,$agree,$cn);
    for my $id (@common) {
        next unless exists($lc->{$id}) && exists($rc->{$id});
        my ($a1,$b1)=($lc->{$id},$rc->{$id});
        push @cluster_pairs, [$a1,$b1];
        $cont{$a1}{$b1}++;
        $cn++;
        $agree++ if defined($right_to_left_cluster{$b1}) && $right_to_left_cluster{$b1} == $a1;
    }
    my $ari = _ari_stats(\@cluster_pairs);
    my $aligned = $cn ? $agree/$cn : undef;
    my @cont_csv;
    for my $x (sort {$a<=>$b} keys %cont) { for my $y (sort {$a<=>$b} keys %{$cont{$x}}) { push @cont_csv, [$x,$y,$cont{$x}{$y}]; } }

    my $stats_root = File::Spec->catdir($p->{root_dir}, $s->{statistics_dir} || 'statistics');
    my $rel = $s->{output_dir} || $pair;
    my $out = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($stats_root, $rel);
    my $summary_path = File::Spec->catfile($out, 'summary.json');
    my $aggregate_csv = File::Spec->catfile($stats_root, 'structuredesign-summary.csv');
    my $aggregate_json = File::Spec->catfile($stats_root, 'structuredesign-summary.json');
    my $common_path = File::Spec->catfile($out, 'common-instances.csv');
    my $matching_path = File::Spec->catfile($out, 'medoid-matching.csv');
    my $clusters_path = File::Spec->catfile($out, 'cluster-overlap.csv');
    my $categories_path = File::Spec->catfile($out, 'category-metrics.csv');
    my $record = {
        schema => 'Sim::OPT::StructureDesign/landscape-statistics-1', operation=>'statistics', pair=>$pair,
        left_state=>$left,right_state=>$right,left_abstraction=>$left_abs_path,right_abstraction=>$right_abs_path,
        right_memory_manifest=>$map_path,
        landscape_metrics=>$metrics, category_metrics=>\%category_metrics,
        medoid_metrics=>{
            left_count=>scalar(@lm), right_count=>scalar(@rm), exact_matches=>scalar(@exact),
            jaccard=>scalar(@exact)/scalar(keys %union), matched_count=>scalar(@$matching),
            matched_mean_distance=>@md ? $sumd/@md : undef, matched_median_distance=>_median_stats(@md), matched_max_distance=>@md ? $maxd : undef,
            left_to_right_nearest_mean=>@left_near ? do {my $s=0;$s+=$_ for @left_near;$s/@left_near}:undef,
            right_to_left_nearest_mean=>@right_near ? do {my $s=0;$s+=$_ for @right_near;$s/@right_near}:undef,
            symmetric_hausdorff_distance=>$haus,
        },
        cluster_metrics=>{ common_clustered_instances=>0+($cn||0), adjusted_rand_index=>$ari, aligned_agreement=>$aligned },
        metric=>$metric,
        files=>{ summary=>$summary_path, common_instances=>$common_path, medoid_matching=>$matching_path, cluster_overlap=>$clusters_path, category_metrics=>$categories_path, aggregate_csv=>$aggregate_csv, aggregate_json=>$aggregate_json },
    };
    return $record unless $commit;
    make_path($out) unless -d $out;
    _write_csv_stats($common_path,[qw(source_instance memory_instance source_performance memory_performance signed_error absolute_error source_sampled memory_sampled category)],\@common_csv);
    _write_csv_stats($matching_path,[qw(source_cluster source_medoid source_performance memory_cluster memory_medoid memory_medoid_in_source_coordinates memory_performance hybrid_distance exact_coordinate_match)],\@matching_csv);
    _write_csv_stats($clusters_path,[qw(source_cluster memory_cluster common_instance_count)],\@cont_csv);
    my @category_csv;
    for my $cat (sort keys %category_metrics) {
        my $m = $category_metrics{$cat};
        push @category_csv, [$cat,$m->{n},$m->{mean_signed_error},$m->{mae},$m->{mse},$m->{rmse},$m->{max_absolute_error},$m->{r_squared}];
    }
    _write_csv_stats($categories_path,[qw(category n mean_signed_error mae mse rmse max_absolute_error r_squared)],\@category_csv);
    _write_json($summary_path,$record);
    _rewrite_statistics_aggregate($stats_root);
    return { pair=>$pair, manifest=>$summary_path, files=>$record->{files}, landscape_metrics=>$metrics, medoid_metrics=>$record->{medoid_metrics}, cluster_metrics=>$record->{cluster_metrics} };
}

sub _validation_sample_manifest_path {
    my (%a) = @_;
    my $p = $a{procedure};
    my $s = $a{step};
    my $state = $s->{name} || $s->{state} or die "validation_sample: target state required\n";
    my $dir = _state_dir($p, $state);
    my $name = $s->{manifest_file} || 'structuredesign-validation-sample.json';
    return File::Spec->file_name_is_absolute($name) ? $name : File::Spec->catfile($dir, $name);
}

sub _execute_validation_sample {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $commit = $a{commit};
    my $target = $s->{name} || $s->{state} or die "validation_sample: target state required\n";
    my $source = $s->{source_state} or die "validation_sample '$target': source_state required\n";
    my $sample_size = $s->{sample_size};
    die "validation_sample '$target': sample_size must be a positive integer\n"
        unless defined($sample_size) && !ref($sample_size) && $sample_size =~ /^\d+$/ && $sample_size > 0;
    my $seed = exists($s->{seed}) ? $s->{seed} : 1;
    die "validation_sample '$target': seed must be a scalar\n" if ref($seed);

    my $source_dir = _state_dir($p, $source);
    my $target_dir = _state_dir($p, $target);
    my $source_name = $s->{source_file} || 'btmed-report-0-0.csv_sortm.csv_weightordmeta.csv';
    my $source_path = File::Spec->file_name_is_absolute($source_name)
        ? $source_name : File::Spec->catfile($source_dir, $source_name);
    my $pass_name = $s->{passnames_file} || 'passnames_.txt';
    my $pass_path = File::Spec->file_name_is_absolute($pass_name)
        ? $pass_name : File::Spec->catfile($target_dir, $pass_name);
    my $manifest_path = _validation_sample_manifest_path(procedure=>$p, step=>$s);

    return {
        state=>$target, source_state=>$source, source_file=>$source_path,
        sample_size=>0+$sample_size, seed=>"$seed", passnames=>$pass_path,
        manifest=>$manifest_path, planned=>1,
    } unless $commit;

    die "validation_sample '$target': target state directory not found: $target_dir\n" unless -d $target_dir;
    die "validation_sample '$target': source landscape not found: $source_path\n" unless -f $source_path;

    require Text::CSV;
    my $csv = Text::CSV->new({ binary=>1, auto_diag=>1 });
    open my $fh, '<', $source_path or die "Cannot read $source_path: $!\n";
    my (@ids, %seen);
    while (my $r = $csv->getline($fh)) {
        next unless ref($r) eq 'ARRAY' && @$r;
        my $id = $r->[0];
        next unless defined($id) && $id =~ /^\d+-\d+(?:_\d+-\d+)*$/;
        next if $seen{$id}++;
        push @ids, $id;
    }
    close $fh;
    die "validation_sample '$target': source landscape contains no instance rows\n" unless @ids;
    die "validation_sample '$target': sample_size $sample_size exceeds available unique instances " . scalar(@ids) . "\n"
        if $sample_size > @ids;

    # A seeded SHA-256 ranking is a deterministic pseudorandom permutation.
    # It avoids changing Perl's process-global rand()/srand() state and makes
    # the exact validation batch reproducible on every platform.
    my @ordered = sort {
        sha256_hex("$seed\0$a") cmp sha256_hex("$seed\0$b") || $a cmp $b
    } @ids;
    my @selected = @ordered[0 .. $sample_size-1];

    open my $pfh, '>', $pass_path or die "Cannot write $pass_path: $!\n";
    print {$pfh} "$_\n" for @selected;
    close $pfh or die "Cannot close $pass_path: $!\n";

    open my $sfh, '<', $source_path or die "Cannot read $source_path: $!\n";
    binmode $sfh;
    local $/;
    my $source_bytes = <$sfh>;
    close $sfh;
    my $source_sha = sha256_hex($source_bytes // '');
    my $selection_sha = sha256_hex(join("\n", @selected) . "\n");

    my $record = {
        schema=>'Sim::OPT::StructureDesign/validation-sample-1',
        operation=>'validation_sample',
        target_state=>$target,
        source_state=>$source,
        source_file=>$source_path,
        source_sha256=>$source_sha,
        available_unique_instances=>0+@ids,
        requested_sample_size=>0+$sample_size,
        realised_sample_size=>0+@selected,
        seed=>"$seed",
        selection_method=>'sha256_seeded_order',
        selection_sha256=>$selection_sha,
        passnames_file=>$pass_path,
        selected_instances=>\@selected,
    };
    _write_json($manifest_path, $record);
    return { %$record, manifest=>$manifest_path, passnames=>$pass_path };
}

sub _execute_direct_validation_statistics {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $pair = $s->{name} || 'direct-validation';
    my $prediction_state = $s->{prediction_state} or die "direct_validation_statistics '$pair': prediction_state required\n";
    my $direct_state = $s->{direct_state} or die "direct_validation_statistics '$pair': direct_state required\n";
    my $pred_dir = _state_dir($p, $prediction_state);
    my $direct_dir = _state_dir($p, $direct_state);
    die "direct_validation_statistics '$pair': prediction state directory not found: $pred_dir\n" unless -d $pred_dir;
    die "direct_validation_statistics '$pair': direct state directory not found: $direct_dir\n" unless -d $direct_dir;

    my $prediction_name = $s->{prediction_file} || 'btmed-report-0-0.csv_sortm.csv_weightordmeta.csv';
    my $prediction_path = File::Spec->file_name_is_absolute($prediction_name)
        ? $prediction_name : File::Spec->catfile($pred_dir, $prediction_name);
    my $root = $s->{model_root} || 'btmed';
    my $direct_name = $s->{direct_results_file} || ($root . '-0_totres.csv');
    my $direct_path = File::Spec->file_name_is_absolute($direct_name)
        ? $direct_name : File::Spec->catfile($direct_dir, $direct_name);
    my $sample_path = _resolve_reference($s->{sample_manifest}, $manifest);
    die "direct_validation_statistics '$pair': sample manifest not found: $sample_path\n"
        unless defined($sample_path) && -f $sample_path;
    for my $f ($prediction_path,$direct_path) {
        die "direct_validation_statistics '$pair': required file not found: $f\n" unless -f $f;
    }

    my $sample = _read_json($sample_path);
    die "direct_validation_statistics '$pair': invalid sample manifest schema\n"
        unless ($sample->{schema}||'') eq 'Sim::OPT::StructureDesign/validation-sample-1';
    my @selected = @{ $sample->{selected_instances} || [] };
    die "direct_validation_statistics '$pair': sample manifest contains no selected instances\n" unless @selected;
    my %wanted = map { $_=>1 } @selected;

    # Reconstructed weightordmeta and directly simulated totres use the same
    # Sim::OPT objective weighting/normalisation because the direct validation
    # state is cloned from the reconstruction's memory.pl.  Compare the final
    # weighted scalar directly; do not renormalise the validation batch.
    my $pred = _read_prediction_scores_for_ids(path=>$prediction_path, wanted=>\%wanted);
    my $direct_rows = _read_totres_rows(source=>$direct_path, mapper=>sub { $_[0] }, label=>$direct_state);
    my %direct = map { $_->{clear} => $_ } @$direct_rows;

    my @missing_direct = grep { !exists $direct{$_} } @selected;
    die "direct_validation_statistics '$pair': direct results lack " . scalar(@missing_direct)
        . " selected instances; first missing '$missing_direct[0]'\n" if @missing_direct;
    my @missing_pred = grep { !exists $pred->{$_} } @selected;
    die "direct_validation_statistics '$pair': prediction file lacks " . scalar(@missing_pred)
        . " selected instances; first missing '$missing_pred[0]'\n" if @missing_pred;

    my %selected_set = map { $_=>1 } @selected;
    my @unexpected = grep { !$selected_set{$_} } keys %direct;
    die "direct_validation_statistics '$pair': direct results contain " . scalar(@unexpected)
        . " unrequested instances; first unexpected '$unexpected[0]'\n" if @unexpected;
    die "direct_validation_statistics '$pair': direct result count " . scalar(@$direct_rows)
        . " differs from selected sample size " . scalar(@selected) . "\n"
        unless @$direct_rows == @selected;

    my (@pairs,@csv_rows);
    for my $id (@selected) {
        my $actual = _payload_weighted_scalar($direct{$id}{payload});
        my $predicted = 0 + $pred->{$id};
        push @pairs, { instance=>$id, predicted=>$predicted, actual=>$actual };
        push @csv_rows, [$id,$predicted,$actual,$predicted-$actual,abs($predicted-$actual)];
    }
    my $metrics = _regression_metrics(\@pairs);
    $metrics->{mse} = $metrics->{rmse} * $metrics->{rmse};

    my $stats_root = File::Spec->catdir($p->{root_dir}, $s->{statistics_dir} || 'bt-statistics');
    my $rel = $s->{output_dir} || $pair;
    my $out = File::Spec->file_name_is_absolute($rel) ? $rel : File::Spec->catdir($stats_root,$rel);
    my $summary_path = File::Spec->catfile($out,'summary.json');
    my $rows_path = File::Spec->catfile($out,'direct-validation-instances.csv');
    my $record = {
        schema=>'Sim::OPT::StructureDesign/direct-validation-statistics-1',
        operation=>'direct_validation_statistics',
        pair=>$pair,
        prediction_state=>$prediction_state,
        direct_state=>$direct_state,
        prediction_file=>$prediction_path,
        direct_results=>$direct_path,
        sample_manifest=>$sample_path,
        sample_size=>0+@selected,
        score_semantics=>'same_config_weighted_scalar_no_batch_renormalisation',
        metrics=>$metrics,
        files=>{summary=>$summary_path, instances=>$rows_path},
    };
    return $record unless $commit;
    make_path($out) unless -d $out;
    _write_csv_stats($rows_path,[qw(instance predicted_surrogate direct_simulation signed_error absolute_error)],\@csv_rows);
    _write_json($summary_path,$record);
    return { %$record, manifest=>$summary_path };
}

sub _execute_compare {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $commit = $a{commit};
    my $left = $s->{left} or die "compare: left state required\n";
    my $right = $s->{right} or die "compare: right state required\n";
    my $root = $s->{model_root} || 'bt';
    my $left_dir = _state_dir($p, $left);
    my $right_dir = _state_dir($p, $right);
    die "compare: left state directory not found: $left_dir\n" unless -d $left_dir;
    die "compare: right state directory not found: $right_dir\n" unless -d $right_dir;
    my $left_tot = File::Spec->catfile($left_dir, $s->{left_results_file} || ($root . '-0_totres.csv'));
    my $right_tot = File::Spec->catfile($right_dir, $s->{right_results_file} || ($root . '-0_totres.csv'));
    my $identity = sub { $_[0] };
    my $lr = _read_totres_rows(source => $left_tot, mapper => $identity, label => $left);
    my $rr = _read_totres_rows(source => $right_tot, mapper => $identity, label => $right);

    if (defined $s->{expected_left_rows}) {
        die "compare '$left/$right': expected $s->{expected_left_rows} left rows but found " . scalar(@$lr) . "\n"
            unless @$lr == 0 + $s->{expected_left_rows};
    }
    if (defined $s->{expected_right_rows}) {
        die "compare '$left/$right': expected $s->{expected_right_rows} right rows but found " . scalar(@$rr) . "\n"
            unless @$rr == 0 + $s->{expected_right_rows};
    }

    my (%L, %R);
    $L{$_->{clear}} = $_ for @$lr;
    $R{$_->{clear}} = $_ for @$rr;
    my @overlap = grep { exists $R{$_} } keys %L;
    my @holdout = grep { !exists $L{$_} } keys %R;
    if (defined $s->{expected_overlap_rows}) {
        die "compare '$left/$right': expected $s->{expected_overlap_rows} overlap rows but found " . scalar(@overlap) . "\n"
            unless @overlap == 0 + $s->{expected_overlap_rows};
    }
    if (defined $s->{expected_holdout_rows}) {
        die "compare '$left/$right': expected $s->{expected_holdout_rows} holdout rows but found " . scalar(@holdout) . "\n"
            unless @holdout == 0 + $s->{expected_holdout_rows};
    }
    my $tol = exists($s->{overlap_tolerance}) ? 0 + $s->{overlap_tolerance} : 1e-9;
    for my $id (@overlap) {
        die "compare '$left/$right': shared physical result differs at '$id'\n"
            unless _result_payloads_compatible($L{$id}{payload}, $R{$id}{payload}, $tol);
    }

    my $prediction_state = $s->{prediction_state} || $left;
    my $pred_dir = _state_dir($p, $prediction_state);
    my $prediction_name = $s->{prediction_file}
        or die "compare '$left/$right': prediction_file required\n";
    my $prediction_path = File::Spec->file_name_is_absolute($prediction_name)
        ? $prediction_name : File::Spec->catfile($pred_dir, $prediction_name);
    my %wanted = map { $_ => 1 } @holdout;
    my $pred = _read_prediction_scores_for_ids(path => $prediction_path, wanted => \%wanted);
    my @missing = grep { !exists $pred->{$_} } @holdout;
    die "compare '$left/$right': prediction file lacks " . scalar(@missing) . " holdout instances; first missing '$missing[0]'\n"
        if @missing;

    my $reference = _reference_normalization_from_rows($lr);
    my $left_cfg = File::Spec->catfile($left_dir, $s->{left_config} || ($left . '.pl'));
    my $weights = ref($s->{weights}) eq 'ARRAY'
        ? [ @{$s->{weights}} ]
        : _weights_from_config($left_cfg, $reference->{objective_count});
    my @pairs;
    for my $id (sort @holdout) {
        my $actual = _payload_score_on_reference_scale(
            payload => $R{$id}{payload}, reference => $reference, weights => $weights,
        );
        push @pairs, { instance => $id, predicted => $pred->{$id}, actual => $actual };
    }
    my $metrics = _regression_metrics(\@pairs);
    my $output_name = $s->{output_file} || 'structuredesign-comparison.json';
    my $output = File::Spec->file_name_is_absolute($output_name)
        ? $output_name : File::Spec->catfile($left_dir, $output_name);
    my $record = {
        schema => 'Sim::OPT::StructureDesign/comparison-1',
        operation => 'compare',
        left_state => $left,
        right_state => $right,
        left_results => $left_tot,
        right_results => $right_tot,
        prediction_state => $prediction_state,
        prediction_file => $prediction_path,
        left_rows => scalar(@$lr),
        right_rows => scalar(@$rr),
        overlap_rows => scalar(@overlap),
        holdout_rows => scalar(@holdout),
        overlap_tolerance => $tol,
        shared_physical_results_agree => JSON::PP::true,
        score_reference => {
            state => $left,
            objective_names => $reference->{names},
            absmaxes => $reference->{absmaxes},
            weights => $weights,
        },
        metrics => $metrics,
        threshold_applied => JSON::PP::false,
    };
    _write_json($output, $record) if $commit;
    return { %$record, output => $output };
}

sub _execute_parallel {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};

    my $children = $s->{steps};
    die "parallel: steps must be a non-empty ARRAY reference\n"
        unless ref($children) eq 'ARRAY' && @$children;
    my @children = grep { $_->{enabled} } @$children;
    die "parallel: no enabled child steps\n" unless @children;

    my $max_workers = defined($s->{max_workers}) ? 0 + $s->{max_workers} : scalar(@children);
    die "parallel: max_workers must be an integer >= 1\n"
        unless $max_workers =~ /^\d+$/ && $max_workers >= 1;
    $max_workers = scalar(@children) if $max_workers > @children;

    # The first installed parallel primitive is deliberately narrow.  It exists
    # to run independent, long-lived acquisitions concurrently while the parent
    # process remains the sole writer of the procedure run manifest.  Broader
    # DAG semantics should not be implied until dependency analysis is explicit.
    my %state_seen;
    my @plan;
    for my $i (0 .. $#children) {
        my $c = $children[$i];
        die "parallel: child step must be a HASH reference\n" unless ref($c) eq 'HASH';
        my $type = $c->{type} || '';
        die "parallel: only experience child steps are currently supported (child " . ($i + 1) . " is '$type')\n"
            unless $type eq 'experience';
        my $state = $c->{name} || $c->{state};
        die "parallel: experience child " . ($i + 1) . " has no state\n"
            unless defined($state) && length($state);
        die "parallel: state '$state' occurs more than once; concurrent children must write to distinct state directories\n"
            if $state_seen{$state}++;
        push @plan, {
            id => _step_id($c, $i),
            type => $type,
            state => $state,
            signature => _step_signature($c),
        };
    }

    return {
        mode => 'parallel_experiences',
        max_workers => $max_workers,
        children => \@plan,
        planned => 1,
    } unless $commit;

    my $group_id = $s->{id} || $s->{name} || 'parallel';
    $group_id =~ s/[^A-Za-z0-9_.-]+/_/g;
    my $work_dir = File::Spec->catdir($p->{root_dir}, '.structuredesign', 'parallel', $group_id . '-' . $$);
    make_path($work_dir);

    my @queue = map { [$_, $children[$_], $plan[$_]] } (0 .. $#children);
    my %running;
    my @results;
    my @errors;

    while (@queue || keys %running) {
        while (@queue && keys(%running) < $max_workers) {
            my ($idx, $child, $meta) = @{ shift @queue };
            my $result_path = File::Spec->catfile($work_dir, sprintf('%03d-%s.json', $idx + 1, $meta->{id}));
            my $pid = fork();
            die "parallel '$group_id': fork failed: $!\n" unless defined $pid;
            if ($pid == 0) {
                my $payload;
                my $ok = eval {
                    my $result = _execute_step(
                        step => $child,
                        procedure => $p,
                        manifest => $manifest,
                        commit => 1,
                    );
                    $payload = { ok => JSON::PP::true, result => ($result || {}) };
                    1;
                };
                if (!$ok) {
                    my $err = $@ || 'unknown child error';
                    $payload = { ok => JSON::PP::false, error => "$err" };
                }
                my $write_ok = eval { _write_json($result_path, $payload); 1 };
                if (!$write_ok) {
                    print STDERR "parallel '$group_id': cannot write child result $result_path: " . ($@ || $!) . "\n";
                    exit 2;
                }
                exit($payload->{ok} ? 0 : 1);
            }
            print "[StructureDesign] PARALLEL START $meta->{id} ($meta->{state}) pid=$pid\n";
            $running{$pid} = {
                idx => $idx,
                meta => $meta,
                result_path => $result_path,
            };
        }

        my $pid = wait();
        die "parallel '$group_id': wait failed: $!\n" if $pid < 0;
        my $status = $?;
        my $run = delete $running{$pid};
        next unless $run;
        my $meta = $run->{meta};
        my $payload = eval { _read_json($run->{result_path}) };
        if ($@ || ref($payload) ne 'HASH') {
            push @errors, "$meta->{id}: child result record missing/corrupt ($run->{result_path})";
            print "[StructureDesign] PARALLEL FAIL $meta->{id} ($meta->{state})\n";
            next;
        }
        if (($status >> 8) != 0 || ($status & 127) || !$payload->{ok}) {
            my $err = $payload->{error} || sprintf('child process status=%d signal=%d', ($status >> 8), ($status & 127));
            $err =~ s/\s+\z//;
            push @errors, "$meta->{id}: $err";
            print "[StructureDesign] PARALLEL FAIL $meta->{id} ($meta->{state})\n";
            next;
        }
        $results[$run->{idx}] = {
            %$meta,
            result => ($payload->{result} || {}),
        };
        print "[StructureDesign] PARALLEL DONE $meta->{id} ($meta->{state})\n";
    }

    if (@errors) {
        # Preserve per-child records to diagnose a partial group.  The parent
        # manifest will mark the group FAILED; it remains the only manifest writer.
        die "parallel '$group_id' failed:\n  " . join("\n  ", @errors) . "\nChild records preserved in $work_dir\n";
    }

    remove_tree($work_dir);
    return {
        mode => 'parallel_experiences',
        max_workers => $max_workers,
        children => \@results,
    };
}

sub _execute_step {
    my (%a) = @_;
    my $s = $a{step};
    my $p = $a{procedure};
    my $manifest = $a{manifest};
    my $commit = $a{commit};
    my $type = $s->{type} || '';

    if ($type eq 'parallel') {
        return _execute_parallel(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }

    if ($type eq 'state') {
        my $name = $s->{name} or die "state: name required\n";
        my $dir = _state_dir($p, $name);
        my $cfg_name = $s->{config} || "$name.pl";
        my $cfg = File::Spec->catfile($dir, $cfg_name);
        if ($s->{existing}) {
            die "Existing state directory not found: $dir\n" unless -d $dir;
            die "Existing state config not found: $cfg\n" unless -f $cfg;
            return { state => $name, state_dir => $dir, config => $cfg_name };
        }

        if (defined($s->{from}) && length($s->{from})) {
            my $from = $s->{from};
            my $source_dir = _state_dir($p, $from);
            my $source_cfg_name = $s->{source_config} || "$from.pl";
            my $source_cfg = File::Spec->catfile($source_dir, $source_cfg_name);
            my $root = $s->{model_root} || 'bt';
            my $source_model = File::Spec->catdir($source_dir, $root);
            return {
                state => $name, state_dir => $dir, config => $cfg_name,
                from => $from, source_config => $source_cfg_name, planned => 1,
            } unless $commit;

            die "state '$name': source state directory not found: $source_dir\n" unless -d $source_dir;
            die "state '$name': source config not found: $source_cfg\n" unless -f $source_cfg;
            die "state '$name': source root model not found: $source_model\n" unless -d $source_model;
            die "state '$name': refusing to overwrite existing target directory $dir\n" if -e $dir;

            my $source_geometry_manifest;
            my $target_geometry_manifest;
            if (defined($s->{geometry_manifest}) && length($s->{geometry_manifest})) {
                $source_geometry_manifest = File::Spec->file_name_is_absolute($s->{geometry_manifest})
                    ? $s->{geometry_manifest}
                    : File::Spec->catfile($source_dir, $s->{geometry_manifest});
                die "state '$name': source geometry manifest not found: $source_geometry_manifest\n"
                    unless -f $source_geometry_manifest;
                my $target_geometry_name = $s->{target_geometry_manifest}
                    || basename($s->{geometry_manifest});
                $target_geometry_manifest = File::Spec->catfile($dir, $target_geometry_name);
            }

            # Preflight the entire state contract before creating the target
            # directory.  A stale/corrupt source geometry must not leave a
            # half-created sibling state behind.
            my $variant = $s->{config_variant} || {};
            my $preview = _render_config_variant(
                source => $source_cfg, mypath => $dir, variant => $variant,
            );
            _validate_config_variant_text($preview, $variant);
            if (defined $source_geometry_manifest) {
                my $plan = _read_json($source_geometry_manifest);
                require Sim::OPT::StructureDesign;
                my $source_text = _read_text_file($source_cfg);
                Sim::OPT::StructureDesign::validate_enlarge_pan_config_text(
                    $source_text, $plan, target_dir => $source_dir,
                );
                Sim::OPT::StructureDesign::validate_enlarge_pan_config_text(
                    $preview, $plan, target_dir => $dir,
                );
            }

            make_path($dir);
            _copy_tree_exact($source_model, File::Spec->catdir($dir, $root));
            _write_text_file($cfg, $preview);
            if (defined $source_geometry_manifest) {
                _materialize_cloned_scope_manifest(
                    source => $source_geometry_manifest,
                    target => $target_geometry_manifest,
                    source_config => $source_cfg,
                    target_config => $cfg,
                    source_dir => $source_dir,
                    target_dir => $dir,
                );
            }
            return {
                state => $name, state_dir => $dir, config => $cfg_name,
                from => $from, generated => 1,
                (defined($target_geometry_manifest) ? (geometry_manifest => $target_geometry_manifest) : ()),
            };
        }

        return { state => $name, state_dir => $dir, config => $cfg_name };
    }

    if ($type eq 'experience') {
        my $state = $s->{name} || $s->{state} or die "experience: state required\n";
        my $using = $s->{using} || search();
        my $kind = $using->{kind} || 'search';
        die "experience '$state': '$kind' is represented by the procedure language, but its config compiler is not yet installed; this guard prevents silently running the wrong acquisition method\n"
            unless $kind eq 'search' || $kind eq 'star';

        my $dir = _state_dir($p, $state);
        my $cfg;
        my $star_plan;
        if ($kind eq 'star') {
            $star_plan = _compile_star_experience(step => $s, procedure => $p, commit => $commit);
            return {
                state => $state,
                planned => 1,
                acquisition => 'star',
                divisions => $star_plan->{divisions},
                variables => $star_plan->{variables},
                expected_result_rows => $star_plan->{expected_result_rows},
                acquisition_config => $star_plan->{acquisition_config},
            } unless $commit;
            $cfg = basename($star_plan->{acquisition_config});
        } else {
            return { state => $state, planned => 1, acquisition => $kind } unless $commit;
            $cfg = $s->{config} || "$state.pl";
            if (defined($s->{config_from}) && length($s->{config_from})) {
                my $source_cfg = File::Spec->file_name_is_absolute($s->{config_from})
                    ? $s->{config_from} : File::Spec->catfile($dir, $s->{config_from});
                my $geometry_manifest;
                if (defined($s->{geometry_manifest}) && length($s->{geometry_manifest})) {
                    $geometry_manifest = File::Spec->file_name_is_absolute($s->{geometry_manifest})
                        ? $s->{geometry_manifest}
                        : File::Spec->catfile($dir, $s->{geometry_manifest});
                }
                my $variant = _experience_config_variant(
                    step => $s, procedure => $p,
                );
                _materialize_config_variant(
                    source => $source_cfg,
                    target => File::Spec->catfile($dir, $cfg),
                    mypath => $dir,
                    variant => $variant,
                    geometry_manifest => $geometry_manifest,
                );
            }
        }

        my $r = _run_opt(state => $state, state_dir => $dir, config => $cfg, executable => $s->{executable}, root_dir => $p->{root_dir});
        my $root = $s->{model_root} || 'bt';
        my $winner = _detect_winner(state_dir => $dir, model_root => $root);
        die "OPT completed for '$state', but StructureDesign could not determine the final clear incumbent automatically. response.txt or a winner-labelled tofile entry is required before the next incumbent-dependent operation.\n"
            unless defined $winner;

        if ($kind eq 'star') {
            my $results = File::Spec->catfile($dir, $root . '-0_totres.csv');
            my $rows = _count_result_rows($results);
            die "star experience '$state': expected $star_plan->{expected_result_rows} result rows but found $rows in $results\n"
                unless $rows == $star_plan->{expected_result_rows};
            my $record = {
                %$star_plan,
                result_rows => 0 + $rows,
                results_file => $results,
                incumbent => $winner,
            };
            my $record_path = File::Spec->catfile($dir, 'structuredesign-star.json');
            _write_json($record_path, $record);
            return {
                %$r,
                state => $state,
                acquisition => 'star',
                divisions => $star_plan->{divisions},
                variables => $star_plan->{variables},
                expected_result_rows => $star_plan->{expected_result_rows},
                result_rows => 0 + $rows,
                results_file => $results,
                acquisition_config => $star_plan->{acquisition_config},
                manifest => $record_path,
                incumbent => $winner,
            };
        }

        my $results_path = File::Spec->catfile($dir, $root . '-0_totres.csv');
        my %post;

        if (exists $s->{expected_result_rows}) {
            my $expected = 0 + $s->{expected_result_rows};
            my $rows = _count_result_rows($results_path);
            die "experience '$state': expected $expected result rows but found $rows in $results_path\n"
                unless $rows == $expected;
            $post{expected_result_rows} = $expected;
            $post{result_rows} = 0 + $rows;
            $post{results_file} = $results_path;
        }

        if (ref($s->{required_output_files}) eq 'ARRAY') {
            my @checked;
            for my $name (@{ $s->{required_output_files} }) {
                die "experience '$state': required output filename must be scalar\n" if ref($name);
                my $path = File::Spec->file_name_is_absolute($name)
                    ? $name : File::Spec->catfile($dir, $name);
                die "experience '$state': required output missing or empty: $path\n"
                    unless -f $path && -s $path;
                push @checked, $path;
            }
            $post{required_output_files} = \@checked;
        }

        # Plain numeric search sweeps are automatically guarded as complete
        # factorial searches. This protects btr and btra without changing their
        # already-completed procedure-step signatures in an existing manifest.
        my $factorial_vars = exists($s->{expected_full_factorial})
            ? $s->{expected_full_factorial}
            : _plain_full_factorial_variables(File::Spec->catfile($dir, $cfg));
        if (defined $factorial_vars) {
            die "experience '$state': expected_full_factorial must be a non-empty ARRAY reference\n"
                unless ref($factorial_vars) eq 'ARRAY' && @$factorial_vars;
            my ($counts, $count_source, $lm_path);
            if (defined($s->{lattice_manifest}) && length($s->{lattice_manifest})) {
                my $lm_name = $s->{lattice_manifest};
                $lm_path = File::Spec->file_name_is_absolute($lm_name)
                    ? $lm_name : File::Spec->catfile($dir, $lm_name);
                die "experience '$state': lattice manifest not found: $lm_path\n" unless -f $lm_path;
                my $lm = _read_json($lm_path);
                $counts = $lm->{target_counts} || $lm->{global_counts};
                die "experience '$state': lattice manifest has no target_counts or global_counts\n"
                    unless ref($counts) eq 'HASH' && keys %$counts;
                $count_source = $lm_path;
            } else {
                require Sim::OPT::StructureDesign;
                my $cfg_path = File::Spec->catfile($dir, $cfg);
                my $ci = Sim::OPT::StructureDesign::inspect_config($cfg_path);
                $counts = $ci->{varinumbers};
                $count_source = $cfg_path;
            }
            my ($expected, $rows) = _validate_expected_factorial(
                state => $state, variables => $factorial_vars,
                counts => $counts, results => $results_path,
            );
            $post{expected_result_rows} = 0 + $expected;
            $post{result_rows} = 0 + $rows;
            $post{results_file} = $results_path;
            $post{factorial_count_source} = $count_source;
            $post{full_factorial_variables} = [ map { 0 + $_ } @$factorial_vars ];
            $post{lattice_manifest} = $lm_path if defined $lm_path;
        }

        return { %$r, state => $state, acquisition => $kind, incumbent => $winner, %post };
    }

    if ($type eq 'derive') {
        my %ops = map { (($_->{op} || '') => 1) } @{ $s->{by} || [] };
        my $plan;
        if ($ops{reduce_scope}) {
            $plan = _compile_zoom(step => $s, procedure => $p, manifest => $manifest);
        } elsif ($ops{enlarge_scope}) {
            $plan = _compile_enlarge_pan(step => $s, procedure => $p, manifest => $manifest);
        } else {
            die "derive '$s->{name}': no installed structural executor matches requested operators\n";
        }
        return { state => $s->{name}, operation => $plan->{operation}, plan => $plan } unless $commit;
        require Sim::OPT::StructureDesign;
        if (($plan->{operation} || '') eq 'zoom_in') {
            Sim::OPT::StructureDesign::create_zoom_workspace(plan => $plan, commit => 1);
            return {
                state => $s->{name},
                operation => 'reduce_scope+increase_resolution',
                incumbent_parent => $plan->{incumbent_parent},
                incumbent_refined => $plan->{incumbent_refined},
                manifest => File::Spec->catfile($plan->{child_dir}, 'structuredesign-zoom.json'),
            };
        }
        if (($plan->{operation} || '') eq 'enlarge_scope+maintain_resolution+pan') {
            Sim::OPT::StructureDesign::create_enlarge_pan_workspace(plan => $plan, commit => 1);
            return {
                state => $s->{name},
                operation => $plan->{operation},
                incumbent_source => $plan->{source_incumbent},
                incumbent_target => $plan->{target_incumbent},
                target_counts => $plan->{target_counts},
                manifest => File::Spec->catfile($plan->{child_dir}, 'structuredesign-scope.json'),
            };
        }
        die "derive '$s->{name}': compiled unsupported operation '$plan->{operation}'\n";
    }

    if ($type eq 'reembed') {
        return _execute_reembed(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'merge') {
        return _execute_merge(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'imagine') {
        my $method = (ref($s->{using}) eq 'HASH' && defined($s->{using}{method})) ? $s->{using}{method} : 'unspecified surrogate';
        die "Procedure operator 'imagine by surrogating with $method' is defined, but star/surrogate config compilation is not yet installed in the procedure runtime. Refusing to claim that a surrogate was generated.\n";
    }
    if ($type eq 'reconstruct_memory') {
        return _execute_reconstruct_memory(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'abstract') {
        return _execute_abstract(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'retain_memory') {
        return _execute_retain_memory(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'apply_abstraction') {
        return _execute_apply_abstraction(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'validation_sample') {
        return _execute_validation_sample(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'direct_validation_statistics') {
        return _execute_direct_validation_statistics(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'compare') {
        return _execute_compare(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }
    if ($type eq 'statistics') {
        return _execute_statistics(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
    }

    die "Unknown procedure step type '$type'\n";
}

sub run_procedure {
    my ($p, %opts) = @_;
    die "run_procedure: procedure HASH required\n" unless ref($p) eq 'HASH';
    my $commit = $opts{commit} ? 1 : 0;
    my $manifest_path = _manifest_path($p);
    my $manifest = _prepare_manifest(
        procedure => $p,
        manifest_path => $manifest_path,
        commit => $commit,
        from => $opts{from},
        only => $opts{only},
        accept_runtime_change => $opts{accept_runtime_change},
        accept_tail_change => $opts{accept_tail_change},
    );

    my $from_seen = !$opts{from};
    my $i = 0;
    for my $s (@{ $p->{steps} || [] }) {
        my $sid = _step_id($s, $i++);
        next unless $s->{enabled};
        if (!$from_seen) {
            if ($sid eq $opts{from}) {
                $from_seen = 1;
            } else {
                if ($commit) {
                    my $sig = _step_signature($s);
                    my $old = $manifest->{steps}{$sid};
                    die "Cannot resume --from '$opts{from}': prerequisite step '$sid' is not COMPLETE in the run manifest\n"
                        unless $old && ($old->{status} || '') eq 'COMPLETE';
                    die "Cannot resume --from '$opts{from}': prerequisite step '$sid' changed since it completed; rerun from '$sid' or earlier\n"
                        unless ($old->{signature} || '') eq $sig;
                    die "Cannot resume --from '$opts{from}': prerequisite step '$sid' is marked COMPLETE but its required output artifacts are missing; rerun from '$sid' or earlier\n"
                        unless _reconstruct_memory_artifacts_ok(step => $s, procedure => $p, old => $old);
                }
                next;
            }
        }
        next if $opts{only} && $sid ne $opts{only};

        my $sig = _step_signature($s);
        my $old = $manifest->{steps}{$sid};
        if ($commit && $old && ($old->{status} || '') eq 'COMPLETE' && ($old->{signature} || '') eq $sig && !$opts{force}) {
            if (_reconstruct_memory_artifacts_ok(step => $s, procedure => $p, old => $old)) {
                print "[StructureDesign] SKIP complete $sid\n";
                next;
            }
            print "[StructureDesign] REBUILD $sid: checkpoint is COMPLETE but required output artifacts are missing\n";
        }
        if ($commit && $old && ($old->{status} || '') eq 'COMPLETE' && ($old->{signature} || '') ne $sig && !$opts{force}) {
            if ($opts{accept_tail_change} && $opts{from}) {
                print "[StructureDesign] REBUILD changed tail step $sid under --accept-tail-change\n";
            } else {
                die "Step '$sid' changed since its completed execution. Refusing to reuse stale state; rerun with --force only after deciding how existing filesystem state should be handled.\n";
            }
        }

        print "[StructureDesign] " . ($commit ? 'RUN' : 'PLAN') . " $sid ($s->{type})\n";
        if (!$commit) {
            # A procedure dry run validates the graph and reports intent; it must not
            # require results (incumbents) or committed executors for later states.
            if ($s->{type} eq 'derive') {
                my @ops = map { $_->{op} || '?' } @{ $s->{by} || [] };
                print "  target=$s->{name} from=$s->{from}; operators=" . join('+', @ops) . "; detailed lattice plan deferred until execution inputs are available\n";
                next;
            }
            if ($s->{type} eq 'parallel') {
                my $n = ref($s->{steps}) eq 'ARRAY' ? scalar(grep { $_->{enabled} } @{ $s->{steps} }) : 0;
                my $mw = defined($s->{max_workers}) ? $s->{max_workers} : $n;
                print "  concurrent experience group; children=$n; max_workers=$mw; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'experience') {
                my $kind = ref($s->{using}) eq 'HASH' ? ($s->{using}{kind} || 'search') : 'search';
                print "  state=$s->{name}; acquisition=$kind; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'imagine') {
                my $method = ref($s->{using}) eq 'HASH' ? ($s->{using}{method} || '?') : '?';
                print "  state=$s->{name}; imagine by surrogating with $method; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'abstract') {
                my $rel = $s->{output_dir} || 'abstract';
                my $out = File::Spec->catdir(_state_dir($p, $s->{name}), $rel);
                print "  state=$s->{name}; abstract by clustering and finding medoids; outputs=$out; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'retain_memory') {
                my $rel = $s->{output_dir} || 'memory';
                my $out = File::Spec->catdir(_state_dir($p, $s->{name}), $rel);
                print "  state=$s->{name}; retain medoids with cluster-conditioned direct experience; outputs=$out; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'apply_abstraction') {
                my $rel = $s->{output_dir} || 'applied';
                my $out = File::Spec->catdir(_state_dir($p, $s->{name}), $rel);
                print "  state=$s->{name}; assign regenerated landscape to frozen antecedent categories; outputs=$out; execution deferred\n";
                next;
            }
            if ($s->{type} eq 'reconstruct_memory') {
                my $vars = ref($s->{variables}) eq 'ARRAY' ? join(',', @{ $s->{variables} }) : 'from-abstraction';
                my $rm = _reconstruction_mode_for_step($s);
                if ($rm eq 'legacy_medoid_only') {
                    print "  state=$s->{name}; reconstruct memory from=$s->{from}; variables=$vars; reconstruction_mode=legacy_medoid_only; retained medoids are the memory cues and explicit centres; auxiliary stars, if requested, are distributed over the compact shared lattice; one totres and one surrogate output\n";
                } else {
                    print "  state=$s->{name}; reconstruct memory from=$s->{from}; variables=$vars; reconstruction_mode=experiential_cloud; retained medoids remain privileged centres; retained direct experience positions and seeds one compact shared multi-star workspace; one totres and one surrogate output\n";
                }
                next;
            }
            if ($s->{type} eq 'validation_sample') {
                my $n = $s->{sample_size} // '?';
                print "  state=$s->{name}; select reproducible random validation sample of $n instances from=$s->{source_state}; write passnames_.txt\n";
                next;
            }
            if ($s->{type} eq 'direct_validation_statistics') {
                print "  compare reconstructed surrogate predictions against newly simulated validation instances\n";
                next;
            }
            if ($s->{type} eq 'statistics') {
                print "  compare source and memory landscapes; under applied recall, evaluate preservation against frozen antecedent categories\n";
                next;
            }
            if ($s->{type} =~ /^(?:reembed|merge|compare)$/) {
                print "  declared high-level operator; executor availability is checked at commit time\n";
                next;
            }
        }

        $manifest->{steps}{$sid} = {
            status => 'RUNNING', signature => $sig, started_at => _now(),
            type => $s->{type}, name => $s->{name},
        } if $commit;
        _write_json($manifest_path, $manifest) if $commit;

        my $result;
        my $ok = eval {
            $result = _execute_step(step => $s, procedure => $p, manifest => $manifest, commit => $commit);
            1;
        };
        if (!$ok) {
            my $err = $@ || 'unknown error';
            if ($commit) {
                $manifest->{steps}{$sid}{status} = 'FAILED';
                $manifest->{steps}{$sid}{failed_at} = _now();
                $manifest->{steps}{$sid}{error} = "$err";
                _write_json($manifest_path, $manifest);
            }
            die $err;
        }
        if ($commit) {
            $manifest->{steps}{$sid}{status} = 'COMPLETE';
            $manifest->{steps}{$sid}{completed_at} = _now();
            $manifest->{steps}{$sid}{result} = $result || {};
            _write_json($manifest_path, $manifest);
        }
        print "[StructureDesign] DONE $sid\n" if $commit;
    }

    die "Requested --from step '$opts{from}' was not found in the enabled procedure\n"
        if $opts{from} && !$from_seen;
    print $commit
        ? "[StructureDesign] procedure reached the end of all currently executable enabled steps. Manifest: $manifest_path\n"
        : "[StructureDesign] dry plan complete; nothing was executed. Manifest would be: $manifest_path\n";
    return $manifest;
}

1;

__END__

=head1 NAME

Sim::OPT::StructureDesignProcedure - Perl-embedded procedure language for Sim::OPT hierarchical structure design

=head1 VERSION

Module version 0.27.

Procedure-language version 1.0.

Procedure schema C<Sim::OPT::StructureDesign/procedure-1>.

=head1 SYNOPSIS

A procedure is an ordinary Perl file that returns one C<design(...)> value.
The language is embedded in Perl: Perl supplies syntax, data structures,
modules, interpolation and error handling; this module supplies the
StructureDesign vocabulary and execution semantics.

    use strict;
    use warnings;
    use Sim::OPT::StructureDesignProcedure qw(
        design state experience derive reembed merge abstract
        retain_memory reconstruct_memory statistics compare
        search clustering_and_finding_medoids
        reduce_scope increase_resolution
        enlarge_scope maintain_resolution pan
        incumbent result_of
    );

    return design 'example',
        root_dir => ($ENV{STRUCTUREDESIGN_ROOT} || $ENV{HOME}),
        steps => [

            state('base',
                id       => 'state_base',
                existing => 1,
                config   => 'base.pl',
            ),

            experience('base',
                id         => 'search_base',
                config     => 'base.pl',
                using      => search(),
                model_root => 'base',
                executable => "$ENV{HOME}/base/opt",
            ),

            derive('local',
                id            => 'make_local',
                from          => 'base',
                parent_config => 'base.pl',
                config        => 'local.pl',
                around        => incumbent('search_base'),
                by => [
                    reduce_scope(
                        variables => [1, 2, 3],
                        levels    => 3,
                    ),
                    increase_resolution(
                        variables => [1, 2, 3],
                        factor    => 2,
                    ),
                ],
            ),
        ];

A procedure can be loaded and planned without executing it:

    use Sim::OPT::StructureDesignProcedure qw(load_procedure run_procedure);
    my $p = load_procedure('./example-procedure.pl');
    run_procedure($p);

Execution is requested explicitly:

    run_procedure($p, commit => 1);

=head1 DESCRIPTION

C<Sim::OPT::StructureDesignProcedure> is the public procedure-language layer
for hierarchical StructureDesign workflows in Sim::OPT. It describes design
processes as ordered, inspectable declarations rather than embedding each
experiment directly in filesystem manipulation or Sim::OPT launch code.

The module intentionally separates three levels:

    procedure file
        -> Sim::OPT::StructureDesignProcedure language/runtime
        -> Sim::OPT::StructureDesign geometric planner and workspace engine
        -> generated Sim::OPT configurations, searches and result artifacts

A file such as C<bt-procedure.pl> is therefore a program written in this
embedded domain-specific language. It is not itself the language definition.
The language definition is the constructor vocabulary and execution semantics
implemented here.

The language is declarative in the following limited sense: constructors such
as C<derive(...)> and C<abstract(...)> create data structures that describe
intent. They do not perform filesystem operations when the procedure file is
loaded. Execution occurs later through C<run_procedure()>.

=head1 DESIGN PRINCIPLES

=head2 Procedure declarations are separate from operator implementations

The procedure states what should happen and in what order. Detailed geometry,
configuration rewriting, workspace construction, model copying and Sim::OPT
execution are implemented by installed modules.

=head2 State transitions are explicit

Each major representation is named as a state. Transformations create new
states rather than silently mutating the conceptual identity of a previous
state.

=head2 References are explicit dependencies

C<incumbent($step_id)> and C<result_of($step_id, $key)> refer to results of
previous completed steps. They are resolved from the run manifest at execution
time.

=head2 Checkpoint reuse is conservative

Completed steps are associated with signatures of their declarations and with
a runtime signature. A completed checkpoint is reused only when the runtime can
verify that the declaration and required output artifacts remain compatible.

=head2 Scientific choices belong in the procedure

Acquisition density, scope transformations, abstraction choices and memory
reactivation density belong in the procedure declaration when they are
experimental choices. They should not be hard-coded inside a generic runtime
operator.

=head1 LANGUAGE AND MODULE VERSIONING

C<$Sim::OPT::StructureDesignProcedure::VERSION> identifies the Perl module
implementation. C<procedure_language_version()> identifies the public embedded
language version. C<procedure_schema()> returns the procedure data schema.

    my $language = procedure_language_version();  # "1.1"
    my $schema   = procedure_schema();            # procedure-1 schema

The language version is deliberately separate from the module version. An
implementation can receive bug fixes without requiring a new language version.

=head1 PROCEDURE FILE CONTRACT

A procedure file must return a HASH reference created by C<design(...)> or an
equivalent structure using the supported procedure schema. C<load_procedure()>
loads the file with Perl C<do>, verifies the returned object and records the
absolute procedure-file path for provenance.

The normal form is:

    return design 'procedure_name',
        root_dir => '/path/to/root',
        steps    => [ ... ];

=head2 C<design($name, %args)>

Creates the top-level procedure object.

Common arguments:

=over 4

=item C<root_dir>

Root directory under which named state directories are resolved. Defaults to
C<$ENV{HOME}> and then C<.>.

=item C<manifest>

Optional explicit run-manifest path. If omitted, the default is:

    <root_dir>/.structuredesign/<procedure-name>.json

=item C<steps>

Array reference containing the ordered procedure steps.

=back

Every constructor-generated step is enabled by default. Set C<enabled =E<gt> 0>
to retain a declaration without executing it.

=head1 STEP IDENTIFIERS

A step should normally have an explicit C<id>. References and C<--from>-style
resumption use step identifiers, not state names.

If no C<id> is supplied, the runtime generates an identifier from ordinal
position, step type and step name. Explicit IDs are preferable for procedures
intended to be resumed, cited or maintained over time.

Example:

    experience('base',
        id => 'search_base',
        ...
    )

=head1 CORE STEP CONSTRUCTORS

=head2 C<state($name, %args)>

Declares a named problem-space state.

For an already existing state:

    state('base',
        id       => 'state_base',
        existing => 1,
        config   => 'base.pl',
    )

The runtime verifies that the state directory and configuration file exist.

A state can also be cloned from another state:

    state('branch',
        id                => 'state_branch',
        from              => 'source',
        source_config     => 'source.pl',
        config            => 'branch.pl',
        model_root        => 'bt',
        geometry_manifest => 'structuredesign-scope.json',
    )

For cloned states the canonical model root is copied, the configuration is
rendered for the target directory, and an optional geometry manifest is
materialized for the clone. Existing target directories are not overwritten.

Optional C<config_variant> and inherited C<dowhat> values can be used when the
clone requires a controlled configuration variant.

=head2 C<experience($state, %args)>

Runs an acquisition/evaluation operation in a state.

The installed executor supports C<search()> and C<star(...)> acquisition kinds.
Other acquisition descriptors may be representable by the language but are not
silently substituted for an installed executor.

Typical search form:

    experience('sampled',
        id           => 'sample_sampled',
        config       => 'sampled.meta.pl',
        config_from  => 'sampled.pl',
        using        => search(),
        model_root   => 'bt',
        executable   => "$ENV{HOME}/bt/opt",
        config_variant => {
            sweeps => [ [ '2>1', 2, 3, 4, 5 ] ],
            dowhat => {
                names             => 'short',
                metamodel         => 'y',
                convergeintomodel => 'y',
            },
        },
    )

When C<config_from> is present, the runtime creates the requested configuration
variant before launching Sim::OPT.

Useful validation arguments include:

=over 4

=item C<expected_result_rows>

Require an exact number of rows in the direct result file after the run.

=item C<expected_full_factorial>

Array reference of variables expected to have been exhaustively enumerated.
The expected count is derived from the active lattice rather than hard-coded.

=item C<required_output_files>

Array reference of files that must exist and be non-empty after execution.

=item C<geometry_manifest> or C<lattice_manifest>

Geometry information used to validate or count the active lattice.

=item C<config_variant>

Controlled modifications to C<@sweeps>, C<%dowhat> and, where used internally,
explicit star positions.

=item C<inherit_dowhat>

Requests selected C<%dowhat> string values from another state's configuration.
An explicit value in C<config_variant.dowhat> takes precedence over an inherited
value.

=back

After Sim::OPT completes, the runtime determines the clear incumbent from the
produced result evidence. An incumbent-dependent downstream step cannot proceed
without a resolvable winner.

=head2 C<derive($target, %args)>

Declares a structural transformation from one state into another.

The C<by> argument is an array of structural operators.

The current runtime has two installed derive families.

=head3 Local refinement

    derive('local',
        from   => 'base',
        around => incumbent('search_base'),
        by => [
            reduce_scope(variables => [1,2,3], levels => 3),
            increase_resolution(variables => [1,2,3], factor => 2),
        ],
    )

C<reduce_scope> is required by this executor. C<increase_resolution> is
optional. Geometry is planned by C<Sim::OPT::StructureDesign::plan_zoom_in>.

C<mediumiters> and C<refined_mediumiters> can be supplied explicitly when a
procedure needs to override the planner's normal policy.

=head3 Scope enlargement with preserved resolution and panning

    derive('wide',
        from => 'merged',
        by => [
            enlarge_scope(variables => [1,2,3,4,5], factor => 2),
            maintain_resolution(variables => [1,2,3,4,5]),
            pan(around => incumbent('make_merged')),
        ],
    )

The installed executor requires all three operators. The source lattice
manifest supplies the existing global counts; the planner derives the enlarged
geometry without requiring physical step sizes to be repeated in the procedure.

=head2 C<reembed($target, %args)>

Re-embeds a locally refined state into the global refined lattice described by
a zoom manifest.

Typical form:

    reembed('refined_global',
        id         => 'make_refined_global',
        from       => 'local',
        into       => 'global_refined_lattice',
        config     => 'refined_global.pl',
        incumbent  => incumbent('search_local'),
        model_root => 'bt',
    )

The executor maps local clear instance identifiers into global refined-lattice
coordinates, rewrites result identities and cryptolinks consistently, and can
translate the local incumbent into the global coordinate system.

=head2 C<merge($target, %args)>

Combines compatible parent and refined experience on a common refined lattice.

    merge('merged',
        id               => 'make_merged',
        parent           => 'base',
        refined          => 'refined_global',
        zoom_plan        => 'local/structuredesign-zoom.json',
        incumbent_policy => 'best_merged_scalar',
        config           => 'merged.pl',
        model_root       => 'bt',
    )

Overlapping physical instances must have compatible result payloads. The
refined state's canonical geometry is cloned into the merged state; merging
changes accumulated experience, not the lattice geometry itself.

Do not specify both an explicit C<incumbent> and C<incumbent_policy>.

=head2 C<abstract($state, %args)>

Compresses a represented landscape by clustering and medoid selection.

    abstract('landscape',
        id               => 'abstract_landscape',
        source           => 'weightordmeta',
        results_file     => 'bt-report-0-0.csv_sortm.csv_weightordmeta.csv',
        lattice_manifest => 'structuredesign-scope.json',
        using            => clustering_and_finding_medoids(
                                selection => 'hierarchical_distortion'),
        output_dir       => 'abstract',
        output_prefix    => 'landscape-weightordmeta',
        model_root       => 'bt',
    )

The installed abstraction executor delegates to
C<Sim::OPT::ClusterMedoid>. The supplied results file defines the landscape
being clustered. Consequently, a medoid is an actual row of that landscape,
but it is not necessarily a directly simulated row if the landscape itself is
a surrogate C<weightordmeta> representation.

The abstraction manifest records the selected medoids and the metric metadata
needed by later reconstruction and statistical comparison.

The C<source> string is provenance metadata. The operative dataset is selected
by C<results_file>.

=head2 C<retain_memory($state, %args)>

Materialises the declarative memory passed from a completed abstraction.  The
retained object is not only the medoid set: every directly experienced result
row is joined to its already-frozen cluster membership and stored with the
corresponding medoid/category.

    retain_memory('landscape',
        id              => 'retain_landscape_memory',
        abstraction     => result_of('abstract_landscape', 'manifest'),
        experience_file => 'bt-0_ordres.csv',
        experience_kind => 'direct_simulation',
        output_dir      => 'memory-retained',
    )

C<experience_file> must contain actual accumulated experience, not the surrogate
landscape used for clustering.  Cluster pertinence is inherited by exact
instance identity from the frozen clustered landscape; retention does not
recluster or reassign those experiences.  A category is allowed to have zero
direct support: its medoid remains a valid retained archetypal cue.

=head2 C<reconstruct_memory($target, %args)>

Reactivates a retained abstraction into one shared compact memory workspace.
The reconstruction semantics are selected by C<reconstruction_mode>.  This is
an experimental/scientific choice and should be explicit in new procedures.

Two modes are available.

=head3 C<reconstruction_mode =E<gt> 'legacy_medoid_only'>

This reproduces the historical reconstruction used for the first recall runs.
Only the abstraction medoids are retained as memory cues.  They remain explicit
star centres in a compact shared lattice derived from their source positions.
Optional C<star_divisions> adds an nE<gt>-equivalent evenly distributed set of
auxiliary centres over that same recalled lattice; these auxiliary centres do
not replace the medoids.

    reconstruct_memory('memory',
        id                  => 'reconstruct_memory',
        reconstruction_mode => 'legacy_medoid_only',
        from                => 'landscape',
        source_config       => 'landscape.pl',
        abstraction         => result_of('abstract_landscape', 'manifest'),
        variables           => [1,2,3,4,5],
        star_divisions      => 3,       # optional enriched legacy probing
        model_root          => 'bt',
        memory_model_root   => 'btmed',
        executable          => "$ENV{HOME}/bt/opt",
    )

No retained experiential packet is required or consumed in this mode.  If a
procedure also contains a C<memory> argument, it is deliberately ignored by the
legacy executor so that a comparison procedure can change only the mode switch.
For the same reason C<cloud_star_divisions> is accepted as an alias of
C<star_divisions> while legacy mode is selected.

=head3 C<reconstruction_mode =E<gt> 'experiential_cloud'>

This implements medoid-anchored experiential recall.  The abstraction medoids
remain privileged archetypal cues, but a retained memory packet also carries
directly experienced points with their already-frozen category pertinence.

    reconstruct_memory('memory',
        id                  => 'reconstruct_memory',
        reconstruction_mode => 'experiential_cloud',
        from                => 'landscape',
        source_config       => 'landscape.pl',
        abstraction         => result_of('abstract_landscape', 'manifest'),
        memory              => result_of('retain_landscape_memory', 'manifest'),
        variables           => [1,2,3,4,5],
        cloud_star_divisions => 3,      # optional enriched cloud probing
        model_root          => 'bt',
        memory_model_root   => 'btmed',
        executable          => "$ENV{HOME}/bt/opt",
    )

The architecture is:

    frozen categories + retained medoids + cluster-conditioned direct experience
        -> one compact shared source-grid-aligned memory lattice
        -> remembered direct rows seed the accumulated result set
        -> one mandatory reactivation star per medoid
        -> optional cloud-conditioned auxiliary stars
        -> one reconstructed surrogate landscape

The recalled scope is not expanded to the full antecedent lattice merely
because remembered points span it.  Retained experiential clouds position the
compact window.  If a category has direct remembered support but the nominal
window would contain none of it, the planner expands only enough to admit at
least one remembered point from that category.  A category with zero direct
support remains represented by its medoid alone.

C<cloud_star_divisions> enriches renewed probing by selecting additional actual
remembered experiences within each frozen category using deterministic maximin
spatial coverage.  These centres are therefore conditioned by the remembered
cloud rather than cast uniformly across an invented common box.

=head3 Backward-compatible mode inference

Historical procedure files predate C<reconstruction_mode>.  To keep them
replayable under one installed Sim::OPT version, omission of the switch is
interpreted as follows:

    memory => ... present     -> experiential_cloud
    no memory argument        -> legacy_medoid_only

This inference exists only for backward compatibility.  Procedures prepared
for publication or new experiments should specify C<reconstruction_mode>
explicitly so the reconstruction semantics are directly inspectable.

Other useful arguments in both modes include C<medoid_limit>, C<mediumiters>,
C<inherit_dowhat>, C<source_config>, C<model_root> and C<memory_model_root>.

The executor verifies the exact expected sampled union and the completeness of
the reconstructed surrogate lattice according to the selected mode.

=head2 C<statistics($pair_name, %args)>

Compares two represented landscapes and their abstractions.

    statistics('source-memory',
        id                    => 'statistics_source_memory',
        left                  => 'source',
        right                 => 'memory',
        left_abstraction      => result_of('abstract_source', 'manifest'),
        right_abstraction     => result_of('abstract_memory', 'manifest'),
        right_memory_manifest => 'structuredesign-memory-local.json',
        left_model_root       => 'bt',
        right_model_root      => 'btmed',
        statistics_dir        => 'statistics',
        output_dir            => 'source-memory',
    )

When the right-hand state is a compressed memory state, the memory manifest is
used to map local memory coordinates back into source-lattice coordinates
before comparison. Raw local memory instance names therefore must not be
compared directly with source instance names.

The statistics executor records pointwise regression/error measures, categories
based on direct versus surrogate status, globally matched medoid distances,
set-level medoid measures, adjusted Rand index and aligned cluster agreement.
It writes machine-readable JSON and CSV outputs.

=head2 C<compare($name, %args)>

Performs direct-evidence validation between two states sharing physical
instances and a prediction landscape.

    compare('sparse_dense_validation',
        id               => 'validate_sparse_against_dense',
        left             => 'sparse',
        right            => 'dense',
        model_root       => 'bt',
        prediction_state => 'sparse',
        prediction_file  => 'bt-report-0-0.csv_sortm.csv_weightordmeta.csv',
        output_file      => 'structuredesign-validation.json',
    )

Shared direct simulations are first required to agree within
C<overlap_tolerance> (default C<1e-9>). Right-only instances form the holdout
set. Predictions for those instances are compared with their direct right-hand
results on the left-hand normalization scale.

Optional count guards include C<expected_left_rows>, C<expected_right_rows>,
C<expected_overlap_rows> and C<expected_holdout_rows>.

=head2 C<imagine($state, %args)>

C<imagine> is part of the article-facing language vocabulary. It represents
"imagine by surrogating with ...". In module 0.25 the dedicated generic
C<imagine> configuration compiler is intentionally not installed. A committed
C<imagine> step therefore fails explicitly rather than silently running an
incorrect surrogate operation.

Existing procedures obtain surrogate landscapes through supported Sim::OPT
search/configuration variants and through memory reconstruction.

=head1 DESCRIPTOR CONSTRUCTORS

=head2 C<search(%args)>

Returns an acquisition descriptor with C<kind =E<gt> 'search'>.

=head2 C<star(%args)>

Returns an acquisition descriptor with C<kind =E<gt> 'star'>. The installed
star-experience compiler uses StructureDesign star planning and validates the
result count.

=head2 C<surrogate(%args)>

Returns a generic surrogate descriptor. It is vocabulary-level infrastructure;
not every descriptor has an independent committed executor.

=head2 C<surrogating_with($method, %args)>

Article-facing surrogate descriptor retaining the named method.

=head2 C<medoids(%args)>

Compatibility abstraction descriptor accepted by the installed abstraction
executor.

=head2 C<clustering_and_finding_medoids(%args)>

Preferred abstraction descriptor. The currently used selection policy is
C<hierarchical_distortion> when requested by the procedure. Parameters are
passed through the generated ClusterMedoid configuration where supported.

=head2 C<clustering_and_medoiding(%args)>

Backward-compatible alias for C<clustering_and_finding_medoids>. New procedure
files should use the latter spelling.

=head1 STRUCTURAL OPERATORS

These constructors are normally placed in a C<derive(..., by =E<gt> [...])>
array.

=head2 C<reduce_scope(%args)>

Declares local scope reduction. Common arguments are C<variables> and C<levels>.

=head2 C<increase_resolution(%args)>

Declares increased resolution. Common arguments are C<variables>, C<factor>,
optional per-variable C<factors>, and optional C<local_strides>.

=head2 C<enlarge_scope(%args)>

Declares scope enlargement. Common arguments are C<variables> and C<factor>.

=head2 C<maintain_resolution(%args)>

Declares that enlargement should retain physical resolution for the listed
variables.

=head2 C<pan(%args)>

Declares a shift of the represented scope. C<around> normally refers to an
incumbent from an earlier step.

=head2 C<decrease_resolution(%args)>

The constructor is part of the language vocabulary. The current derive
executor does not install a general committed executor for an arbitrary
C<decrease_resolution> transformation. A procedure must therefore not assume
that declaration alone implies executable support.

=head1 REFERENCE EXPRESSIONS

=head2 C<incumbent($step_id)>

Creates a deferred reference to the C<incumbent> result of a completed step.

    around => incumbent('search_base')

The reference is resolved only during execution. The referenced step must be
C<COMPLETE> in the run manifest and must have recorded an incumbent.

=head2 C<result_of($step_id, $key)>

Creates a deferred reference to a named result field of a completed step.

    abstraction => result_of('abstract_source', 'manifest')

If C<$key> is omitted, the default key is C<result>.

=head1 CONFIGURATION VARIANTS AND INHERITANCE

Several state and experience operations can create a derived Sim::OPT
configuration without hand-editing the generated file.

A C<config_variant> can contain:

    config_variant => {
        sweeps => [ [ '2>1', 2, 3, 4, 5 ] ],
        dowhat => {
            names             => 'short',
            metamodel         => 'y',
            convergeintomodel => 'y',
        },
    }

The runtime patches the active C<@sweeps> assignment and requested C<%dowhat>
keys, then validates that the generated text contains the requested values.

C<inherit_dowhat> has the form:

    inherit_dowhat => {
        from_state => 'base',
        config     => 'base.pl',
        keys       => [ 'canon' ],
    }

Only the requested string-valued keys are inherited. An explicit value in
C<config_variant.dowhat> overrides the inherited value.

=head1 SIM::OPT SWEEP SYNTAX

The procedure language does not redefine Sim::OPT sweep semantics; it carries
sweep declarations into generated configurations.

For this Sim::OPT codebase:

    [ [ 1, 2, 3, 4, 5 ] ]

is one full-factorial sweep block over variables 1 through 5, whereas:

    [ [1], [2], [3], [4], [5] ]

is sequential coordinate descent.

Subdivision star notation such as:

    [ [ '2>1', 2, 3, 4, 5 ] ]

uses Sim::OPT's C<nE<gt>> mechanism to generate star centres. Procedure code
should not replace that mechanism with a hand-maintained external
C<starpositions> file unless an operator explicitly requires resolved star
positions internally.

=head1 ABSTRACTION, EXPERIENCE AND SURROGATE LANDSCAPES

The dataset passed to C<abstract()> determines what the medoids represent.
Clustering C<bt-0_totres.csv> selects medoids from directly accumulated result
rows. Clustering a C<weightordmeta> file selects medoids from the represented
surrogate landscape. Such a medoid is an actual row of the clustered landscape,
but it can correspond to a surrogate-predicted rather than directly simulated
instance.

This distinction is intentional and should be preserved in scientific
interpretation.

=head1 MEMORY RECONSTRUCTION SEMANTICS

Memory reconstruction treats retained medoids as privileged retrieval cues and
retained direct cluster members as experiential support.  It does not store one
independent model workspace per medoid.  The support clouds choose and, when
needed, minimally enlarge one compact shared lattice.  Direct remembered rows
inside that lattice seed the result set before renewed probing, after which one
reconstructed surrogate landscape is produced.

The source-to-memory mapping, seed provenance, category-conditioned support
counts and auxiliary cloud centres are recorded in the memory manifest.
Downstream recall classification applies the frozen antecedent category model;
it does not refit clusters or move medoids.

C<cloud_star_divisions> controls renewed probing density. It does not redefine
the retained categories or medoids.

=head1 DRY RUNS AND EXECUTION

=head2 C<load_procedure($file)>

Loads a procedure file and verifies its top-level schema.

=head2 C<run_procedure($procedure, %options)>

Without C<commit =E<gt> 1>, the runtime performs a dry plan. It reports the
declared operations without executing Sim::OPT or requiring downstream results
that can exist only after earlier committed steps.

Common options:

=over 4

=item C<commit>

Execute rather than only plan.

=item C<from>

Resume from a named step ID. Every enabled prerequisite step before C<from>
must be recorded as complete with the same step signature and with required
artifacts still present.

=item C<only>

Select only one step ID after normal manifest safety checks.

=item C<force>

Allow a completed step to be rebuilt instead of reused. This does not waive
operator-specific refusal to overwrite an existing target directory.

=item C<accept_runtime_change>

With an explicit C<from>, accept a manifest difference caused only by a changed
StructureDesign runtime. Completed prerequisite declarations are still checked.

=item C<accept_tail_change>

With an explicit C<from>, accept a procedure declaration change in the selected
step or later tail, provided earlier prerequisite step signatures still match.

=back

=head1 RUN MANIFEST AND CHECKPOINTING

The default run manifest is stored under:

    <root_dir>/.structuredesign/<procedure-name>.json

It records the procedure signature, runtime signature, step status, timestamps,
step signatures and results returned by completed operators.

A procedure/runtime mismatch is treated conservatively. Unless an explicitly
supported partial-resume exception is requested, a committed full run archives
the stale manifest and generated states before starting a new run. Partial runs
are rejected when the manifest cannot prove their prerequisites safe.

The runtime also verifies required artifacts for checkpointed abstractions,
comparisons and reconstructed memories before treating their C<COMPLETE> status
as reusable.

=head1 FILESYSTEM SAFETY

Structural operators that create new states normally refuse to overwrite an
existing target directory. This is separate from checkpoint policy. C<force>
controls checkpoint reuse; it is not a general filesystem overwrite switch.

Generated configuration variants are validated before or after materialization
as appropriate. Geometry manifests are treated as part of the state contract,
not merely as informal logs.

=head1 OUTPUT AND PROVENANCE ARTIFACTS

Depending on the operators used, a procedure can create:

=over 4

=item * state directories and generated Sim::OPT configuration files

=item * zoom, re-embedding, merge, scope and memory manifests

=item * direct C<totres> result files

=item * surrogate C<weightordmeta> landscapes

=item * clustering/medoid abstractions

=item * comparison and validation JSON

=item * landscape, medoid and cluster statistics in JSON/CSV form

=item * the top-level procedure run manifest

=back

These artifacts are part of the executable provenance of the procedure.

=head1 IMPLEMENTATION STATUS

The language vocabulary is intentionally somewhat broader than the installed
executor set. Module 0.27 installs committed execution for the step families
used by the current StructureDesign production workflows: state creation and
cloning, search/star experience, the two supported derive families, re-embedding,
merge, clustering/medoid abstraction, experiential-memory retention, frozen-category application, shared-memory reconstruction, statistics
and comparison.

The generic C<imagine> executor and arbitrary combinations involving
C<decrease_resolution> are represented but deliberately fail rather than being
silently approximated by a different operation.

This distinction between a language construct and an installed executor should
be maintained when the language is extended.

=head1 EXTENDING THE LANGUAGE

A new language operator should normally have three parts:

=over 4

=item 1. A small constructor that records intent without side effects.

=item 2. An executor or compiler that validates the declaration and delegates
geometry or workspace mechanics to the appropriate Sim::OPT module.

=item 3. Manifest/provenance output sufficient to reproduce and validate the
resulting state transition.

=back

New experimental choices should be exposed as procedure arguments rather than
embedded as fixed behavior in the runtime when more than one scientifically
meaningful policy is possible.

=head1 COMPLETE PUBLIC EXPORT SET

Module 0.27 offers the following symbols through C<@EXPORT_OK>:

    design
    state
    experience
    derive
    reembed
    merge
    imagine
    abstract
    retain_memory
    apply_abstraction
    compare
    statistics
    reconstruct_memory

    search
    star
    surrogate
    medoids
    surrogating_with
    clustering_and_finding_medoids
    clustering_and_medoiding

    reduce_scope
    enlarge_scope
    increase_resolution
    decrease_resolution
    pan
    maintain_resolution

    incumbent
    result_of

    procedure_language_version
    procedure_schema

    load_procedure
    run_procedure

Nothing is exported by default.

=head1 RELATION TO C<Sim::OPT::StructureDesign>

This module is the procedure-language and execution-orchestration layer.
C<Sim::OPT::StructureDesign> is the lower-level geometric planner, mapping and
workspace-construction engine. Procedure files should normally call the public
constructors in this module rather than invoking private geometric helpers
directly.

=head1 RELATION TO C<Sim::OPT::ClusterMedoid>

C<abstract()> with C<clustering_and_finding_medoids()> delegates clustering and
medoid selection to C<Sim::OPT::ClusterMedoid>. Cluster-selection algorithms and
dissimilarity mechanics are therefore implementation choices of the
abstraction operator rather than syntax of the procedure language itself.

=head1 RECOMMENDED TERMINOLOGY

For technical documentation, the most precise description is:

    Sim::OPT StructureDesign Procedure Language

or:

    a Perl-embedded domain-specific language (DSL) for StructureDesign procedures

A particular C<*-procedure.pl> file is a program written in that language.

=head1 DOCUMENTATION PROVENANCE

This manual was initially drafted with the assistance of ChatGPT (OpenAI) from
the source code of C<Sim::OPT::StructureDesignProcedure>,
C<Sim::OPT::StructureDesign> and the associated production procedure. The
technical descriptions were checked against the implementation during drafting.
Responsibility for the final software and documentation remains with the
software author and maintainer.

=head1 SEE ALSO

L<Sim::OPT::StructureDesign>, L<Sim::OPT::ClusterMedoid>, C<perldoc>, and the
procedure examples distributed with this module.

=cut
