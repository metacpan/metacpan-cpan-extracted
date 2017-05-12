#! /usr/bin/perl

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
    if 0;    # not running under some shell

use 5.0008;
use strict;
use warnings;
use version;

use Carp;
use Config;
use English qw( -no_match_vars );
use File::Basename;
use File::Find;
use File::Path;
use File::Slurp;
use File::Spec;
use File::Spec::Unix;
use GDBM_File;
use Getopt::Auto 1.9.2;    # Versions less than this not a good idea
use HTML::EasyTags;
use IO::File;
use IO::Handle;
use List::MoreUtils qw{any};
use Pod::HtmlEasy 1.1.11;
use Pod::Usage;
use Readonly;
use Regexp::Common qw{ whitespace };
use Storable qw( store retrieve );
use Uniq;

our $VERSION = '1.0';    # Also appears in "=head1 VERSION" in the POD below

# Static configuration
Readonly my $DEBUG     => 0;
Readonly my $DOT       => q{.};
Readonly my $EMPTY     => q{};
Readonly my $NL        => qq{\n};
Readonly my $NUL       => qq{\0};
Readonly my $FONTSIZE  => 5;
Readonly my @SUFFIXES  => qw{ \.pm \.pod \.pl };
Readonly my $TITLE     => q{Perl Documentation};
Readonly my $USER      => q{root\@localhost};
Readonly my $CSS_ADDON => qq(dt { margin-top: 1em; });

# Variables that may be set from the command line
my $scratch;
my $verbose;
my $outfile;

# Longest first, otherwise alpha
my @prefixes
    = reverse uniq sort { length $a <=> length $b or $a cmp $b } @INC;
if ( $prefixes[-1] eq $DOT ) { pop @prefixes; }

# Here we try to accommodate multiple paths, such as /usr/lib/perl5/5.10.0 and
# /usr/local/lib/perl5/site_perl/5.10.0
my @sources;
foreach (@prefixes) {
    if ( -d $_ ) { push @sources, $_; }
}

my $targetdir = q{/usr/local/doc/HTML/Perl};
my @addpods   = qw{/usr/local/doc/POD};        # Adds on to @INC

if ($DEBUG) {

    # To debug in a smaller environment, use these.
    # Note that if you should use something like
    #    /usr/lib/perl5/vendor_perl/5.8.8/Regexp
    # in order to get a small-sample "live" test, the links will be
    # CPAN searches as the last directory will be lost, resulting in
    # failure of the inverted hash lookup in on_L().
    $targetdir = qq{$ENV{HOME}/Perl/pod2_test_output};
    @addpods   = ();
    @sources   = (qq{$ENV{HOME}/Perl/pod2_test_input});
}

# Make a compiled regex.
Readonly my $PREFIXER => q{\A} . join( q{/|\A}, @prefixes, @addpods ) . q{/};
Readonly my $PREFIXRE => qr{$PREFIXER}msx;

# Persistant hashes that track the state of PODs converted to HTML.
# %html_track:
#   key:   path to original (.pod, .pm or .pl) file
#   value: [ path to the .html file, last mod time of POD ]
# %nopod_track:
#   key:   path to original .pm  or .pl file
#   value: the last-modified time of the .pm  or .pl file
#          that was found to have no POD.
# %index_track:
#   key:   tag for the index (Foo::Bar)
#   value: ARRAY of [ path to the .html file, last mod time of POD ]
# See insert_latest() for a specific example.
my ( %HTML_TRACK,     %nopod_track,     %index_track );
my ( $html_track_ref, $nopod_track_ref, $index_track_ref )
    = ( \%HTML_TRACK, \%nopod_track, \%index_track );

# %pod_convert:
#   key:   path to the POD file to convert
#   value: path to the HTML file that will receive the conversion
my %pod_convert;

# Files accessed in the course of index generation

# Index tracking and nopod tracking files
Readonly my $HTML_TRACK  => qq{$targetdir/.html_track};
Readonly my $INDEX_TRACK => qq{$targetdir/.index_track};
Readonly my $NOPOD_TRACK => qq{$targetdir/.nopod_track};

