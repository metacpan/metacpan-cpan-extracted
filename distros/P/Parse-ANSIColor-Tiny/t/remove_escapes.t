use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

{
  chomp(my $other_escapes = <<ESC);
\033[1A\033[2KPhantomJS 1.9.7 (Linux): Executed 5 of 10\033[32m SUCCESS\033[39m (0 secs / 0.066 secs)\033[0m
ESC

  eq_or_diff
    $p->parse($other_escapes),
    [
      [ [       ], 'PhantomJS 1.9.7 (Linux): Executed 5 of 10' ],
      [ ['green'], ' SUCCESS' ],
      [ [       ], ' (0 secs / 0.066 secs)' ],
    ],
    'removed screen/cursor escape sequences';

  eq_or_diff
    new_ok($mod, [remove_escapes => 0])->parse($other_escapes),
    [
      [ [       ], "\e[1A\e[2KPhantomJS 1.9.7 (Linux): Executed 5 of 10" ],
      [ ['green'], " SUCCESS" ],
      [ [       ], " (0 secs / 0.066 secs)" ],
    ],
    'retained screen/cursor escape sequences as configured';

  eq_or_diff
    $p->parse("\e[xFoo\e[31mBar\e[mBaz"),
    [
      [ [     ], 'Foo' ],
      [ ['red'], 'Bar' ],
      [ [     ], 'Baz' ],
    ],
    'parse escape sequences without a number removal';
}


{
  # Tests adapted from Taiki Kawakami's pull request.
  # https://github.com/rwstauner/HTML-FromANSI-Tiny/pull/2/files
  eq_or_diff
    $p->parse("\e[2j\e[2Jfoo"),
    [
      [ [], q[foo], ],
    ],
    'with escape sequence to clear screen';

  eq_or_diff
    $p->parse("\e[0k\e[0K\e[1k\e[1K\e[2k\e[2Kfoo"),
    [
      [ [], q[foo], ],
    ],
    'with escape sequence to clear row';

  eq_or_diff
    $p->parse("\e[1;2h\e[10;20Hfoo"),
    [
      [ [], q[foo], ],
    ],
    'with escape sequence to move cursor by lengthwise and crosswise';

  eq_or_diff
    $p->parse("\e[10a\e[10A\e[10b\e[10B\e[10c\e[10C\e[10d\e[10Dfoo"),
    [
      [ [], q[foo], ],
    ],
    'with escape sequence to move cursor';
}

done_testing;
