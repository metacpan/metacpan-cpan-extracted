package ShiftJIS::CP932::MapUTF::Supplements;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw(%Supplements);

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(to_cp932_supplements);
@EXPORT_OK = qw(%Supplements);

$VERSION = '1.03';

%Supplements = (
  0x00A2,	# CENT SIGN
    "\x81\x91", # FULLWIDTH CENT SIGN (U+FFE0) // <-NFKC

  0x00A3,	# POUND SIGN
    "\x81\x92", # FULLWIDTH POUND SIGN (U+FFE1) // <-NFKC

  0x00A5,	# YEN SIGN
    "\x5C",	# REVERSE SOLIDUS (U+005C)

  0x00A6,	# BROKEN BAR
    "\xFA\x55", # FULLWIDTH BROKEN BAR (U+FFE4) // <-NFKC

  0x00AB,	# LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
    "\x81\xE1", # MUCH LESS-THAN (U+226A)

  0x00AC,	# NOT SIGN
    "\x81\xCA", # FULLWIDTH NOT SIGN (U+FFE2) // <-NFKC

  0x00AF,	# MACRON
    "\x81\x50", # FULLWIDTH MACRON (U+FFE3)

  0x00B5,	# MICRO SIGN
    "\x83\xCA", # GREEK SMALL LETTER MU (U+03BC)

  0x00B7,	# MIDDLE DOT
    "\x81\x45", # KATAKANA MIDDLE DOT (U+30FB)

  0x00B8,	# CEDILLA
    "\x81\x43", # FULLWIDTH COMMA (U+FF0C)

  0x00BB,	# RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
    "\x81\xE2", # MUCH GREATER-THAN (U+226B)

  0x00C5,	# LATIN CAPITAL LETTER A WITH RING ABOVE
    "\x81\xF0", # ANGSTROM SIGN (U+212B) // <-NFC

  0x2014,	# EM DASH
    "\x81\x5C", # HORIZONTAL BAR (U+2015)

  0x2016,	# DOUBLE VERTICAL LINE
    "\x81\x61", # PARALLEL TO (U+2225)

  0x203E,	# OVERLINE
    "\x7E",	# TILDE (U+007E)

  0x2212,	# MINUS SIGN
    "\x81\x7C", # FULLWIDTH HYPHEN-MINUS (U+FF0D)

  0x301C,	# WAVE DASH
    "\x81\x60", # FULLWIDTH TILDE (U+FF5E)

  0x3094,	# HIRAGANA LETTER VU
    "\x83\x94", # KATAKANA LETTER VU (U+30F4)

  0x3099,	# COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    "\xDE",	# HALFWIDTH KATAKANA VOICED SOUND MARK (U+FF9E) // <-NFKC

  0x309A,	# COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    "\xDF",	# HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK (U+FF9F) // <-NFKC

  0x51DE,	# CJK UNIFIED IDEOGRAPH-51DE
    "\xFB\x58", # COMPATIBILITY IDEOGRAPH-FA15 // <-NFC

  0x8612,	# CJK UNIFIED IDEOGRAPH-8612
    "\xFB\x9F", # COMPATIBILITY IDEOGRAPH-FA20 // <-NFC
);

sub to_cp932_supplements { defined $_[0] && $Supplements{$_[0]} || '' }

1;
__END__

=head1 NAME

ShiftJIS::CP932::MapUTF::Supplements - Supplemental Mapping from Unicode to Microsoft Windows CP-932

=head1 SYNOPSIS

  use ShiftJIS::CP932::MapUTF qw(:all);
  use ShiftJIS::CP932::MapUTF::Supplements;

  $cp932_string  = utf8_to_cp932   (\&to_cp932_supplements, $utr8_string);
  $cp932_string  = utf16_to_cp932  (\&to_cp932_supplements, $utf16_string);
  $cp932_string  = utf16le_to_cp932(\&to_cp932_supplements, $utf16le_string);
  $cp932_string  = utf16be_to_cp932(\&to_cp932_supplements, $utf16be_string);
  $cp932_string  = utf32_to_cp932  (\&to_cp932_supplements, $utf32_string);
  $cp932_string  = utf32le_to_cp932(\&to_cp932_supplements, $utf32le_string);
  $cp932_string  = utf32be_to_cp932(\&to_cp932_supplements, $utf32be_string);
  $cp932_string  = unicode_to_cp932(\&to_cp932_supplements, $unicode_string);

=head1 DESCRIPTION

This module provides some supplemental mappings (fallbacks)
from Unicode to CP-932, via a coderef.

=over 4

=item C<$cp932_char = to_cp932_supplements($unicode_codepoint)>

It returns a CP-932 character (as a string) for some Unicode
code points which are not mapped to CP-932.
Otherwise it returns a null string.

e.g. C<to_cp932_supplements(0xA5)> returns C<"\x5C">.

=back

=head1 DISCLAIMER

This module is an B<experimental> release.
Propriety of mapping is not guaranteed.
Any of these supplemental mappings
may be added, modified, or removed in future.

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2001-2007, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<ShiftJIS::CP932::MapUTF>

=back

=cut
