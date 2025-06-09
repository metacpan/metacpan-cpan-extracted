package Pod::L10N::Html;
use strict;
use Exporter 'import';

our $VERSION = '1.08';
$VERSION = eval $VERSION;
our @EXPORT = qw(pod2htmll10n htmlify);
our @EXPORT_OK = qw(anchorify relativize_url);

use Config;
use Cwd;
use File::Basename;
use File::Spec;
use Pod::Simple::Search;
use Pod::Simple::SimpleTree ();
use Pod::L10N::Html::Util qw(
    html_escape
    process_command_line
    trim_leading_whitespace
    unixify
    usage
    htmlify
    anchorify
    relativize_url
);
use locale; # make \w work right in non-ASCII lands

use Pod::L10N::Model;

=head1 NAME

Pod::L10N::Html - module to convert pod files to HTML with L10N

=head1 SYNOPSIS

    use Pod::L10N::Html;
    pod2htmll10n([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.

Its API is fully compatible with L<Pod::Html>.

If input files support L<Pod::L10N::Format> extended format,
Pod::L10N::Html do some more works to print translated text pretty well.

=head1 ADDITIONAL FEATURES

Additional features from L<Pod::Html> 1.33 are:

=over

=item *

Support L<Pod::L10N::Format> extended format.

=back

=head1 FUNCTIONS

=head2 pod2htmll10n

    pod2htmll10n("pod2htmll10n",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

See L<Pod::Html> for details.

=head2 htmlify

    htmlify($heading);

See L<Pod::Html> for details.

=head2 anchorify

    anchorify(@heading);

See L<Pod::Html> for details.

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHOR

C<Pod::L10N::Html> is based on L<Pod::Html> Version 1.33 written by
Marc Green, E<lt>marcgreen@cpan.orgE<gt>. 

Modification to C<Pod::L10N::Html> is written by SHIRAKATA Kentaro,
E<lt>argrath@cpan.orgE<gt>.

=head1 SEE ALSO

L<perlpod>, L<Pod::Html>, L<Pod::L10N::Format>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub pod2htmll10n {
    local(@ARGV) = @_;
    local $_;

    my $self = Pod::L10N::Html->new();
    $self->init_globals();

    my $opts = process_command_line;
    $self->process_options($opts);

    $self->refine_globals();

    # load or generate/cache %Pages
    unless ($self->get_cache()) {
        # generate %Pages
        #%Pages = $self->generate_cache(\%Pages);
        $self->generate_cache($self->{Pages});
    }
    my $input   = $self->identify_input();

    my ($lcontent, $lencoding) = arrange($self->{Podfile});
    if(!defined $lencoding){
        $lencoding = 'utf-8';
    }
    $self->{Lcontent} = $lcontent;
    $self->{Lencoding} = $lencoding;

    my $podtree = $self->parse_input_for_podtree($input);
    $self->set_Title_from_podtree($podtree);

    # set options for the HTML generator
    my     $parser = Pod::L10N::Html::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($self->{Backlink}); # linkify =head1 directives
    $parser->force_title($self->{Title});
    $parser->htmldir($self->{Htmldir});
    $parser->htmlfileurl($self->{Htmlfileurl});
    $parser->htmlroot($self->{Htmlroot});
    $parser->index($self->{Doindex});
    # still need as parse twice
    $parser->no_errata_section(!$self->{Poderrors}); # note the inverse
    $parser->output_string(\$self->{output}); # written to file later
    #$parser->pages(\%Pages);
    $parser->pages($self->{Pages});
    $parser->quiet($self->{Quiet});
    $parser->verbose($self->{Verbose});

#    $parser->html_charset('UTF-8');
    $parser->html_encode_chars('&<>">');
#    $parser->html_header_tags('');

    $parser = $self->refine_parser($parser);
    $self->feed_tree_to_parser($parser, $podtree);
    $self->write_file();
}

sub init_globals {
    my $self = shift;
    $self->{Cachedir} = ".";            # The directory to which directory caches
                                        #   will be written.

    $self->{Dircache} = "pod2htmd.tmp";

    $self->{Htmlroot} = "/";            # http-server base directory from which all
                                        #   relative paths in $podpath stem.
    $self->{Htmldir} = "";              # The directory to which the html pages
                                        #   will (eventually) be written.
    $self->{Htmlfile} = "";             # write to stdout by default
    $self->{Htmlfileurl} = "";          # The url that other files would use to
                                        # refer to this file.  This is only used
                                        # to make relative urls that point to
                                        # other files.

    $self->{Poderrors} = 1;
    $self->{Podfile} = "";              # read from stdin by default
    $self->{Podpath} = [];              # list of directories containing library pods.
    $self->{Podroot} = $self->{Curdir} = File::Spec->curdir;
                                        # filesystem base directory from which all
                                        #   relative paths in $podpath stem.
    $self->{Css} = '';                  # Cascading style sheet
    $self->{Recurse} = 1;               # recurse on subdirectories in $podpath.
    $self->{Quiet} = 0;                 # not quiet by default
    $self->{Verbose} = 0;               # not verbose by default
    $self->{Doindex} = 1;               # non-zero if we should generate an index
    $self->{Backlink} = 0;              # no backlinks added by default
    $self->{Header} = 0;                # produce block header/footer
    $self->{Title} = undef;             # title to give the pod(s)
    $self->{Saved_Cache_Key} = '';
    $self->{Pages} = {};
    return $self;
}

sub process_options {
    my ($self, $opts) = @_;

    $self->{Podpath}   = (defined $opts->{podpath})
                            ? [ split(":", $opts->{podpath}) ]
                            : [];

    $self->{Backlink}  =          $opts->{backlink}   if defined $opts->{backlink};
    $self->{Cachedir}  =  unixify($opts->{cachedir})  if defined $opts->{cachedir};
    $self->{Css}       =          $opts->{css}        if defined $opts->{css};
    $self->{Header}    =          $opts->{header}     if defined $opts->{header};
    $self->{Htmldir}   =  unixify($opts->{htmldir})   if defined $opts->{htmldir};
    $self->{Htmlroot}  =  unixify($opts->{htmlroot})  if defined $opts->{htmlroot};
    $self->{Doindex}   =          $opts->{index}      if defined $opts->{index};
    $self->{Podfile}   =  unixify($opts->{infile})    if defined $opts->{infile};
    $self->{Htmlfile}  =  unixify($opts->{outfile})   if defined $opts->{outfile};
    $self->{Poderrors} =          $opts->{poderrors}  if defined $opts->{poderrors};
    $self->{Podroot}   =  unixify($opts->{podroot})   if defined $opts->{podroot};
    $self->{Quiet}     =          $opts->{quiet}      if defined $opts->{quiet};
    $self->{Recurse}   =          $opts->{recurse}    if defined $opts->{recurse};
    $self->{Title}     =          $opts->{title}      if defined $opts->{title};
    $self->{Verbose}   =          $opts->{verbose}    if defined $opts->{verbose};

    warn "Flushing directory caches\n"
        if $opts->{verbose} && defined $opts->{flush};
    $self->{Dircache} = "$self->{Cachedir}/pod2htmd.tmp";
    if (defined $opts->{flush}) {
        1 while unlink($self->{Dircache});
    }
    return $self;
}

sub refine_globals {
    my $self = shift;

    # prevent '//' in urls
    $self->{Htmlroot} = "" if $self->{Htmlroot} eq "/";
    $self->{Htmldir} =~ s#/\z##;

    if (  $self->{Htmlroot} eq ''
       && defined( $self->{Htmldir} )
       && $self->{Htmldir} ne ''
       && substr( $self->{Htmlfile}, 0, length( $self->{Htmldir} ) ) eq $self->{Htmldir}
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        #$self->{Htmlfileurl} = "$self->{Htmldir}/" . substr( $self->{Htmlfile}, length( $self->{Htmldir} ) + 1);
        # Is the above not just "$self->{Htmlfileurl} = $self->{Htmlfile}"?
        $self->{Htmlfileurl} = unixify($self->{Htmlfile});
    }
    return $self;
}

sub generate_cache {
    my $self = shift;
    my $pwd = getcwd();
    chdir($self->{Podroot}) ||
        die "$0: error changing to directory $self->{Podroot}: $!\n";

    # find all pod modules/pages in podpath, store in %Pages
    # - inc(0): do not prepend directories in @INC to search list;
    #     limit search to those in @{$self->{Podpath}}
    # - verbose: report (via 'warn') what search is doing
    # - laborious: to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
    # - recurse: go into subdirectories
    # - survey: search for POD files in PodPath
    my ($name2path, $path2name) = 
        Pod::Simple::Search->new->inc(0)->verbose($self->{Verbose})->laborious(1)
        ->recurse($self->{Recurse})->survey(@{$self->{Podpath}});
    # remove Podroot and extension from each file
    for my $k (keys %{$name2path}) {
        $self->{Pages}{$k} = _transform($self, $name2path->{$k});
    }

    chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

    # cache the directory list for later use
    warn "caching directories for later use\n" if $self->{Verbose};
    open my $cache, '>', $self->{Dircache}
        or die "$0: error open $self->{Dircache} for writing: $!\n";

    print $cache join(":", @{$self->{Podpath}}) . "\n$self->{Podroot}\n";
    my $_updirs_only = ($self->{Podroot} =~ /\.\./) && !($self->{Podroot} =~ /[^\.\\\/]/);
    foreach my $key (keys %{$self->{Pages}}) {
        if($_updirs_only) {
          my $_dirlevel = $self->{Podroot};
          while($_dirlevel =~ /\.\./) {
            $_dirlevel =~ s/\.\.//;
            # Assume $Pagesref->{$key} has '/' separators (html dir separators).
            $self->{Pages}->{$key} =~ s/^[\w\s\-\.]+\///;
          }
        }
        print $cache "$key $self->{Pages}->{$key}\n";
    }
    close $cache or die "error closing $self->{Dircache}: $!";
}

sub _transform {
    my ($self, $v) = @_;
    $v = $self->{Podroot} eq File::Spec->curdir
               ? File::Spec->abs2rel($v)
               : File::Spec->abs2rel($v,
                                     File::Spec->canonpath($self->{Podroot}));

    # Convert path to unix style path
    $v = unixify($v);

    my ($file, $dir) = fileparse($v, qr/\.[^.]*/); # strip .ext
    return $dir.$file;
}

sub get_cache {
    my $self = shift;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = $self->cache_key();
    return 1 if $self->{Saved_Cache_Key} and $this_cache_key eq $self->{Saved_Cache_Key};
    $self->{Saved_Cache_Key} = $this_cache_key;

    # load the cache of %Pages if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $self->{Dircache}) {
        warn "scanning for directory cache\n" if $self->{Verbose};
        $tests = $self->load_cache();
    }

    return $tests;
}

sub cache_key {
    my $self = shift;
    return join('!',
        $self->{Dircache},
        $self->{Recurse},
        @{$self->{Podpath}},
        $self->{Podroot},
        stat($self->{Dircache}),
    );
}

#
# load_cache - tries to find if the cache stored in $dircache is a valid
#  cache of %Pages.  if so, it loads them and returns a non-zero value.
#
sub load_cache {
    my $self = shift;
    my $tests = 0;
    local $_;

    warn "scanning for directory cache\n" if $self->{Verbose};
    open(my $cachefh, '<', $self->{Dircache}) ||
        die "$0: error opening $self->{Dircache} for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if (join(":", @{$self->{Podpath}}) eq $_);

    # is it the same podroot?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if ($self->{Podroot} eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($cachefh);
        return 0;
    }

    warn "loading directory cache\n" if $self->{Verbose};
    while (<$cachefh>) {
        /(.*?) (.*)$/;
        $self->{Pages}->{$1} = $2;
    }

    close($cachefh);
    return 1;
}

sub identify_input {
    my $self = shift;
    my $input;
    unless (@ARGV && $ARGV[0]) {
        if ($self->{Podfile} and $self->{Podfile} ne '-') {
            $input = $self->{Podfile};
        } else {
            $input = '-'; # XXX: make a test case for this
        }
    } else {
        $self->{Podfile} = $ARGV[0];
        $input = *ARGV;
    }
    return $input;
}

sub parse_input_for_podtree {
    my ($self, $input) = @_;
    # set options for input parser
    my $input_parser = Pod::Simple::SimpleTree->new;
    # Normalize whitespace indenting
    $input_parser->strip_verbatim_indent(\&trim_leading_whitespace);

    $input_parser->codes_in_verbatim(0);
    $input_parser->accept_targets(qw(html HTML));
    $input_parser->no_errata_section(!$self->{Poderrors}); # note the inverse

    warn "Converting input file $self->{Podfile}\n" if $self->{Verbose};
    my $podtree = $input_parser->parse_string_document($self->{Lcontent})->root;
    return $podtree;
}

sub set_Title_from_podtree {
    my ($self, $podtree) = @_;
    unless(defined $self->{Title}) {
        if($podtree->[0] eq "Document" && ref($podtree->[2]) eq "ARRAY" &&
            $podtree->[2]->[0] eq "head1" && @{$podtree->[2]} == 3 &&
            ref($podtree->[2]->[2]) eq "" && $podtree->[2]->[2] eq "NAME" &&
            ref($podtree->[3]) eq "ARRAY" && $podtree->[3]->[0] eq "Para" &&
            @{$podtree->[3]} >= 3 &&
            !(grep { ref($_) ne "" }
                @{$podtree->[3]}[2..$#{$podtree->[3]}]) &&
            (@$podtree == 4 ||
                (ref($podtree->[4]) eq "ARRAY" &&
                $podtree->[4]->[0] eq "head1"))) {
            $self->{Title} = join("", @{$podtree->[3]}[2..$#{$podtree->[3]}]);
        }
    }

    $self->{Title} //= "";
    $self->{Title} = html_escape($self->{Title});
    return $self;
}

sub refine_parser {
    my ($self, $parser) = @_;
    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $self->{Backlink} ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $tdstyle = ' style="background-color: #cccccc; color: #000"';

    if ($self->{Css}) {
        $csslink = qq(\n<link rel="stylesheet" href="$self->{Css}" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $tdstyle= '';
    }

    # header/footer block
    my $block = $self->{Header} ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$self->{Title}</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$self->{Title}</title>$csslink
<meta http-equiv="content-type" content="text/html; charset=$self->{Lencoding}" />
<link rev="made" href="mailto:$Config{perladmin}" />
</head>

<body$bodyid>
$block
HTMLHEAD

    $parser->html_footer(<<"HTMLFOOT");
$block
</body>

</html>
HTMLFOOT
    return $parser;
}

# This sub duplicates the guts of Pod::Simple::FromTree.  We could have
# used that module, except that it would have been a non-core dependency.
sub feed_tree_to_parser {
    my($self, $parser, $tree) = @_;
    if(ref($tree) eq "") {
        $parser->_handle_text($tree);
    } elsif(!($tree->[0] eq "X" && $parser->nix_X_codes)) {
        $parser->_handle_element_start($tree->[0], $tree->[1]);
        $self->feed_tree_to_parser($parser, $_) foreach @{$tree}[2..$#$tree];
        $parser->_handle_element_end($tree->[0]);
    }
}

sub write_file {
    my $self = shift;
    $self->{Htmlfile} = "-" unless $self->{Htmlfile}; # stdout
    my $fhout;
    if($self->{Htmlfile} and $self->{Htmlfile} ne '-') {
        open $fhout, ">", $self->{Htmlfile}
            or die "$0: cannot open $self->{Htmlfile} file for output: $!\n";
    } else {
        open $fhout, ">-";
    }
    binmode $fhout, ":encoding($self->{Lencoding})";
    print $fhout $self->{output};
    close $fhout or die "Failed to close $self->{Htmlfile}: $!";
    chmod 0644, $self->{Htmlfile} unless $self->{Htmlfile} eq '-';
}

sub arrange {
    my $fn = shift;
    my $base;
    my $ret;
    my $encoding;

    $base = Pod::L10N::Model::decode_file($fn);

    for (@$base){
	my($o, $t) = @$_;
	if($o =~ /^=encoding (.+)/){
	    $encoding = $1;
	    $ret .= $o . "\n\n";
	    next;
	}
	if($o =~ /^=/){
	    if(defined $t){
		$t =~ /\((.+)\)/;
		$ret .= $o . '@@@@@@@@@@' . $1;
	    } else {
		$ret .= $o;
	    }
	} else {
	    if(defined $t){
		$ret .= $t;
	    } else {
		$ret .= $o;
	    }
	}
	$ret .= "\n\n";
    }

    return ($ret, $encoding);
}

package Pod::L10N::Html::LocalPodLinks;
use strict;
use warnings;
use parent 'Pod::Simple::XHTML';

use File::Spec;
use File::Spec::Unix;

__PACKAGE__->_accessorize(
 'htmldir',
 'htmlfileurl',
 'htmlroot',
 'pages', # Page name => relative/path/to/page from root POD dir
 'quiet',
 'verbose',
);

sub idify {
    my ($self, $t, $not_unique) = @_;
    for ($t) {
        s/<[^>]+>//g;            # Strip HTML.
        s/&[^;]+;//g;            # Strip entities.
        s/^\s+//; s/\s+$//;      # Strip white space.
        s/^([^a-zA-Z]+)$/pod$1/; # Prepend "pod" if no valid chars.
        s/^[^a-zA-Z]+//;         # First char must be a letter.
        s/[^-a-zA-Z0-9_:.]+/-/g; # All other chars must be valid.
        s/[-:.]+$//;             # Strip trailing punctuation.
    }
    return $t if $not_unique;
    my $i = '';
    $i++ while $self->{ids}{"$t$i"}++;
    return "$t$i";
}

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;

    return undef unless defined $to || defined $section;
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    } else {
        $section = '';
    }

    my $path; # path to $to according to %Pages
    unless (exists $self->pages->{$to}) {
        # Try to find a POD that ends with $to and use that.
        # e.g., given L<XHTML>, if there is no $Podpath/XHTML in %Pages,
        # look for $Podpath/*/XHTML in %Pages, with * being any path,
        # as a substitute (e.g., $Podpath/Pod/Simple/XHTML)
        my @matches;
        foreach my $modname (keys %{$self->pages}) {
            push @matches, $modname if $modname =~ /::\Q$to\E\z/;
        }

        # make it look like a path instead of a namespace
        my $modloc = File::Spec->catfile(split(/::/, $to));

        if ($#matches == -1) {
            warn "Cannot find file \"$modloc.*\" directly under podpath, " . 
                 "cannot find suitable replacement: link remains unresolved.\n"
                 if $self->verbose;
            return '';
        } elsif ($#matches == 0) {
            $path = $self->pages->{$matches[0]};
            my $matchloc = File::Spec->catfile(split(/::/, $path));
            warn "Cannot find file \"$modloc.*\" directly under podpath, but ".
                 "I did find \"$matchloc.*\", so I'll assume that is what you ".
                 "meant to link to.\n"
                 if $self->verbose;
        } else {
            # Use [-1] so newer (higher numbered) perl PODs are used
            # XXX currently, @matches isn't sorted so this is not true
            $path = $self->pages->{$matches[-1]};
            my $matchloc = File::Spec->catfile(split(/::/, $path));
            warn "Cannot find file \"$modloc.*\" directly under podpath, but ".
                 "I did find \"$matchloc.*\" (among others), so I'll use that " .
                 "to resolve the link.\n" if $self->verbose;
        }
    } else {
        $path = $self->pages->{$to};
    }

    my $url = File::Spec::Unix->catfile(Pod::L10N::Html::Util::unixify($self->htmlroot),
                                        $path);

    if ($self->htmlfileurl ne '') {
        # then $self->htmlroot eq '' (by definition of htmlfileurl) so
        # $self->htmldir needs to be prepended to link to get the absolute path
        # that will be relativized
        $url = Pod::L10N::Html::Util::relativize_url(
            File::Spec::Unix->catdir(Pod::L10N::Html::Util::unixify($self->htmldir), $url),
            $self->htmlfileurl # already unixified
        );
    }

    return $url . ".html$section";
}

sub _end_head {
    my $h = delete $_[0]{in_head};

    my $add = $_[0]->html_h_level;
    $add = 1 unless defined $add;
    $h += $add - 1;

    my ($orig, $trans) = split /@@@@@@@@@@/, $_[0]{scratch};
    if(!defined $trans){
	$trans = $orig;
    }
    my $id = $_[0]->idify($orig);
    my $text = $trans;
    $_[0]{'scratch'} = $_[0]->backlink && ($h - $add == 0) 
                         # backlinks enabled && =head1
                         ? qq{<a href="#_podtop_"><h$h id="$id">$text</h$h></a>}
                         : qq{<h$h id="$id">$text</h$h>};
    $_[0]->emit;
    push @{ $_[0]{'to_index'} }, [$h, $id, $text];
}

sub end_item_text   {
    my ($orig, $trans) = split /@@@@@@@@@@/, $_[0]{scratch};
    if(!defined $trans){
	$trans = $orig;
    }

    # idify and anchor =item content if wanted
    my $dt_id = $_[0]{'anchor_items'} 
                 ? ' id="'. $_[0]->idify($orig) .'"'
                 : '';

    # reset scratch
    my $text = $trans;
    $_[0]{'scratch'} = '';

    if ($_[0]{'in_dd'}[ $_[0]{'dl_level'} ]) {
        $_[0]{'scratch'} = "</dd>\n";
        $_[0]{'in_dd'}[ $_[0]{'dl_level'} ] = 0;
    }

    $_[0]{'scratch'} .= qq{<dt$dt_id>$text</dt>\n<dd>};
    $_[0]{'in_dd'}[ $_[0]{'dl_level'} ] = 1;
    $_[0]->emit;
}

1;
