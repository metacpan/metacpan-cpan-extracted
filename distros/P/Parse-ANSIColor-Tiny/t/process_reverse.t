use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

sub e { note $_[0]; $_[0] }

my $p = new_ok($mod);

# simplify 'reverse' (regardless of auto_reverse option)

eq_or_diff
  [$p->process_reverse(qw(bold underline red))],
  [qw(bold underline red)],
  'no change';

eq_or_diff
  [$p->process_reverse(qw(bold underline red reverse))],
  [qw(bold underline on_red black)],
  'change preceeding fg to bg';

eq_or_diff
  [$p->process_reverse(qw(bold reverse green))],
  [qw(bold on_green black)],
  'change following fg to bg';

eq_or_diff
  [new_ok($mod, [background => 'white', foreground => 'black'])->process_reverse(qw(bold reverse green))],
  [qw(bold on_green white)],
  'change following fg to bg';

eq_or_diff
  [$p->process_reverse(qw(bold underline on_red reverse))],
  [qw(bold underline red on_white)],
  'change preceeding bg to fg';

eq_or_diff
  [$p->process_reverse(qw(bold reverse on_green))],
  [qw(bold green on_white)],
  'change following bg to fg';

eq_or_diff
  [$p->process_reverse(qw(bold on_bright_red bright_blue reverse))],
  [qw(bold bright_red on_bright_blue)],
  'swap preceeding colors, fg first';

eq_or_diff
  [$p->process_reverse(qw(bold bright_magenta on_bright_yellow reverse))],
  [qw(bold on_bright_magenta bright_yellow)],
  'swap preceeding colors';

eq_or_diff
  [$p->process_reverse(qw(bold reverse green on_blue))],
  [qw(bold on_green blue)],
  'swap following cologs';

# reverse when no colors are present

eq_or_diff
  [$p->process_reverse(qw(bold reverse))],
  [qw(bold on_white black)],
  'default colors reversed';

eq_or_diff
  [new_ok($mod, [background => 'blue'])->process_reverse(qw(bold reverse))],
  [qw(bold on_white blue)],
  'default colors (alternate bg) reversed';

eq_or_diff
  [new_ok($mod, [background => 'blue', foreground => 'red'])->process_reverse(qw(bold reverse))],
  [qw(bold on_red blue)],
  'default colors (alternate) reversed';

# auto_reverse off by default

eq_or_diff
  $p->parse(e "\033[1;4mfoo\033[7mbar"),
  [
    [ [qw(bold underline        )], 'foo' ],
    [ [qw(bold underline reverse)], 'bar' ],
  ],
  'no conversion (no colors to convert)';

eq_or_diff
  $p->parse(e "\033[1;4;31mfoo\033[7mbar"),
  [
    [ [qw(bold underline    red        )], 'foo' ],
    [ [qw(bold underline    red reverse)], 'bar' ],
  ],
  'no conversion';

eq_or_diff
  $p->parse(e "foo\033[1;31mbar\033[7mbaz\033[7mbaz\033[27mqux"),
  [
    [ [                    ], 'foo' ],
    [ [qw(bold red        )], 'bar' ],
    [ [qw(bold red reverse)], 'baz' ],
    [ [qw(bold red reverse)], 'baz' ],
    [ [qw(bold red        )], 'qux' ],
  ],
  'double-reverse has no effect';

eq_or_diff
  $p->parse(e "\e[32;105mfoo\033[1;7mbar\033[34mbaz\033[27mqux"),
  [
    [ [qw(green on_bright_magenta        )], 'foo' ],
    [ [qw(green on_bright_magenta bold reverse)], 'bar' ],
    [ [qw(on_bright_magenta bold reverse blue )], 'baz' ],
    [ [qw(on_bright_magenta bold blue )], 'qux' ],
  ],
  'bg and fg reversed';

eq_or_diff
  $p->parse(e " none \033[31m redfg \033[7m redbg \033[7m same \e[34m bluebg \e[27m bluefg \e[7m bluebg \e[m none \e[31m r "),
  [
    [ [                ], ' none '   ],
    [ [qw(red         )], ' redfg '  ],
    [ [qw(red  reverse)], ' redbg '  ],
    [ [qw(red  reverse)], ' same '   ],
    [ [qw(reverse blue)], ' bluebg ' ],
    [ [qw(blue        )], ' bluefg ' ],
    [ [qw(blue reverse)], ' bluebg ' ],
    [ [                ], ' none '   ],
    [ [qw(red         )], ' r '      ],
  ],
  'longer, very clear example';

# reverse automatically when enabled

$p = new_ok($mod, [auto_reverse => 1]);

eq_or_diff
  $p->parse(e "\033[1;4mfoo\033[7mbar"),
  [
    [ [qw(bold underline               )], 'foo' ],
    [ [qw(bold underline on_white black)], 'bar' ],
  ],
  'auto-reverse default colors';

eq_or_diff
  $p->parse(e "\033[1;4;31mfoo\033[7mbar"),
  [
    [ [qw(bold underline    red      )], 'foo' ],
    [ [qw(bold underline on_red black)], 'bar' ],
  ],
  'auto-reverse fg color';

eq_or_diff
  $p->parse(e "foo\033[1;31mbar\033[7mbaz\033[7mbaz\033[27mqux"),
  [
    [ [                     ], 'foo' ],
    [ [qw(bold red         )], 'bar' ],
    [ [qw(bold on_red black)], 'baz' ],
    [ [qw(bold on_red black)], 'baz' ],
    [ [qw(bold red         )], 'qux' ],
  ],
  'double-reverse has no effect';

eq_or_diff
  $p->parse(e "\e[32;105mfoo\033[1;7mbar\033[34mbaz\033[27mqux"),
  [
    [ [qw(   green on_bright_magenta     )], 'foo' ],
    [ [qw(on_green    bright_magenta bold)], 'bar' ],
    [ [qw(   bright_magenta bold on_blue )], 'baz' ],
    [ [qw(on_bright_magenta bold    blue )], 'qux' ],
  ],
  'bg and fg reversed';

eq_or_diff
  $p->parse(e " none \033[31m redfg \033[7m redbg \033[7m same \e[34m bluebg \e[27m bluefg \e[7m bluebg \e[m none \e[31m r "),
  [
    [ [                 ], ' none '   ],
    [ [qw(red          )], ' redfg '  ],
    [ [qw(on_red  black)], ' redbg '  ],
    [ [qw(on_red  black)], ' same '   ],
    [ [qw(on_blue black)], ' bluebg ' ],
    [ [qw(blue         )], ' bluefg ' ],
    [ [qw(on_blue black)], ' bluebg ' ],
    [ [                 ], ' none '   ],
    [ [qw(red          )], ' r '      ],
  ],
  'longer, very clear example';

done_testing;
