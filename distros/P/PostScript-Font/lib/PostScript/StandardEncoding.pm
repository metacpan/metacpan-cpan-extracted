# RCS Status      : $Id: StandardEncoding.pm,v 1.2 2000-11-15 14:50:14+01 jv Exp $
# Author          : Johan Vromans
# Created On      : Sun Jun 18 10:47:10 2000
# Last Modified By: Johan Vromans
# Last Modified On: Wed Nov 15 14:49:07 2000
# Update Count    : 14
# Status          : Released

################ Module Preamble ################

package PostScript::StandardEncoding;

$VERSION = "1.01";

use 5.005;
use strict;

# Adobe StandardEncoding.
my @StandardEncoding;
my $StandardEncoding_str =
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  "space exclam quotedbl numbersign dollar percent ampersand quoteright ".
  "parenleft parenright asterisk plus comma hyphen period slash zero ".
  "one two three four five six seven eight nine colon semicolon less ".
  "equal greater question at A B C D E F G H I J K L M N O P Q R S T U ".
  "V W X Y Z bracketleft backslash bracketright asciicircum underscore ".
  "quoteleft a b c d e f g h i j k l m n o p q r s t u v w x y z ".
  "braceleft bar braceright asciitilde .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef exclamdown cent ".
  "sterling fraction yen florin section currency quotesingle ".
  "quotedblleft guillemotleft guilsinglleft guilsinglright fi fl ".
  ".notdef endash dagger daggerdbl periodcentered .notdef paragraph ".
  "bullet quotesinglbase quotedblbase quotedblright guillemotright ".
  "ellipsis perthousand .notdef questiondown .notdef grave acute ".
  "circumflex tilde macron breve dotaccent dieresis .notdef ring ".
  "cedilla .notdef hungarumlaut ogonek caron emdash .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef .notdef .notdef ".
  ".notdef .notdef .notdef .notdef .notdef .notdef AE .notdef ".
  "ordfeminine .notdef .notdef .notdef .notdef Lslash Oslash OE ".
  "ordmasculine .notdef .notdef .notdef .notdef .notdef ae .notdef ".
  ".notdef .notdef dotlessi .notdef .notdef lslash oslash oe germandbls ".
  ".notdef .notdef .notdef .notdef";

sub string {
    my ($self) = @_;
    $StandardEncoding_str;
}

sub array {
    my ($self) = @_;
    @StandardEncoding = split(' ', $StandardEncoding_str)
      unless @StandardEncoding;
    wantarray ? @StandardEncoding : \@StandardEncoding;
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::StandardEncoding - Adobe StandardEncoding for PostScript fonts

=head1 SYNOPSIS

  use PostScript::StandardEncoding;
  $enc = PostScript::StandardEncoding->array;

=head1 DESCRIPTION

This package contains the PostScript StandardEncoding.

=head1 CLASS METHODS

=over 4

=item array

In list context, returns an array containing the encoding.

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
