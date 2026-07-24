use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;
# use Test::More::UTF8 qw( failure out );
binmode( Test::More->builder->failure_output(), ':utf8');
binmode( Test::More->builder->output(), ':utf8');

BEGIN {
  require_ok 'Termbox::PP';
  use_ok 'Termbox';
  use_ok 'Terminal::WCWidth';
}

*wcwidth = Termbox::TB_OPT_LIBC_WCHAR 
         ? \&Termbox::wcwidth 
         : \&Terminal::WCWidth::wcwidth;

note "Using ", Termbox::TB_OPT_LIBC_WCHAR 
            ? "Termbox::wcwidth()" 
            : "Terminal::WCWidth::wcwidth()";

sub assert_length {
  my ($str, $each, $phrase, $msg) = @_;
  $msg ||= "wcwidth test";
  my @actual_each = map { wcwidth(ord $_) } split(//, $str);
  is_deeply \@actual_each, $each,
    "$msg: $str expects @$each and gets @actual_each";
}

assert_length("コンニチハ, セカイ!",
  [2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1],
  19,
  "Width of Japanese phrase: コンニチハ, セカイ!"
);
assert_length("abc\0def",
  [1, 1, 1, 0, 1, 1, 1],
  6,
  "NULL (0) should report width 0."
);
assert_length("\x1b[0m",
  [-1, 1, 1, 1],
  -1,
  "CSI should report width -1."
);
assert_length("--\x{05bf}--",
  [1, 1, 0, 1, 1],
  4,
  "Simple combining character test."
);
# café test not done since Perl6 will inevitably mess it up
assert_length("\x{0410}\x{0488}",
  [1, 0],
  1,
  "CYRILLIC CAPITAL LETTER A + COMBINING CYRILLIC " .
    "HUNDRED THOUSANDS SIGN is А҈ of length 1."
);
assert_length("\x{1b13}\x{1b28}\x{1b2e}\x{1b44}",
  [1, 1, 1, 1],
  4,
  "Balinese kapal (ship) is ᬓᬨᬮ᭄ of length 4."
);

done_testing;
