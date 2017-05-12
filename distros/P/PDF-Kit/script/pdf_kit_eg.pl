#!/usr/bin/env perl
# --------------------------------------
#
#   Title: Test PDF::Kit
# Purpose: Test PDF::Kit
#
#    Name: pdf_kit_eg
#    File: pdf_kit_eg
# Created: June 18, 2009
#
# Copyright: Copyright 2009 by Shawn H. Corey.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# --------------------------------------
# Pragmas

require v5.8.0;

use strict;
use warnings;

use utf8;  # Convert all UTF-8 to Perl's internal representation.

# --------------------------------------
# Version
use version; our $VERSION = qv(v1.0.1);

# --------------------------------------
# Modules
use Carp;
use Data::Dumper;
use English qw( -no_match_vars ) ;  # Avoids regex performance penalty
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use POSIX;

use PDF::API2;
use PDF::Kit;

# --------------------------------------
# Configuration Parameters

my $SPACE = "\x20";

my $Box_color = '#0000ff';

my $Phrase = 'The quick brown fox jumped over the lazy dogs.';
my $Block = [ in2pts( 1 ), in2pts( 1 ), in2pts( 8.5 - 1 ), in2pts( 11 - 1 ) ];

my %P_opts = (
  -print_text     => \&print_text,
  -compute_length => \&print_text,
  -block          => $Block,
  -space_after    => 1,

  -size           => 20,
  -indent         => 0,
  -alignment      => 0,
  -justify_word   => 0,
  -justify_char   => 0,
  -justify_scale  => 0,
);

# Make Data::Dumper pretty
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Maxdepth = 0;

# --------------------------------------
# Variables

my $Box = 0;

my ( $Pdf, $Page, $Pen );
my ( $Font_plain, $Font_bold, $Font_italic, $Font_bolditalic );

# Documentation levels
my $DOC_USAGE = 0;
my $DOC_HELP  = 1;
my $DOC_VER   = 2;
my $DOC_MAN   = 3;

# --------------------------------------
# Subroutines

# --------------------------------------
#       Name: print_documentation
#      Usage: print_documentation( $documentation_level );
#    Purpose: Print the usage, help, or man documentation.
#    Returns: Does not return.
# Parameters: $documentation_level -- how much documentation to display.
#                                     0 == usage
#                                     1 == help
#                                     2 == version
#                                     other == man
#
sub print_documentation {
  my $level = shift @_ || 0;

  # print the usage documentation
  if( $level == $DOC_USAGE ){
    pod2usage(
      -exitval => 2,
      -verbose => 99,
      -sections => 'USAGE',
    );
  }

  # print the help documentation
  if( $level == $DOC_HELP ){
    pod2usage(
      -exitval => 2,
      -verbose => 99,
      -sections => 'NAME|VERSION|USAGE|REQUIRED ARGUMENTS|OPTIONS',
    );
  }

  # print the version
  if( $level == $DOC_VER ){
    pod2usage(
      -exitval => 2,
      -verbose => 99,
      -sections => 'VERSION',
    );
  }

  # print the man documentation
  pod2usage(
    -exitval => 2,
    -verbose => 2,
  );
}

# --------------------------------------
#       Name: get_cmd_opts
#      Usage: get_cmd_opts();
#    Purpose: Process the command-line switches.
#    Returns: none
# Parameters: none
#
sub get_cmd_opts {

  # Check command-line options
  unless( GetOptions(
    box           => \$Box,
    'alignment=f' => \$P_opts{-alignment},
    'char=f'      => \$P_opts{-justify_char},
    'indent=f'    => \$P_opts{-indent},
    'scale=f'     => \$P_opts{-justify_scale},
    'size=f'      => \$P_opts{-size},
    'word=f'      => \$P_opts{-justify_word},

    usage   => sub { print_documentation( $DOC_USAGE ); },
    help    => sub { print_documentation( $DOC_HELP  ); },
    version => sub { print_documentation( $DOC_VER   ); },
    man     => sub { print_documentation( $DOC_MAN   ); },
  )){
    print_documentation( $DOC_USAGE );
  }
  $P_opts{-indent} = in2pts( $P_opts{-indent} );

}

# --------------------------------------
#       Name: setup
#      Usage: setup();
#    Purpose: Set up the application.
# Parameters: none
#    Returns: none
#
sub setup {

  $Pdf = PDF::API2->new();

  $Font_plain      = $Pdf->corefont( 'Times-Roman' );
  $Font_bold       = $Pdf->corefont( 'Times-Bold' );
  $Font_italic     = $Pdf->corefont( 'Times-Italic' );
  $Font_bolditalic = $Pdf->corefont( 'Times-BoldItalic' );

  $Page = $Pdf->page();
  $Pen = $Page->text();
  # delete $Pen->{Filter}; # TEMPORARY

  if( $Box ){
    my $gfx = $Page->gfx();
    $gfx->strokecolor( $Box_color );
    $gfx->rectxy( @$Block );
    $gfx->stroke();
  }

  return;
}