# Default URL for referenced uninstalled PODs
Readonly my $CPAN => q{search.cpan.org};

# HTML index for converted PODs
Readonly my $INDEX_FILE => qq{$targetdir/index.html};

# Stylesheet for generated HTML
Readonly my $CSS_FILE => qq{$targetdir/.doc.css};

sub TRUE  { return 1 }
sub FALSE { return 0 }

sub if_verbose {
    if ( defined $verbose ) { print shift or carp q{print fail}; }
    return;
}

sub error_print {
    print shift, $NL or carp q{print fail};
    exit 1;
}

sub dumpdb {    ## no critic (ProhibitExcessComplexity)

    if ( defined $scratch ) {
        error_print(q{Can't combine -scratch and -dump!})
            or carp q{print fail};
    }

    print qq{$HTML_TRACK$NL} or carp q{print fail};
    for ( sort keys %{$html_track_ref} ) {
        print qq{  $_ =>$NL    $html_track_ref->{$_}->[0]$NL    },
            scalar localtime $html_track_ref->{$_}->[1], $NL
            or carp q{print fail};
    }

    my @index_refs;
    print qq{$NL$INDEX_TRACK$NL} or carp q{print fail};
    for ( sort keys %{$index_track_ref} ) {
        print qq{  $_ =>$NL} or carp q{print fail};
        if ( int @{ $index_track_ref->{$_} } > 1 ) {
            push @index_refs, $_;
        }
        foreach my $ary_ref ( @{ $index_track_ref->{$_} } ) {
            print qq{    $ary_ref->[0]$NL    },
                scalar localtime $ary_ref->[1], $NL
                or carp q{print fail};
        }
    }

    print qq{$NL$NL$NOPOD_TRACK$NL} or carp q{print fail};
    for ( sort keys %{$nopod_track_ref} ) {
        print qq{  $_ =>$NL    }, scalar localtime $nopod_track_ref->{$_}, $NL
            or carp q{print fail};
    }

    if (@index_refs) {
        print qq{${NL}Multiple index references$NL} or carp q{print fail};
        foreach (@index_refs) {
            print qq{  $_ =>$NL} or carp q{print fail};
            foreach my $ary_ref ( @{ $index_track_ref->{$_} } ) {
                print qq{    $ary_ref->[0]$NL    },
                    scalar localtime $ary_ref->[1], $NL
                    or carp q{print fail};
            }
        }
    }
    return;
}

# Get the last modified time of the file arg.
Readonly my $MTIME => 9;

sub mtime {
    return ( stat shift )[$MTIME];
}

# Execute the Storable module's retrieve() to load the persistent hashes.
sub do_retrieve {
    if ( defined $scratch ) {    # Hashes are not loaded.
        return;
    }
    if ( !-e $HTML_TRACK ) {     # Hash files are not found.
        return;
    }

    if_verbose(qq{Retrieving $HTML_TRACK$NL});
    $html_track_ref = retrieve($HTML_TRACK)
        or error_print(qq{Unable to retrieve $HTML_TRACK - $ERRNO});

    if_verbose(qq{Retrieving $INDEX_TRACK$NL});
    $index_track_ref = retrieve($INDEX_TRACK)
        or error_print(qq{Unable to retrieve $INDEX_TRACK - $ERRNO});

    if_verbose(qq{Retrieving $NOPOD_TRACK$NL$NL});
    $nopod_track_ref = retrieve($NOPOD_TRACK)
        or error_print(qq{Unable to retrieve $NOPOD_TRACK - $ERRNO});
    return;
}

# Execute the Storable module's store() to save the persistent hashes.
sub do_store {
    store( $html_track_ref,  $HTML_TRACK );
    store( $index_track_ref, $INDEX_TRACK );
    store( $nopod_track_ref, $NOPOD_TRACK );
    return;
}

# Build HTML for the header/trailer that goes at the top and bottom of
# generated HTML pages.
sub build_header {
    my ( $name, $alt ) = @_;
    if ( not defined $name ) { $name = $alt; }
    my $header = <<"_HEAD_";
<div class=hf>
&nbsp;$name</head>
</div>
_HEAD_
    return $header;
}

# Maintain the array of index targets with the latest date as element [0].
# If you wish to maintain the array sorted by date, use this:
#  return [ sort { $b->[1] <=> $a->[1] } @$arrayref, $htmlfile ]
# Here's a sample of the hash.  Note the nested ARRAYs.
# HASH(0x930e668)
#  'Item_error_Pod_Readme' => ARRAY(0x930f3ac)
#     0  ARRAY(0x930f3c4)
#        0  '/home/geoff/Perl/pod2_test_output/Item_error_Pod_Readme.html'
#        1  1151020294
#     1  ARRAY(0x930f3f4)
#        0  '/home/geoff/Perl/pod2_test_output2/Item_error_Pod_Readme.html'
#        1  1150299856
#  'OLEwriter' => ARRAY(0x930f424)
#     0  ARRAY(0x930f43c)
#        0  '/home/geoff/Perl/pod2_test_output/OLEwriter.html'
#        1  1150299856

sub insert_latest {
    my ( $arrayref, $htmlfile ) = @_;
    if ( not defined $arrayref ) {

        # First time for this htmlfile
        return [$htmlfile];
    }

    # Multiple links for a particular tag.
    # The $htmlfile (ref to ARRAY) goes at the head of the list if
    # its date is later than the one currently there, and at the
    # back of the list otherwise.  We're interested only in the head
    # of the list for link generation when this tag is referenced.
    $arrayref->[0][1] > $htmlfile->[1]
        ? push @{$arrayref}, $htmlfile
        : unshift @{$arrayref}, $htmlfile;
    return $arrayref;
}

# Subroutines which replace the subs internal to pod2html
# and associated global variables.

# $html_file:
#   the file currently being generated, and is used for
#   links within the page.
my $html_file;

sub on_l {    ## no critic (ProhibitManyArgs)
    my ( $this, $text, $inferred, $name, $section, $type ) = @_;

    if ( $type eq q{pod} ) {

        if ( not defined $name ) { $name = $EMPTY; }

        if ( defined $section ) {

            # If an name was stated, reference it
            if ( length $name ) {
                my $tail = qq{#$section'>$inferred</a></i>};
                return
                    exists $index_track_ref->{$name}
                    ? qq{<i><a href='f${NUL}ile://$index_track_ref->{$name}[0][0]$tail}
                    : qq{<i><a href='h${NUL}ttp://$CPAN/perldoc?$name$tail};
            }

            # Otherwise, assume we have an internal reference
            # HtmlEasy squeezes unfriendly stuff out of tags with toc_tag
            $section = Pod::HtmlEasy::Data::toc_tag($section);
            return qq{<i><a href='#$section'>$inferred</a></i>};
        }

        # $name is expected to contain Foo::Bar.
        # Returning a link to an HTML file in the conversion directory
        my $link = $index_track_ref->{$name};
        return
            defined $link
            ? qq{<i><a href='f${NUL}ile://$link->[0][0]'>$inferred</a></i>}
            :

            # Returning a search command that will (hopefully) locate POD for
            # a module that is not installed
            qq{<i><a href='h${NUL}ttp://$CPAN/perldoc?$name'>$inferred</a></i>};
    }

    # OK, not a POD.  Try something else
    if ( $type eq q{man} ) {

 # $name probably looks like "foo(1)", and the () are interpreted as metachars
        if ( $inferred !~ m{\Q$name\E}sxm ) { $inferred .= qq{ in $name}; }
        return qq{<i>$inferred</i>};
    }

    if ( $type eq q{url} ) {

        # Leave it to _add_uri_href
        return $name;
    }

    print qq{Pod::HtmlEasy asked to process link $name type $type, },
        q{but that's not supported.}
        or carp q{bad link};

    return $EMPTY;
}

my $podhtml = Pod::HtmlEasy->new( on_l => \&on_l, );

# This a "wanted" sub for File::Find.
# It accepts files with extension .pod or with extension .pm or .pl and
# which have a line that begins with "=\w+" and saves them in the
# HTML_TRACK hash. If they've been modified since last conversion,
# or never converted, the file is stuffed into the pod_convert hash.
# If a POD file is removed, it's entry will linger in the persistent files.

sub list_pods {

    my $podfile = $File::Find::name;
    my ( $name, $path, $suffix ) = fileparse( $podfile, @SUFFIXES );

    if ( length $suffix == 0 ) {
        return;
    }

    if_verbose(qq{$podfile$NL});

    # Source podfile is assumed to exist. Otherwise, how did we get here?
    # $podmtime is the last-modified time of the .pm or .pod we're
    # considering.
    my $podmtime = mtime($podfile);

    # Check if there is anything to do.
    my $ftime = $nopod_track_ref->{$podfile};
    if ( defined $ftime and ( $ftime >= $podmtime ) ) {

        # The podfile was previously examined and had no POD and
        # it has't been modified since.
        if_verbose(qq{  in .nopod_track$NL});
        return;
    }

    # Now let's see if the podfile was previously converted and
    # whether its been modified since then.
    my $track = $html_track_ref->{$podfile};
    if ( defined $track ) {

        # We've converted this POD before.
        my ( $this_htmlfile, $this_ftime ) = @{$track};
        if ( -e $this_htmlfile and ( $this_ftime >= $podmtime ) ) {

            # The podfile was previously converted and it hasn't
            # been modified since, and the HTML version is still around.
            if_verbose(qq{  already converted $NL});
            return;
        }
    }

    # .pod files should have POD; with .pm or .pl its problematic.
    # So, check the .pm or .pl file to see if there are any lines
    # beginning with "="
    if ( $suffix ne q{.pod} ) {

        # Get the source and check
        # This is not foolproof.  But its cheap.
        if ( not any {m{^=\w+}msx} ( read_file($podfile) ) ) {
            if_verbose(qq{  no POD$NL});
            $nopod_track_ref->{$podfile} = $podmtime;
            return;
        }
    }

    # We have a POD to convert. The time is last-modified of POD.
    # %HTML_TRACK has the state of the index database.
    # %pod_convert has the PODs that are to be converted this run.

    my $newpath;

    # @sources is sorted longest first, so we strip as much as possible.
    # There's a possibility of multiple sources mapping to a single target.
    foreach my $sourcedir (@sources) {
        if ( $path =~ m{\A$sourcedir}msx ) {
            $newpath = $path;
            $newpath =~ s{\A$sourcedir}{$targetdir}msx;
            last;
        }
    }

    if ( not defined $newpath ) {
        error_print(qq{Unable to strip prefix from $podfile});
    }

    # Construct a path for the HTML file.
    my $htmlfile = qq{$newpath$name.html};
    $html_track_ref->{$podfile} = [ $htmlfile, $podmtime ];
    $pod_convert{$htmlfile} = $podfile;
    if_verbose(qq{  to be converted$NL});
    return;
}

# Convert a POD file to HTML

sub convert_pod {
    my ( $local_file, $from_pod_file, $to_html_file ) = @_;

    # Make an HTML file from the POD
    if ( defined $to_html_file ) {

        # $html_file is global as its needed by on_l()
        $html_file = $to_html_file;
        my ( $name, $path ) = fileparse($html_file);
        if ( !-d $path ) { mkpath($path); }

        print qq{$from_pod_file =>$NL  $html_file$NL} or carp q{podrint};
    }

    my $pod_name = $from_pod_file;
    my @pod2args = $from_pod_file;
    if ( $from_pod_file eq q{-} ) {
        $pod_name = defined $to_html_file ? $to_html_file : q{STDOUT};
        push @pod2args, $pod_name;
    }
    push @pod2args, css => $local_file ? undef : $CSS_FILE;
    push @pod2args, index_item => 1;
    push @pod2args, top        => 'uArr';

    my @html = $podhtml->pod2html(@pod2args);

    my $heading = build_header( $podhtml->pm_name, $pod_name );

    # Build header and footer for the page

    # This should be near the top of the page
    foreach my $html_line (@html) {
        $html_line =~ m{<body}msx and do {
            $html_line .= $heading;
            last;
        };
    }

    # And this should be near the end of the list.
    foreach my $html_line ( reverse @html ) {
        $html_line =~ m{</body}msx and do {
            $html_line .= $heading;
            last;
        };
    }

    # The file has alread been written by pod2html, but that's OK
    if ( defined $html_file ) { write_file( $html_file, \@html ); }

    return;
}

sub convert_local {
    $verbose = 1;
    foreach my $pod_file (@ARGV) {
        if ( $pod_file eq q{-} ) {
            convert_pod( TRUE, $pod_file, $outfile );
            return;
        }

        if ( !-e $pod_file ) {
            print qq{No file $pod_file$NL} or carp q{No file};
            next;
        }

        my ( $name, $path, $suffix ) = fileparse( $pod_file, @SUFFIXES );
        $outfile = qq{$name.html};

        convert_pod( TRUE, $pod_file, $outfile );
    }
    return;
}

# Globals to manage the generation of HTML.
# Assigned in build_index
my ( $index_fh, $html );

# Assumed to be called with the tags array sorted and with all of the
# entries having the same value in the first position.
sub definition {
    my $tags_ref = shift;

 # If there's only one item here, we'll skip the <dd> and put the link in <dt>
    if ( @{$tags_ref} == 1 ) {
        my $tag = shift @{$tags_ref};
        my ( $name, $index ) = @{$tag};
        my $link = $index_track_ref->{$index}[0][0];
        $index_fh->print(
            $html->dt_start,
            $html->a(
                href => $link,
                text => $name
            ),
        );
        $index_fh->print( $html->dt_end );
        return;
    }

    # The first thing we need to do is to define the 0-level
    my $tag = $tags_ref->[0];
    my ($section) = $tag->[0][0] =~ m{^(\w+)}sxm;
    if ( $section =~ m{^perl}msx ) { $section =~ q{perl}; }
    $index_fh->print( $html->dt($section) );

    $index_fh->print( $html->dd_start );
    while ( my $this_tag = shift @{$tags_ref} ) {
        my $index = $this_tag->[1];

        # Two-step calc preserves single names (no '::")
        my $name = $index;
        $name =~ s{${section}::}{}sxm;
        my $link = $index_track_ref->{$index}[0][0];
        $index_fh->print(
            $html->a(
                href => $link,
                text => $name
            ),
            '&nbsp;&nbsp;'
        );
    }
    $index_fh->print( $html->dd_end );
    return;
}

# Finds all tags that have the same first element as the first tag on
# the tags list, deleting them from that list. Returns an array ref,
# with elements that look like this: [[first, second, rest], tag]
Readonly my $NTAG => 3;

sub get_first {
    my $tags_ref = shift;
    my ($first) = ${$tags_ref}[0] =~ m{^(\w+)}sxm;
    my @first_tags;

  # The purpose of $first_re is to cause the Perl pages (perlops, perlre, etc.
  # to sort together
    my $first_re;
    if   ( $first =~ m{\Aperl}sxm ) { $first_re = qr{\Aperl}sxm; }
    else                            { $first_re = qr{\A$first\z}sxm; }
    while ( my $tag = shift @{$tags_ref} ) {
        my ($tagprefix) = $tag =~ m{^(\w+)}sxm;
        if ( $tagprefix !~ m{$first_re}sxm ) {
            unshift @{$tags_ref}, $tag;
            return \@first_tags;
        }
        push @first_tags, [ [ split /::/sxm, $tag, $NTAG ], $tag ];
    }
    return \@first_tags;
}

sub key_sort {
    if ( uc( substr $a, 0, 1 ) ne uc( substr $b, 0, 1 ) ) {
        return uc $a cmp uc $b;
    }
    return $a cmp $b;
}

# The index is re-generated without regard to whether
# the HTML files were changed.
sub build_index {

    $index_fh = IO::File->new( $INDEX_FILE, '>' )
        or error_print(qq{Can't open $INDEX_FILE: $ERRNO});
    $html = HTML::EasyTags->new();
    $html->groups_by_default(1);

    # Do the HTML document header
    $index_fh->print(
        $html->start_html(
            $TITLE,
            [   $html->link(
                    rel  => q{stylesheet},
                    href => $CSS_FILE,
                    type => q{text/css}
                ),
                $html->link(
                    rev  => q{made},
                    href => qq{mailto:$USER}
                ),
            ],
        ),
        $html->font_start( size => $FONTSIZE ),
        $html->strong( $html->center($TITLE) ),
        $html->font_end,
        $html->hr,    # Horizontal rule
        $html->p,
        $html->dl_start,
    );

    # Get set up to dump %index_track as links to the docs
    my @tags = sort key_sort keys %{$index_track_ref};
    while ( not length $tags[0] ) { shift @tags; }
    while (@tags) {
        my $tags = get_first( \@tags );
        if ( defined $tags ) { definition($tags); }
    }

    $index_fh->print( $html->dl_end, $html->end_html );
    $index_fh->close();
    return;
}

# Here's where it all begins

# Persistant hashes not updated.
local $SIG{INT} = sub { exit 1; };

# Print it now!
*STDOUT->autoflush();

sub outfile {
    $outfile = shift @ARGV;
    return;
}

sub help {
    pod2usage( -verbose => 2 );
    exit 0;
}

# This is set (magically) by Getopt::Auto
our %options;    ## no critic (ProhibitPackageVars)

if ( exists $options{'--scratch'} ) {
    $scratch = 1;
}

if ( exists $options{'--verbose'} ) {
    $verbose = 1;
}

do_retrieve();

if ( exists $options{'dumpdb'} ) { dumpdb(); exit 0; }

if (@ARGV) { convert_local(); exit 0; }

# Put CSS_ADDON at the end of the css
# 'x' is inappropriate here
my @css = split m{$NL}sxm, Pod::HtmlEasy::Data::css;
push @css, splice @css, -1, 1, $CSS_ADDON; ## no critic (ProhibitMagicNumbers)
write_file( $CSS_FILE, join( qq{$NL}, @css ) . $NL );

if ( not -d $targetdir ) {
    mkdir $targetdir
        or error_print(qq{Unable to create $targetdir})
        or carp q{print fail};
}
if ( not -w $targetdir ) {
    error_print(qq{Unable to write $targetdir}) or carp q{print fail};
}

# Generate a hash (in %pod_convert) of qualifying .pm, .pl and .pod files
# and keep up-to-date the hash of the HTML file state (%HTML_TRACK)

if_verbose(qq{Indexing .pm, .pl and .pod$NL$NL});
find( \&list_pods, @sources );

# Update the %index_track hash taking into account that there may be more
# than one path that maps to a particular name. This is used to find
# the HTML for linking.

if_verbose(qq{${NL}Processing HTML paths$NL$NL});
foreach my $podfile ( values %pod_convert ) {

    # Extract the name of the POD
    my $htmlfile = $html_track_ref->{$podfile};

    # "." marks the beginning of the suffix
    my ($tag) = $podfile =~ m{$PREFIXRE(.*)\.}msx;

    if ( not defined $tag ) {

        # Match didn't work.  Try Plan B.
        my ( $hf, $ht ) = @{$htmlfile};
        print qq{Tag match failure for$NL  $hf$NL}
            or carp q{tag match failed}
            or carp q{print fail};
        my ( $name, $path, $suffix ) = fileparse( $hf, '\.html' );
        $tag = $name;
    }

    # PODs in the pod/ directory of the standard distribution are referred
    # to without the pod:: prefix, so let's just dump it.
    $tag =~ s{^pod/}{}msx;

    # Convert the POD path (Foo/Bar) to a POD name (Foo::Bar)
    $tag =~ s{/}{::}msxg;

    if_verbose(qq{$podfile =>$NL  $htmlfile->[0]$NL});

    # Insert the new reference into the %index_track entry.
    $index_track_ref->{$tag}
        = insert_latest( $index_track_ref->{$tag}, $htmlfile );
}

if_verbose(qq{${NL}Generating HTML$NL$NL});
foreach my $html_file ( keys %pod_convert ) {
    convert_pod( FALSE, $pod_convert{$html_file}, $html_file );
}

# Make an index of the HTML files
build_index();

# Save data
do_store();

exit 0;

__END__

=pod

=begin stopwords
outfile
html
STDIN
manpage
=end stopwords

=head1 NAME 

pod2indexed_html - Convert POD files to HTML and create an index page

=head1 VERSION

This documentation refers to pod2indexed_html version 1.0

=head1 SYNOPSIS

pod2indexed_html [--dump] [--help] [--outfile file] [--scratch] [--verbose] [POD file ...]

In much the same way as pod2html, 
pod2indexed_html converts POD (.pm, .pl or .pod) files to HTML.
However, pod2indexed_html also indexes them. That is, a page of links is created
to allow the individual pages to be accessed easily.
The state of the HTML with respect to the POD is tracked, and re-conversion
is avoided if unnecessary.
    
If path(s) are specified on the command line, indexing is skipped,
and conversion takes place directly.  /foo/bar/test.pm => ./test.pm.html

The POD file may be specified as "-", in which case input is taken from STDIN.

=head1 REQUIRED ARGUMENTS

There are none. However, consult the "Static configuration" section at the beginning
of the script to make sure that you like the choices.

=head1 OPTIONS

=over 4

=item --dump     - Dump F<.html_track>, F<.index_track> and F<.nopod_track>, then exit.

This also provides a list of all links having the same tag.

=item --help     - Print this and exit.

=item --outfile  - File name to use when converting from STDIN. Defaults to STDIN.html.

=item --scratch  - Rebuild the persistent files, which re-creates all HTML.

=item --verbose  - Babble.

=back

=head1 READ ME

See DESCRIPTION.

=head1 DESCRIPTION

pod2indexed_html locates all the Perl modules in your distribution that have 
documentation in POD format, converts it to 
HTML and makes an index page. Links are rendered so as to refer 
to the appropriate pages.

The principal advantage of pod2indexed_html is that it uses a persistent
database of module creation times
so that once its been run for the first time, subsequent
executions are relatively quick, depending of course
on what has been changed.
pod2indexed_html notices both new modules and updates.
This indexing is performed for all converted files; in particular,
those specified on the command line.

The generated HTML index is flat, organized to look like a module hierarchy.
For example,
F</some/path/DBI/Const/GetInfo/ANSI.pm> goes to
F</another/path/DBI/Cons/GetInfo/ANSI.html>,
and is indexed under F<Const::GetInfo::Ansi>.

HTML display is controlled by a style sheet, F<.doc.css>
in the document root directory, or, if you're converting documents on the
command line, embedded in the generated HTML file.


=head1 ENVIRONMENT

$ENV{HOME} is used in debug mode.

=head1 DEPENDENCIES

This script requires the following modules:
L<Carp>,
L<Config>,
L<English>,
L<File::Basename>,
L<File::Find>,
L<File::Path>,
L<File::Slurp>,
L<File::Spec>,
L<File::Spec::Unix>,
L<GDBM_File>,
L<Getopt::Auto>,
L<HTML::EasyTags>,
L<IO::File>,
L<IO::Handle>,
L<MIME::Base64>,
L<Pod::HtmlEasy>,
L<Readonly>,
L<Regexp::Common>,
L<Storable>

It also requires Perl 5.8.0, but should run under earlier version with only
minor modifications.  Required modules willing, of course.

=head1 CONFIGURATION AND ENVIRONMENT

The persistent USER environment, configured in the script.

=over

=item @addpods

Defaults to F</usr/local/doc/POD>.
This is a list of paths to search for POD files, in addition to @INC.

=item $CPAN

Defaults to "search.cpan.org". This is the URL to be used to search for
modules that are mentioned in a POD, but have not been installed locally.

=item $sourcedir

Defaults to the shortest path in @INC.  Usually, that's
F</usr/lib/perl5>
If there are multiple roots, we attempt to accommodate that.

=item $targetdir

Defaults to F</usr/local/doc/HTML/Perl>

=item $USER

Email address for the creator of the index page. Defaults to "root@localhost".

=item $TITLE

Defaults to "Perl Documentation"

=back

=head1 DIAGNOSTICS

=over 4

=item C<--verbose> 

This will produce all sorts of (allegedly) helpful info. 

=item Tag references more than one POD.

Sometimes, one index entry will map to more than one HTML file.
For example, both
F</usr/local/doc/HTML/Perl/vendor_perl/5.8.8/IPC/Run/Timer.html>
and
F</usr/local/doc/HTML/Perl/site_perl/5.8.8/IPC/Run/Timer.html>
would be pointed to by
F<IPC::Run::Timer>.
Obviously, this is not going to work very well. The situation is resolved by
choosing the most recently modified POD file. To see what's going on, run with
-dump and look for the section TITLEd "Multiple index references" at the end.

=item Unable to open F<file> - I<error>

Failure to open (or create) the database files.

=item Tag match failure for F<some/path>

Failure of the regular expression matching that strips @INC paths.

=item Can't combine --dump and --scratch.

Don't combine C<--dumpb> and C<--scratch>, as this will delete the database
before dumping it.

=item Pod::HtmlEasy asked to process link of type I<type>, but that's not supported.

HTML conversion has missed a particular link type.
Supported types are: URL, manpage, URI.

=back

=head1 FILES

Assuming the you are using the default target directory.

=over 4

=item F</usr/local/doc/HTML/Perl/.html_track>

Tracks the HTML file by the corresponding POD (.pm or .pod) file.

 /usr/local/doc/HTML/Perl/.html_track
  /usr/lib/perl5/5.8.8/AnyDBM_File.pm =>
    /usr/local/doc/HTML/Perl/5.8.8/AnyDBM_File.html
    Sun Jun  4 16:45:28 2006
  /usr/lib/perl5/5.8.8/Attribute/Handlers.pm =>
    /usr/local/doc/HTML/Perl/5.8.8/Attribute/Handlers.html
    Sun Jun  4 16:45:28 2006
  /usr/lib/perl5/5.8.8/AutoLoader.pm =>
    /usr/local/doc/HTML/Perl/5.8.8/AutoLoader.html
    Sun Jun  4 16:45:28 2006
...

=item F</usr/local/doc/HTML/Perl/.index_track>

Tracks the HTML index entry by the file tag and HTML file.

 /usr/local/doc/HTML/Perl/.index_track
  APR =>
    /usr/local/doc/HTML/Perl/vendor_perl/5.8.8/i386-linux-thread-multi/APR.html
    Sat Feb 11 23:29:50 2006
  APR::Base64 =>
    /usr/local/doc/HTML/Perl/vendor_perl/5.8.8/i386-linux-thread-multi/APR/Base64.html
    Sat Feb 11 23:29:57 2006
  APR::Brigade =>
    /usr/local/doc/HTML/Perl/vendor_perl/5.8.8/i386-linux-thread-multi/APR/Brigade.html
    Sat Feb 11 23:29:34 2006
...

There are some entries that point to multiple HTML files 
(found at the end out the output), for example:

  Archive::Extract =>
    /usr/local/doc/HTML/Perl/vendor_perl/5.8.8/Archive/Extract.html
    Thu Jan 19 04:53:02 2006
    /usr/local/doc/HTML/Perl/site_perl/5.8.8/Archive/Extract.html
    Thu Jan 19 04:53:02 2006
...

=item F</usr/local/doc/HTML/Perl/.nopod_track>

Tracks those .pm files that were not found to have POD.

 /usr/local/doc/HTML/Perl/.nopod_track
  /usr/lib/perl5/5.8.8/CGI/eg/make_links.pl =>
    Sun Jun  4 16:45:28 2006
  /usr/lib/perl5/5.8.8/CPAN/Config.pm =>
    Mon Jun 19 17:02:39 2006
...

=item F</usr/local/doc/HTML/Perl/.doc.css>

The style sheet that's generated to go with the HTML.
The source for this file is found in the script,
at the end of the file.

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 EXIT STATUS

0 on success, 1 on failure.

=head1 AUTHOR

Geoffrey Leach <geoff@hughes.net>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 - 2010 by Geoffrey Leach

This script is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SCRIPT CATEGORIES

CPAN/Administrative

=cut

