#---------------------------------------------------------------------
package PostScript::File::Metrics::Loader;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 29 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Load metrics for PostScript fonts using Font::AFM
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '2.20';          ## no critic
# This file is part of PostScript-File 2.23 (October 10, 2015)

use strict;
use warnings;
use Carp 'confess';
# RECOMMEND PREREQ: Font::AFM
use Font::AFM;
use PostScript::File 2.00 ();

our %attribute = qw(
  FullName           full_name
  FamilyName         family
  Weight             weight
  IsFixedPitch       fixed_pitch
  ItalicAngle        italic_angle
  FontBBox           font_bbox
  UnderlinePosition  underline_position
  UnderlineThickness underline_thickness
  Version            version
  CapHeight          cap_height
  XHeight            x_height
  Ascender           ascender
  Descender          descender
);

our @numeric_attributes = qw(
  ascender
  cap_height
  descender
  italic_angle
  underline_position
  underline_thickness
  x_height
);

our @StandardEncoding = qw(
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    space exclam quotedbl numbersign
	dollar percent ampersand quoteright
    parenleft parenright asterisk plus
	comma hyphen period slash
    zero one two three
	four five six seven
    eight nine colon semicolon
	less equal greater question
    at A B C D E F G
    H I J K L M N O
    P Q R S T U V W
    X Y Z bracketleft backslash bracketright asciicircum underscore
    quoteleft a b c d e f g
    h i j k l m n o
    p q r s t u v w
    x y z braceleft bar braceright asciitilde .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef exclamdown cent sterling
	fraction yen florin section
    currency quotesingle quotedblleft guillemotleft
	guilsinglleft guilsinglright fi fl
    .notdef endash dagger daggerdbl
	periodcentered .notdef paragraph bullet
    quotesinglbase quotedblbase quotedblright guillemotright
	ellipsis perthousand .notdef questiondown
    .notdef grave acute circumflex tilde macron breve dotaccent
    dieresis .notdef ring cedilla .notdef hungarumlaut ogonek caron
    emdash .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef
    .notdef AE .notdef ordfeminine .notdef .notdef .notdef .notdef
    Lslash Oslash OE ordmasculine .notdef .notdef .notdef .notdef
    .notdef ae .notdef .notdef .notdef dotlessi .notdef .notdef
    lslash oslash oe germandbls .notdef .notdef .notdef .notdef
);

our @SymbolEncoding = (
  ('.notdef') x 32,
# \040
  qw(space exclam universal numbersign
	existential percent ampersand suchthat
    parenleft parenright asteriskmath plus
	comma minus period slash
    zero one two three
	four five six seven
    eight nine colon semicolon
	less equal greater question),
# \100
  qw(congruent Alpha Beta Chi
	Delta Epsilon Phi Gamma
    Eta Iota theta1 Kappa
	Lambda Mu Nu Omicron
    Pi Theta Rho Sigma
	Tau Upsilon sigma1 Omega
    Xi Psi Zeta bracketleft
	therefore bracketright perpendicular underscore),
# \140
  qw(radicalex alpha beta chi
	delta epsilon phi gamma
    eta iota phi1 kappa
	lambda mu nu omicron
    pi theta rho sigma
	tau upsilon omega1 omega
    xi psi zeta braceleft
	bar braceright similar .notdef),
# \200
  ('.notdef') x 32,
# \240
  qw(Euro Upsilon1 minute lessequal
	fraction infinity florin club
    diamond heart spade arrowboth
	arrowleft arrowup arrowright arrowdown
    degree plusminus second greaterequal
	multiply proportional partialdiff bullet
    divide notequal equivalence approxequal
	ellipsis arrowvertex arrowhorizex carriagereturn),
# \300
  qw(aleph Ifraktur Rfraktur weierstrass
	circlemultiply circleplus emptyset intersection
    union propersuperset reflexsuperset notsubset
	propersubset reflexsubset element notelement
    angle gradient registerserif copyrightserif
	trademarkserif product radical dotmath
    logicalnot logicaland logicalor arrowdblboth
	arrowdblleft arrowdblup arrowdblright arrowdbldown),
# \340
  qw(lozenge angleleft registersans copyrightsans
	trademarksans summation parenlefttp parenleftex
    parenleftbt bracketlefttp bracketleftex bracketleftbt
	bracelefttp braceleftmid braceleftbt braceex
    .notdef angleright integral integraltp
	integralex integralbt parenrighttp parenrightex
    parenrightbt bracketrighttp bracketrightex bracketrightbt
	bracerighttp bracerightmid bracerightbt .notdef),
);
#=====================================================================


