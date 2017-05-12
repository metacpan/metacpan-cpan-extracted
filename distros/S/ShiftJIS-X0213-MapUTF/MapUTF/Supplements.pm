package ShiftJIS::X0213::MapUTF::Supplements;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw(%Supplements);

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(to_sjis0213_supplements to_sjis2004_supplements);
@EXPORT_OK = qw(%Supplements);

$VERSION = '0.40';

%Supplements = (
  0x00B5,	# MICRO SIGN (ISO/IEC 8859-1 11/05)
    "\x83\xCA",	# GREEK SMALL LETTER MU (U+03BC)

  0x0110,	# LATIN CAPITAL LETTER D WITH STROKE (ISO/IEC 8859-2 13/00)
    "\x85\x66",	# LATIN CAPITAL LETTER ETH (U+00D0)

  0x2015,	# HORIZONTAL BAR
    "\x81\x5C", # EM DASH (U+2014)

  0x2211,	# N-ARY SUMMATION (Windows CP932 0x8794)
    "\x83\xB0",	# GREEK CAPITAL LETTER SIGMA (U+03A3)

  0x2985,	# LEFT WHITE PARENTHESIS
    "\x81\xD4", # FULLWIDTH LEFT WHITE PARENTHESIS (U+FF5F)

  0x2986,	# RIGHT WHITE PARENTHESIS
    "\x81\xD5",	# FULLWIDTH RIGHT WHITE PARENTHESIS (U+FF60)

  0x3099,	# COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    "\xDE",	# HALFWIDTH KATAKANA VOICED SOUND MARK (U+FF9E) // NFKC

  0x309A,	# COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    "\xDF",	# HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK (U+FF9F) // NFKC

  0x4E44,	# CJK UNIFIED IDEOGRAPH-4E44 (JIS X 0212 16-17)
    "\x81\x59",	# IDEOGRAPHIC CLOSING MARK (U+3006)

  0x9B1C,	# CJK UNIFIED IDEOGRAPH-9B1C (for backward compatibility)
    "\xFC\x5A", # CJK UNIFIED IDEOGRAPH-9B1C

  0x9B1D,	# CJK UNIFIED IDEOGRAPH-9B1D (JIS X 0213:2000)
    "\xFC\x5A", # CJK UNIFIED IDEOGRAPH-9B1C

  0xFF3C,	# FULLWIDTH REVERSE SOLIDUS
    "\x81\x5F", # REVERSE SOLIDUS (U+005C)

  0xFF5E,	# FULLWIDTH TILDE
    "\x81\xB0",	# TILDE (U+007E)

  0xFFE0,	# FULLWIDTH CENT SIGN
    "\x81\x91",	# CENT SIGN (U+00A2)

  0xFFE1,	# FULLWIDTH POUND SIGN
    "\x81\x92",	# POUND SIGN (U+00A3)

  0xFFE2,	# FULLWIDTH NOT SIGN
    "\x81\xCA",	# NOT SIGN (U+00AC)

  0xFFE4,	# FULLWIDTH BROKEN BAR
    "\x85\x44",	# BROKEN BAR (U+00A6)
);

sub to_sjis0213_supplements { defined $_[0] && $Supplements{$_[0]} || '' }
sub to_sjis2004_supplements { defined $_[0] && $Supplements{$_[0]} || '' }

1;
__END__

=head1 NAME

ShiftJIS::X0213::MapUTF::Supplements - Supplemental Mapping from Unicode to Shift_JISX0213

=head1 SYNOPSIS

  use ShiftJIS::X0213::MapUTF;
  use ShiftJIS::X0213::MapUTF::Supplements;

  $sjis_str = utf8_to_sjis2004   (\&to_sjis2004_supplements, $utf8_str);
  $sjis_str = utf16_to_sjis2004  (\&to_sjis2004_supplements, $utf16_str);
  $sjis_str = utf16le_to_sjis2004(\&to_sjis2004_supplements, $utf16le_str);
  $sjis_str = utf16be_to_sjis2004(\&to_sjis2004_supplements, $utf16be_str);
  $sjis_str = utf32_to_sjis2004  (\&to_sjis2004_supplements, $utf32_str);
  $sjis_str = utf32le_to_sjis2004(\&to_sjis2004_supplements, $utf32le_str);
  $sjis_str = utf32be_to_sjis2004(\&to_sjis2004_supplements, $utf32be_str);
  $sjis_str = unicode_to_sjis2004(\&to_sjis2004_supplements, $unicode_str);

  $sjis_str = utf8_to_sjis0213   (\&to_sjis0213_supplements, $utf8_str);
  $sjis_str = utf16_to_sjis0213  (\&to_sjis0213_supplements, $utf16_str);
  $sjis_str = utf16le_to_sjis0213(\&to_sjis0213_supplements, $utf16le_str);
  $sjis_str = utf16be_to_sjis0213(\&to_sjis0213_supplements, $utf16be_str);
  $sjis_str = utf32_to_sjis0213  (\&to_sjis0213_supplements, $utf32_str);
  $sjis_str = utf32le_to_sjis0213(\&to_sjis0213_supplements, $utf32le_str);
  $sjis_str = utf32be_to_sjis0213(\&to_sjis0213_supplements, $utf32be_str);
  $sjis_str = unicode_to_sjis0213(\&to_sjis0213_supplements, $unicode_str);

=head1 DESCRIPTION

This module provides some supplemental mappings (fallbacks)
from Unicode to Shift_JISX0213, via a coderef.

=over 4

=item C<$sjis2004_char = to_sjis2004_supplements($unicode_codepoint)>

=item C<$sjis0213_char = to_sjis0213_supplements($unicode_codepoint)>

Returns a SJIS character (as a string) for some Unicode codepoints
unmapped to SJIS. Otherwise returns a null string.

B<NOTE:> C<to_sjis0213_supplements> is just an alias
for C<to_sjis2004_supplements>, then their mappings has no difference.

E.g. C<to_sjis2004_supplements(0x9B1D)> returns C<"\xFC\x5A">;
     C<to_sjis2004_supplements(0x00B5)> returns C<"\x83\xCA">;
     C<to_sjis0213_supplements(0x9B1C)> returns C<"\xFC\x5A">;
     C<to_sjis0213_supplements(0x00B5)> returns C<"\x83\xCA">.


=back

=head1 DISCLAIMER

This module is an B<experimental> release.
Propriety of mapping is not guaranteed.
Any of these supplemental mappings
may be added, modified, or removed in future.

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

  Copyright(C) 2002-2007, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<ShiftJIS::X0213::MapUTF>

=back

=cut
