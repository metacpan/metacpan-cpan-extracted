use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;

# t/0002-width.t - multibyte display width and character splitting for the
# three supported encodings.  All test strings are built from byte escapes
# so this file stays US-ASCII.

use lib 'lib', 't/lib';
use INA_CPAN_Check;

require TUI::Handy;

# UTF-8 'A' + U+3042 (HIRAGANA A) + 'B'
my $utf8 = "A\xe3\x81\x82B";
# Shift_JIS U+3042 = 0x82 0xa0
my $sjis = "\x82\xa0";
# EUC-JP U+3042 = 0xa4 0xa2 ; SS2 half-width katakana = 0x8e 0xb1
my $euc_zen = "\xa4\xa2";
my $euc_han = "\x8e\xb1";
# UTF-8 half-width katakana occupies one column like its Shift_JIS and EUC-JP
# counterparts, even though it is three bytes long.  The range U+FF61-U+FF9F
# spans two lead-byte pairs, so both ends of both halves are checked.
my $u_ff61 = "\xef\xbd\xa1";        # U+FF61 HALFWIDTH IDEOGRAPHIC FULL STOP
my $u_ff7f = "\xef\xbd\xbf";        # U+FF7F HALFWIDTH KATAKANA SMALL TSU
my $u_ff80 = "\xef\xbe\x80";        # U+FF80 HALFWIDTH KATAKANA TA
my $u_ff9f = "\xef\xbe\x9f";        # U+FF9F HALFWIDTH KATAKANA SEMI-VOICED
my $u_ff60 = "\xef\xbd\xa0";        # U+FF60 - just below the range, wide
my $u_zen  = "\xef\xbd\x81";        # U+FF41 FULLWIDTH SMALL A, also ef bd ..

my @tests = (
    sub { ok(TUI::Handy::_width($utf8, 'utf8') == 4, 'utf8 width A + zenkaku + B == 4') },
    sub { ok(TUI::Handy::_width('hello', 'utf8') == 5, 'ascii width == length') },
    sub { ok(TUI::Handy::_width($sjis, 'sjis') == 2, 'sjis zenkaku width == 2') },
    sub { ok(TUI::Handy::_width("\xb1", 'sjis') == 1, 'sjis hankaku katakana width == 1') },
    sub { ok(TUI::Handy::_width($euc_zen, 'euc') == 2, 'euc zenkaku width == 2') },
    sub { ok(TUI::Handy::_width($euc_han, 'euc') == 1, 'euc SS2 hankaku katakana width == 1') },
    sub { ok(TUI::Handy::_width($u_ff61, 'utf8') == 1, 'utf8 hankaku katakana U+FF61 width == 1') },
    sub { ok(TUI::Handy::_width($u_ff7f, 'utf8') == 1, 'utf8 hankaku katakana U+FF7F width == 1') },
    sub { ok(TUI::Handy::_width($u_ff80, 'utf8') == 1, 'utf8 hankaku katakana U+FF80 width == 1') },
    sub { ok(TUI::Handy::_width($u_ff9f, 'utf8') == 1, 'utf8 hankaku katakana U+FF9F width == 1') },
    sub { ok(TUI::Handy::_width($u_ff60, 'utf8') == 2, 'utf8 U+FF60 below the range stays 2') },
    sub { ok(TUI::Handy::_width($u_zen,  'utf8') == 2, 'utf8 zenkaku sharing the ef bd lead stays 2') },
    sub {
        # A lead byte at the very end of the string has no following bytes to
        # inspect; the width must still be produced, not a substr() warning.
        ok(TUI::Handy::_width("\xef", 'utf8') == 2, 'truncated utf8 lead byte does not die');
    },
    sub {
        my @c = TUI::Handy::_chars($u_ff61 . $u_ff9f, 'utf8');
        ok(scalar(@c) == 2, 'utf8 hankaku katakana splits into 2 characters');
    },
    sub {
        my @c = TUI::Handy::_chars($utf8, 'utf8');
        ok(scalar(@c) == 3, 'utf8 splits into 3 characters');
    },
    sub {
        my @c = TUI::Handy::_chars($utf8, 'utf8');
        ok($c[1] eq "\xe3\x81\x82", 'utf8 middle character is 3 bytes');
    },
    sub {
        my @c = TUI::Handy::_chars($sjis . 'X', 'sjis');
        ok(scalar(@c) == 2, 'sjis zenkaku + ascii splits into 2');
    },
    sub { ok(TUI::Handy::_is_ascii('plain') == 1, '_is_ascii true for ascii') },
    sub { ok(TUI::Handy::_is_ascii($sjis) == 0, '_is_ascii false for bytes') },
);

plan_tests(scalar(@tests));
for my $t (@tests) {
    $t->();
}
