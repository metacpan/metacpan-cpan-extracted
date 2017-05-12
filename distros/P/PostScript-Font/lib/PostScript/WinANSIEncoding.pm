# RCS Status      : $Id: WinANSIEncoding.pm,v 1.3 2003-10-23 14:11:37+02 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Jun 18 06:37:31 2003
# Last Modified By: Johan Vromans
# Last Modified On: Thu Oct 23 14:11:32 2003
# Update Count    : 11
# Status          : Released

################ Module Preamble ################

package PostScript::WinANSIEncoding;

$VERSION = "1.01";

use 5.005;
use strict;

# Windows ANSI Encoding.
my $WinANSIEncoding_str =
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  "space exclam quotedbl numbersign dollar percent ampersand quotesingle ".
  "parenleft parenright asterisk plus comma hyphen period slash zero one ".
  "two three four five six seven eight nine colon semicolon less equal ".
  "greater question at A B C D E F G H I J K L M N O P Q R S T U V W X ".
  "Y Z bracketleft backslash bracketright asciicircum underscore ".
  "grave a b c d e f g h i j k l m n o p q r s t u v w x y z ".
  "braceleft bar braceright asciitilde bullet Euro bullet quotesinglbase ".
  "florin quotedblbase ellipsis dagger daggerdbl circumflex perthousand ".
  "Scaron guilsinglleft OE bullet Zcaron bullet bullet quoteleft quoteright ".
  "quotedblleft quotedblright bullet endash emdash tilde trademark scaron ".
  "guilsinglright oe bullet zcaron Ydieresis space exclamdown cent ".
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

my @WinANSIEncoding;

sub string {
    my ($self) = @_;
    $WinANSIEncoding_str;
}

sub array {
    my ($self) = @_;
    @WinANSIEncoding = split(' ', $WinANSIEncoding_str)
      unless @WinANSIEncoding;
    wantarray ? @WinANSIEncoding : \@WinANSIEncoding;
}

if ( !caller ) {
    my @a = array();
    die("Size = ", scalar(@a), ", should be 256\n")
      unless @a == 256;
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::WinANSIEncoding - WinANSIEncoding for PostScript fonts

=head1 SYNOPSIS

  use PostScript::WinANSIEncoding;
  $enc = PostScript::WinANSIEncoding->array;

=head1 DESCRIPTION

This package contains the Windows ANSI encoding.

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

This program is Copyright 2003,1998 by Squirrel Consultancy. All
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
