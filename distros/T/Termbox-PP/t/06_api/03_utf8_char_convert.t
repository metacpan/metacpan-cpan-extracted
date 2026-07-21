use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;
binmode( Test::More->builder->failure_output(), ':utf8');
binmode( Test::More->builder->output(), ':utf8');

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox', qw(
    tb_utf8_char_length
    tb_utf8_char_to_unicode
    tb_utf8_unicode_to_char
  );
}

# -------------------------
note 'tb_utf8_char_length';
# -------------------------

subtest 'tb_utf8_char_length - edge bytes' => sub {
  plan tests => 6;

  is(tb_utf8_char_length("\x00"), 1, '00 => 1');
  is(tb_utf8_char_length("\x7F"), 1, '7F => 1');

  # Continuation bytes: must still be 1 to guarantee progress in extract
  is(tb_utf8_char_length("\x80"), 1, '80 (continuation) => 1');
  is(tb_utf8_char_length("\xBF"), 1, 'BF (continuation) => 1');

  # Invalid bytes FE/FF map to 1 in the classic table
  is(tb_utf8_char_length("\xFE"), 1, 'FE => 1');
  is(tb_utf8_char_length("\xFF"), 1, 'FF => 1');
};

# -----------------------------
note 'tb_utf8_char_to_unicode';
# -----------------------------

subtest 'tb_utf8_unicode_to_char - ASCII and Unicode widths' => sub {
  plan tests => 10;
  my ($out, $len, $ch);

  $len = tb_utf8_char_to_unicode(\$out, 'A');
  is($out, ord('A'), 'ASCII: A => U+0041');
  is($len, 1, 'ASCII: length 1');
  
  # 2-byte: é (U+00E9) => C3 A9
  utf8::encode($ch = "\x{00E9}");
  $len = tb_utf8_char_to_unicode(\$out, $ch);
  is($out, 0x00E9, '2-byte: é => U+00E9');
  is($len, 2, '2-byte: length 2');

  # 3-byte: € (U+20AC) => E2 82 AC
  utf8::encode($ch = "\x{20AC}");
  $len = tb_utf8_char_to_unicode(\$out, $ch);
  is($out, 0x20AC, '3-byte: € => U+20AC');
  is($len, 3, '3-byte: length 3');

  # 4-byte: 𐍈 (U+10348) => F0 90 8D 88
  utf8::encode($ch = "\x{10348}");
  $len = tb_utf8_char_to_unicode(\$out, $ch);
  is($out, 0x10348, '4-byte: 𐍈 => U+10348');
  is($len, 4, '4-byte: length 4');

  # NUL input: should return 0 like C (*c == '\0')
  $len = tb_utf8_char_to_unicode(\$out, "\0");
  is($len, 0, 'NUL: returns 0');
  ok(!defined($out) || $out != 0, 'NUL: out unchanged (best-effort)');
};

subtest 'tb_utf8_char_to_unicode - truncation returns negative' => sub {
  plan tests => 6;
  my ($out, $len);

  # 2-byte truncated: C3 (expected -1)
  $len = tb_utf8_char_to_unicode(\$out, "\xC3");
  is($len, -1, 'Truncated 2-byte: returns -1');

  # 3-byte truncated: E2 82 (expected -2)
  $len = tb_utf8_char_to_unicode(\$out, "\xE2\x82");
  is($len, -2, 'Truncated 3-byte: returns -2');

  # 4-byte truncated: F0 90 8D (expected -3)
  $len = tb_utf8_char_to_unicode(\$out, "\xF0\x90\x8D");
  is($len, -3, 'Truncated 4-byte: returns -3');

  # Corrupt: lead byte suggests 2, but next byte is NUL
  $len = tb_utf8_char_to_unicode(\$out, "\xC3\0");
  is($len, -1, 'NUL inside sequence: returns -1');

  # Corrupt: lead byte suggests 3, but next byte is NUL at i=1
  $len = tb_utf8_char_to_unicode(\$out, "\xE2\0\xAC");
  is($len, -1, 'Early NUL: returns -1');

  # Corrupt: lead byte suggests 3, but NUL at i=2
  $len = tb_utf8_char_to_unicode(\$out, "\xE2\x82\0");
  is($len, -2, 'Late NUL: returns -2');
};

# -----------------------------
note 'tb_utf8_unicode_to_char';
# -----------------------------

subtest 'tb_utf8_unicode_to_char - ASCII and Unicode' => sub {
  plan tests => 8;
  my ($out, $len, $ch);

  $len = tb_utf8_unicode_to_char(\$out, 0x41);
  is($out, 'A', '0x41 => ASCII A');
  is($len, 1, 'ASCII: length 1');

  utf8::encode($ch = "\x{00E9}");
  $len = tb_utf8_unicode_to_char(\$out, 0xE9);
  is($out, $ch, '0xE9 => UTF-8 é');
  is($len, 2, 'Unicode: é length 2');

  utf8::encode($ch = "\x{20AC}");
  $len = tb_utf8_unicode_to_char(\$out, 0x20AC);
  is($out, $ch, 'U+20AC => UTF-8 €');
  is($len, 3, '3-byte: length 3');

  utf8::encode($ch = "\x{10348}");
  $len = tb_utf8_unicode_to_char(\$out, 0x10348);
  is($out, $ch, 'U+10348 => UTF-8 𐍈');
  is($len, 4, '4-byte: length 4');
};

subtest 'tb_utf8_unicode_to_char - roundtrip extended range' => sub {
  plan tests => 2;
  my ($octets, $len1, $u, $len2);

  # > 0x10FFFF triggers fallback; still should roundtrip with char_to_unicode
  $len1 = tb_utf8_unicode_to_char(\$octets, 0x110000);
  ok($len1 >= 4, 'Extended: produced >= 4 octets');

  $len2 = tb_utf8_char_to_unicode(\$u, $octets);
  is($u, 0x110000, 'Extended: roundtrip keeps codepoint');
};

done_testing();
