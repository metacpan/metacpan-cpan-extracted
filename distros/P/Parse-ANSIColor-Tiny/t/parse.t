use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

sub e { note $_[0]; $_[0] }

my $p = new_ok($mod);

eq_or_diff
  $p->parse(e "foo\033[31mbar\033[00m"),
  [
    [ [     ], 'foo' ],
    [ ['red'], 'bar' ],
  ],
  'parsed simple color';

eq_or_diff
  $p->parse(e "foo\033[01;31mbar\033[33mbaz\033[00m"),
  [
    [ [                ], 'foo' ],
    [ ['bold', 'red'   ], 'bar' ],
    [ ['bold', 'yellow'], 'baz' ],
  ],
  'bold attribute inherited';

eq_or_diff
  $p->parse(e <<OUTPUT),
I've got a \e[01;33mlovely \e[32mbunch\033[0m of coconuts.
I want to be \033[34ma \e[4mmighty \e[45mpirate\e[0m.
OUTPUT
  [
    [ [], "I\'ve got a " ],
    [ ['bold', 'yellow'], 'lovely ' ],
    [ ['bold', 'green'], 'bunch'],
    [ [], " of coconuts.\nI want to be " ],
    [ ['blue'], 'a ' ],
    [ ['blue', 'underline'], 'mighty ' ],
    [ ['blue', 'underline', 'on_magenta'], 'pirate' ],
    [ [], ".\n" ],
  ],
  'parsed output';

eq_or_diff
  $p->parse(e "foo\033[31mbar\033[mbaz\033[32mqu\e[42;mx"),
  [
    [ [       ], 'foo' ],
    [ ['red'  ], 'bar' ],
    [ [       ], 'baz' ],
    [ ['green'], 'qu' ],
    [ [       ], 'x' ],
  ],
  'no numbers at all means zero/clear';

my $rev_then_blank = e "foo\033[01;31mbar\033[07m\033[32mbaz\033[00m";

eq_or_diff
  $p->parse($rev_then_blank),
  [
    [ [                 ], 'foo' ],
    [ [qw(bold red)     ], 'bar' ],
    [ [qw(bold reverse green)], 'baz' ],
  ],
  '"reverse" sequence carried across empty string';

eq_or_diff
  new_ok($mod, [auto_reverse => 1])->parse($rev_then_blank),
  [
    [ [                       ], 'foo' ],
    [ [qw(bold red           )], 'bar' ],
    [ [qw(bold on_green black)], 'baz' ],
  ],
  '"reverse" sequence carried across empty string with auto_reverse';

done_testing;
