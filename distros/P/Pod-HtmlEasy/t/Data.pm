#
#===============================================================================
#
#         FILE:  Data.pm
#
#  DESCRIPTION:  Data definitions
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  --- The intent of this module is to localize some of the HTML
#                    generation so as to make it accessible to the test suite.
#                    This version of Data.pm provides the same data for testing.
#                    The result of running t/data.t should be to report that this
#                    file and Pod::HtmlEasy::Data.pm deliver the same data.
#                    The two modules should, of course, have the same version
#       AUTHOR:  Geoffrey Leach, <geoff@hughes.net>
#      VERSION:  1.1.11
#      CREATED:  10/17/07 15:14:33 LPDT
#     REVISION:  Wed Jan 20 05:23:16 PST 2010
#    COPYRIGHT:  (c) 2008-2010 Geoffrey Leach
#
#===============================================================================

package Data;
use 5.006002;

use strict;
use warnings;
use English qw{ -no_match_vars };

use Exporter::Easy (
    OK => [
        qw( EMPTY NL body css gen head headend title toc top podon podoff toc_tag )
    ],
);

sub EMPTY { return q{}; }
sub NL    { return $INPUT_RECORD_SEPARATOR; }
sub NUL   { return qq{\0}; }
sub SPACE { return q{ }; }
sub TRUE  { return 1; }
sub FALSE { return 0; }

sub head {
    return q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">},
        q{<html><head>},
        q{<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">};
}

sub headend { return q{</head>}; }

sub gen {
    my ( $ver, $pver ) = @_;
    my $g
        = q{<meta name="generator" content="Pod::HtmlEasy/VER Pod::Parser/PVER }
        . qq{Perl/$] [$^O]">};
    $g =~ s{VER}{$ver}mx;
    $g =~ s{PVER}{$pver}mx;
    return $g;
}

sub podon { return q{<div class='pod'>}; }

sub podoff {
    my $no_body = shift;
    return defined $no_body ? q{</div>} : q{</div></body></html>};
}

sub title {
    my $title = shift;
    return q{<title>}, $title, q{</title>};
}

sub toc {
    my @index = @_;
    my @toc = ( q{<div class="toc">}, q{<ul>}, q{</ul>}, q{</div>} );
    ## no critic (ProhibitMagicNumbers)
    return @index ? ( @toc[ 0 .. 1 ], @index, @toc[ 2 .. 3 ] ) : @toc;
    ## no critic
}

# Create the toc tag.
# First we remove <' to '>'. These are HTML encodings (<i> ... </i>, for example)
# that have been introduced processing directives (I<...>, for example)
# Spaces are squeezed to one to eliminate problems created by embedded tabs.
# Single space remains to avoid having foo @bar become foo@bar
# HTTP prefix removed to avoid getting tag post-processed as an URL.

sub toc_tag {
    my $txt = shift;
    $txt =~ s{<.+?>}{}mxg;
    $txt =~ s{\s+}{ }mxg;
    $txt =~ s{https?://}{}mxg;
    return $txt;
}

sub top { return q{<a name='_top'></a>}; }

sub body {
    my $body_spec = shift;
    my %body      = (
        alink   => '#FF0000',
        bgcolor => '#FFFFFF',
        link    => '#000000',
        text    => '#000000',
        vlink   => '#000066',
    );
    my $body = q{<body };    # Prototype for return

    # First case - provide the default body addtributes
    if ( not defined $body_spec ) {
        foreach my $key ( sort keys %body ) {
            $body .= qq{ $key="$body{$key}"};
        }
        return $body . q{>};
    }

# Second case - we're given a new, complete (by definition), set of body attributes
    if ( ref $body_spec ne q{HASH} ) { return qq{<body $body_spec>}; }

    # Third case - we have a hash to update the body attributes
    my %new_body = %body;

    # Make sure that the user-defined keys are formatted correctly
    foreach my $key ( keys %{$body_spec} ) {
        my $value = $body_spec->{$key};
        $value =~ s{['"#]}{}smxg;
        $new_body{$key} = qq{#$value};
    }

    # Convert the hash to a string of HTML stuff, maintaining alpha sort
    foreach my $key ( sort keys %new_body ) {
        $body .= qq{ $key="$new_body{$key}"};
    }

    return $body . q{>};
}

sub css {
    my $data = shift;

    my $css = << "END_CSS";
/* Properties that apply to the entire HTML file produced */
BODY {
    background: white;
    color: black;
    font-family: arial,sans-serif;
    margin: 0;
    padding: 1ex;
}
/* The links; no change once visited */
A:link, A:visited {
    background: transparent;
    color: #006699;
}
/* Applies to <div> contents; that's most everything
DIV {
    border-width: 0;
}
/* <pre> is used for verbatum POD */
.pod PRE     {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    padding: 1em;
    white-space: pre;
}
/* This is the style of the header/footer of the POD pages */
.HF     {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    margin: 1ex 0;
    padding: 0.5ex 1ex;
}
/* <h1> result from processing =head1, and are generated only in class="pod" */
.pod H1      {
    background: transparent;
    color: #006699;
    font-size: large;
}
/* Ditto <h1> */
.pod H2, H3, H4      {
    background: transparent;
    color: #006699;
    font-size: medium;
}
/* Applies to all <a ... generated */
.pod .toc A  {
    text-decoration: none;
}
/* <li> items in the class="toc"; the table of contents, aka "index" */
/* <li> in class="pod" -- the actual POD -- default to browser defaults */
.toc li {
    line-height: 1.2em;
    list-style-type: none;
}

END_CSS

    my $NL = NL;

    # "x" modifier inappropriate here
    ## no critic (RequireExtendedFormatting)
    if ( defined $data && $data !~ m{$NL}sm ) {

        # No newlines in $css, so we assume that it is a file name
        return qq{<link rel="stylesheet" href="$data" type="text/css">};
    }

    if ( not defined $data ) { $data = $css; }
    return qq{<style type="text/css"> <!--$data--></style>};
}

1;