# --------------------------------------
#       Name: print_text
#      Usage: $length = print_text( \%opts, $text );
#    Purpose: Print the text.
# Parameters:  \%opts -- How to
#               $text -- What to print
#    Returns: $length -- How much was printed
#
sub print_text {
  my $opts   = shift @_;
  my $text   = shift @_;
  my $length = 0;

  if( $opts->{bold} && $opts->{italic} ){
    $Pen->font( $Font_bolditalic, $opts->{-size} );
  }elsif( $opts->{italic} ){
    $Pen->font( $Font_italic, $opts->{-size} );
  }elsif( $opts->{bold} ){
    $Pen->font( $Font_bold, $opts->{-size} );
  }else{
    $Pen->font( $Font_plain, $opts->{-size} );
  }

  my $wordspace = $Pen->wordspace( $opts->{-wordspace} );
  my $charspace = $Pen->charspace( $opts->{-charspace} );
  my $hspace = $Pen->hspace( $opts->{-hspace} );

  $Pen->wordspace( 0 ) if( exists( $opts->{-wordspace} ));
  $Pen->charspace( 0 ) if( exists( $opts->{-charspace} ));
  $Pen->hspace( 100 ) if( exists( $opts->{-hspace} ));

  if( $opts->{-print} ){
    $Pen->wordspace( $opts->{-wordspace} ) if( exists( $opts->{-wordspace} ) );
    $Pen->charspace( $opts->{-charspace} ) if( exists( $opts->{-charspace} ) );
    $Pen->hspace( $opts->{-hspace} ) if( exists( $opts->{-hspace} ) );

    my %text_opts = ();
    %text_opts = %{ $opts->{text_opts} } if exists( $opts->{text_opts} );

    $Pen->translate( $opts->{-x}, $opts->{-y} );
    $length = $Pen->text( $text, %text_opts );

  }else{
    $length = $Pen->advancewidth( $text );
  }

  $Pen->wordspace( $wordspace ) if( exists( $opts->{-wordspace} ));
  $Pen->charspace( $charspace ) if( exists( $opts->{-charspace} ));
  $Pen->hspace( $hspace ) if( exists( $opts->{-hspace} ));

  return $length;
}

# --------------------------------------
# Main

get_cmd_opts();

setup();

if( @ARGV ){
  $Phrase = join( $SPACE, @ARGV );
}
my $Paragraph = [
  $Phrase,
  [{ bold=>1 }, $Phrase, ],
  [{ italic=>1 }, $Phrase, ],
  [{ bold=>1, italic=>1 }, $Phrase, ],
  [{ -space_after=>0, text_opts=>{ -underline=>'auto' }, },
    $Phrase, $SPACE,
    [{ bold=>1 }, $Phrase, $SPACE, ],
    [{ italic=>1 }, $Phrase, $SPACE, ],
    [{ bold=>1, italic=>1 }, $Phrase, ],
  ],
  $SPACE,
  [{ -space_after=>0 },
    small_caps( $P_opts{-size}, 0.65, $Phrase, $SPACE ),
    [{ bold=>1 }, small_caps( $P_opts{-size}, 0.65, $Phrase, $SPACE ), ],
    [{ italic=>1 }, small_caps( $P_opts{-size}, 0.65, $Phrase, $SPACE ), ],
    [{ bold=>1, italic=>1 }, small_caps( $P_opts{-size}, 0.65, $Phrase, ), ],
  ],
  $SPACE,
  $Phrase,
];
print_paragraph( \%P_opts, $Paragraph );
$Pdf->saveas( basename( $0 ) . 'pdf' );

__DATA__
__END__

=head1 NAME

pdf_kit_eg - Test PDF::Kit

=head1 VERSION

This document refers to pdf_kit_eg version v1.0.1

=head1 USAGE

  pdf_kit_eg [<options>] [<phrase>] ...
  pdf_kit_eg --usage|help|version|man

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=over 4

=item --box

Draw a blue box around the block containing the text.

=item --indent=f

Set the indentation (in inches) of the paragraph.

=item --size=f

Set the font size.

=item --alignment=f

Set the alignment.
A value of 0 (zero) is left aligned.
A value of 0.5 is center aligned.
A value of 1 is right aligned.

=item --char=f

Set the weight of the justification by character.
Each character is given a little extra space so that the paragraph is fully justified.

=item --word=f

Set the weight of the justification by space.
Each space character, ASCII code 32, is given a little extra space so that the paragraph is fully justified.

=item --scale=f

Set the weight of the justification by horizontal scaling.
Each character stretched horizontally so that the paragraph is fully justified.

=item --usage

Print a brief usage message.

=item --help

Print usage, required arguments, and options.

=item --version

Print the version number.

=item --man

Print the manual page.

=back

=head1 DESCRIPTION

Tests PDF::Kit

The given phrase is repeated in paragraph using different fonts and styles.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item *

PDF::API2

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 SEE ALSO

=head1 ORIGINAL AUTHOR

Shawn H. Corey  shawnhcorey@gmail.com

=head2 Contributing Authors

(Insert your name here if you modified this program or its documentation.
 Do not remove this comment.)

=head1 COPYRIGHT & LICENCES

Copyright 2009 by Shawn H. Corey.  All rights reserved.

=head2 Software Licence

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=head2 Document Licence

Permission is granted to copy, distribute and/or modify this document under the
terms of the GNU Free Documentation License, Version 1.2 or any later version
published by the Free Software Foundation; with the Invariant Sections being
ORIGINAL AUTHOR, COPYRIGHT & LICENCES, Software Licence, and Document Licence.

You should have received a copy of the GNU Free Documentation Licence
along with this document; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=head1 ACKNOWLEDGEMENTS

=head1 HISTORY

  $Log$

=cut
