# RCS Status      : $Id: ISOLatin9Encoding.pm,v 1.2 2002-12-24 17:49:19+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Sat Dec 21 11:48:19 2002
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec 24 00:11:33 2002
# Update Count    : 16
# Status          : Released

################ Module Preamble ################

package PostScript::ISOLatin9Encoding;

$VERSION = "1.01";

use 5.005;
use strict;

# Adobe ISOLatin9Encoding.
my $ISOLatin9Encoding_str =
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
  "sterling Euro yen Scaron section scaron copyright ".
  "ordfeminine guillemotleft logicalnot hyphen registered macron degree ".
  "plusminus twosuperior threesuperior Zcaron mu paragraph ".
  "periodcentered zcaron onesuperior ordmasculine guillemotright ".
  "OE oe Ydieresis questiondown Agrave Aacute ".
  "Acircumflex Atilde Adieresis Aring AE Ccedilla Egrave Eacute ".
  "Ecircumflex Edieresis Igrave Iacute Icircumflex Idieresis Eth Ntilde ".
  "Ograve Oacute Ocircumflex Otilde Odieresis multiply Oslash Ugrave ".
  "Uacute Ucircumflex Udieresis Yacute Thorn germandbls agrave aacute ".
  "acircumflex atilde adieresis aring ae ccedilla egrave eacute ".
  "ecircumflex edieresis igrave iacute icircumflex idieresis eth ntilde ".
  "ograve oacute ocircumflex otilde odieresis divide oslash ugrave ".
  "uacute ucircumflex udieresis yacute thorn ydieresis";

my @ISOLatin9Encoding;

sub string {
    my ($self) = @_;
    $ISOLatin9Encoding_str;
}

sub array {
    my ($self) = @_;
    @ISOLatin9Encoding = split(' ', $ISOLatin9Encoding_str)
      unless @ISOLatin9Encoding;
    wantarray ? @ISOLatin9Encoding : \@ISOLatin9Encoding;
}

sub ps_vector {
    my ($self) = @_;
    array();			# will fill @ISOLatin9Encoding
    my $tally = 0;
    my $ret = "/ISOLatin9Encoding [\n";

    foreach my $sym ( @ISOLatin9Encoding ) {
	if ( $tally + length($sym) + 2 > 72 ) {
	    $ret .= "\n";
	    $tally = 0;
	}
	$ret .= " /$sym";
	$tally += length($sym) + 2;
    }

    $ret . "\n] def\n";
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::ISOLatin9Encoding - ISOLatin9Encoding for PostScript fonts

=head1 SYNOPSIS

  use PostScript::ISOLatin9Encoding;
  my $enc = PostScript::ISOLatin9Encoding->array;

=head1 DESCRIPTION

This package contains the PostScript ISO-8859-15 (ISO Latin-9) encoding.

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

This program is Copyright 2002 by Squirrel Consultancy. All
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