sub load
{
  my ($font, $encodings) = @_;

  my $afm = Font::AFM->new($font);


  # Process the encoding-independent font attributes:
  unless ($PostScript::File::Metrics::Info{$font}) {
    my %info;
    while (my ($method, $key) = each %attribute) {
      # Font::AFM croaks instead of returning undef:
      $info{$key} = do { local $@; eval { $afm->$method } };
    }

    # Ensure Data::Dumper will dump numbers as such:
    for (@numeric_attributes) {
      $info{$_} += 0 if defined $info{$_};
    }

    # Convert attributes to be more "Perlish":
    $info{fixed_pitch} = ($info{fixed_pitch} eq 'true' ? 1 : 0);
    $info{font_bbox} = [ map { $_ + 0 } split ' ', $info{font_bbox} ];

    $PostScript::File::Metrics::Info{$font} = \%info;
  } # end unless info has been loaded

  # Create a width table for each requested encoding:
  my $wxHash = $afm->Wx;

  foreach my $encoding (@$encodings) {
    next if $PostScript::File::Metrics::Metrics{$font}{$encoding};

    my $vector = get_encoding_vector($encoding);

    my @wx;
    for (0..255) {
      my $name = $vector->[$_];
      if (exists $wxHash->{$name}) {
        push @wx, $wxHash->{$name} + 0;
      } else {
        push @wx, $wxHash->{'.notdef'} + 0;
      }
    } # end for 0..255

    $PostScript::File::Metrics::Metrics{$font}{$encoding} = \@wx;
  } # end foreach $encoding
} # end load
#---------------------------------------------------------------------


sub get_encoding_vector
{
  my ($encoding) = @_;

  return \@StandardEncoding if $encoding eq 'std';
  return \@SymbolEncoding   if $encoding eq 'sym';

  my $name = $PostScript::File::encoding_name{$encoding}
      or confess "Unknown encoding $encoding";


  $PostScript::File::encoding_def{$name}
      =~ /\bSTARTDIFFENC\b(.+)\bENDDIFFENC\b/s
          or confess "Can't find definition for $encoding";

  my $def = $1;
  $def =~ s/%.*//g;             # Strip comments

  my @vec = @StandardEncoding;

  my $i = 0;
  while ($def =~ /(\S+)/g) {
    my $term = $1;
    if ($term =~ m!^/(.+)!) {
      $vec[$i++] = $1;
    } elsif ($term =~ /^\d+$/) {
      $i = $term;
    } else {
      confess "Invalid term $term in $name";
    }
  }

  return \@vec;
} # end get_encoding_vector

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

PostScript::File::Metrics::Loader - Load metrics for PostScript fonts using Font::AFM

=head1 VERSION

This document describes version 2.20 of
PostScript::File::Metrics::Loader, released October 10, 2015
as part of PostScript-File version 2.23.

=head1 DESCRIPTION

PostScript::File::Metrics::Loader is used by
L<PostScript::File::Metrics> when no pre-compiled metrics are
available for the requested font or encoding.  It uses Font::AFM to
read the AFM file and extract metrics from it.

You should not normally need to use this module, since pre-compiled
metrics for the standard PostScript fonts are included with this
distribution.  If you request metrics for a non-standard font,
PostScript::File::Metrics will load this module automatically.

If you need metrics for additional fonts, you may want to modify and
run F<examples/generate_metrics.pl> to create pre-compiled modules for
them.

=head1 SUBROUTINES

=head2 get_encoding_vector

  PostScript::File::Metrics::Loader::get_encoding_vector($encoding)

This returns the encoding vector for C<$encoding>, an arrayref of 256
glyph names.


=head2 load

  PostScript::File::Metrics::Loader::load($font, \@encodings)

This uses Font::AFM to read the metrics for C<$font>, and creates
width tables for each of the C<@encodings>.  The metrics are stored
into the hashes used internally by PostScript::File::Metrics.

=head1 DIAGNOSTICS

=over

=item C<< Can't find definition for %s >>

If this happens, it indicates you found a bug in
PostScript::File::Metrics::Loader.  Please report it as described
under L</AUTHOR>.


=item C<< Can't find the AFM file for %s >>

Font::AFM could not find F<%s.afm> in any of the directories it
searched.  See L</"CONFIGURATION AND ENVIRONMENT">.


=item C<< Invalid term %s in %s >>

This also indicates a bug in PostScript::File.  Please report it.


=item C<< Unknown encoding %s >>

You asked for an encoding that PostScript::File::Metrics doesn't know about.


=back

=head1 CONFIGURATION AND ENVIRONMENT

PostScript::File::Metrics::Loader requires no configuration files or
environment variables.

However, it uses L<Font::AFM>, and unfortunately that's difficult to
configure properly (which is why I created PostScript::File::Metrics
in the first place).  Font::AFM expects to find a file named
F<FontName.afm> in one of the directories it searches.

I wound up creating symlinks in F</usr/local/lib/afm/> (which is one
of the default paths that Font::AFM searches if you don't have a
C<METRICS> environment variable):

 Courier.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/courier/pcrr8a.afm
 Courier-Bold.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/courier/pcrb8a.afm
 Courier-BoldOblique.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/courier/pcrbo8a.afm
 Courier-Oblique.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/courier/pcrro8a.afm
 Helvetica.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/helvetic/phvr8a.afm
 Helvetica-Bold.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/helvetic/phvb8a.afm
 Helvetica-BoldOblique.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/helvetic/phvbo8a.afm
 Helvetica-Oblique.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/helvetic/phvro8a.afm
 Symbol.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/symbol/psyr.afm
 Times-Bold.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/times/ptmb8a.afm
 Times-BoldItalic.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/times/ptmbi8a.afm
 Times-Italic.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/times/ptmri8a.afm
 Times-Roman.afm
   -> /usr/share/texmf-dist/fonts/afm/adobe/times/ptmr8a.afm

Paths on your system may vary.  I suggest searching for C<.afm> files,
and then grepping them for "FontName X", where X is the font you need
metrics for.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-PostScript-File AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-File >>.

You can follow or contribute to PostScript-File's development at
L<< https://github.com/madsen/postscript-file >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
