# RCS Status      : $Id: ISOLatin1Encoding.pm,v 1.2 2000-11-15 14:50:14+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Sun Jun 18 10:47:10 2000
# Last Modified By: Johan Vromans
# Last Modified On: Wed Nov 15 14:48:53 2000
# Update Count    : 16
# Status          : Released

################ Module Preamble ################

package PostScript::ISOLatin1Encoding;

$VERSION = "1.01";

use 5.005;
use strict;

# Adobe ISOLatin1Encoding.
my $ISOLatin1Encoding_str =
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  "space exclam quotedbl numbersign dollar percent ampersand quoteright ".
  "parenleft parenright asterisk plus comma minus period slash zero one ".
  "two three four five six seven eight nine colon semicolon less equal ".
  "greater question at A B C D E F G H I J K L M N O P Q R S T U V W X ".
  "Y Z bracketleft backslash bracketright asciicircum underscore ".
  "quoteleft a b c d e f g h i j k l m n o p q r s t u v w x y z ".
  "braceleft bar braceright asciitilde .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef dotlessi grave acute ".
  "circumflex tilde macron breve dotaccent dieresis .notdef ring ".
  "cedilla .notdef hungarumlaut ogonek caron space exclamdown cent ".
  "sterling currency yen brokenbar section dieresis copyright ".
  "ordfeminine guillemotleft logicalnot hyphen registered macron degree ".
  "plusminus twosuperior threesuperior acute mu paragraph ".
  "periodcentered cedilla onesuperior ordmasculine guillemotright ".
  "onequarter onehalf threequarters questiondown Agrave Aacute ".
  "Acircumflex Atilde Adieresis Aring AE Ccedilla Egrave Eacute ".
  "Ecircumflex Edieresis Igrave Iacute Icircumflex Idieresis Eth Ntilde ".
  "Ograve Oacute Ocircumflex Otilde Odieresis multiply Oslash Ugrave ".
  "Uacute Ucircumflex Udieresis Yacute Thorn germandbls agrave aacute ".
  "acircumflex atilde adieresis aring ae ccedilla egrave eacute ".
  "ecircumflex edieresis igrave iacute icircumflex idieresis eth ntilde ".
  "ograve oacute ocircumflex otilde odieresis divide oslash ugrave ".
  "uacute ucircumflex udieresis yacute thorn ydieresis";

my @ISOLatin1Encoding;

sub string {
    my ($self) = @_;
    $ISOLatin1Encoding_str;
}

sub array {
    my ($self) = @_;
    @ISOLatin1Encoding = split(' ', $ISOLatin1Encoding_str)
      unless @ISOLatin1Encoding;
    wantarray ? @ISOLatin1Encoding : \@ISOLatin1Encoding;
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::ISOLatin1Encoding - ISOLatin1Encoding for PostScript fonts

=head1 SYNOPSIS

  use PostScript::ISOLatin1Encoding;
  $enc = PostScript::ISOLatin1Encoding->array;

=head1 DESCRIPTION

This package contains the PostScript ISO-8859-1 (ISO Latin-1) encoding.

=head1 CLASS METHODS

=over 4

=item array

In list context, returns an array that contains all the glyphs names
for this encoding encoding.

In scalar context, returns a reference to an (internal) array
containing the encoding. This should be considered read-only.

=item string

Returns the encoding as a string, with all entries concatenated. This
is useful to quickly compare encodings.

=head1 SEE ALSO

=over 4

=item http://partners.adobe.com/asn/developer/PDFS/TN/T1_SPEC.PDF

The specification of the Type 1 font format.

=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2000,1998 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
