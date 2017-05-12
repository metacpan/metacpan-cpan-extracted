use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

plan skip_all => 'Term::ANSIColor required for these tests'
  unless eval 'require Term::ANSIColor';

use Parse::ANSIColor::Tiny;
my $p = new_ok('Parse::ANSIColor::Tiny');

# in order to match exact output from colored()
# we need to end each chunk with a 'clear' (colored() always ends with a clear)
# plus attributes are not inherited across calls so we need to repeat them
my $text = <<OUTPUT;
I've got a \e[1;33mlovely \e[0m\e[1;32mbunch\033[0m of coconuts.
I want to be \033[34ma \e[0m\e[34;4mmighty \e[0m\e[34;4;45mpirate\e[0m.
OUTPUT

my $parsed = $p->parse($text);

my $exp = [
    [ [], "I\'ve got a " ],
    [ ['bold', 'yellow'], 'lovely ' ],
    [ ['bold', 'green'], 'bunch'],
    [ [], " of coconuts.\nI want to be " ],
    [ ['blue'], 'a ' ],
    [ ['blue', 'underline'], 'mighty ' ],
    [ ['blue', 'underline', 'on_magenta'], 'pirate' ],
    [ [], ".\n" ],
  ];

eq_or_diff
  $parsed,
  $exp,
  'parsed output';

# don't pass empty attributes ( [ [], 'str' ] ) through colored()
# to avoid 'uninitialized' warnings
my $colored = join '',
  map { @{ $_->[0] } ? Term::ANSIColor::colored(@$_) : $_->[1] }
  @$parsed;

note $text, $colored;

eq_or_diff
  $colored,
  $text,
  'round-trip through Term::ANSIColor produced identical output';

eq_or_diff
  $p->parse($colored),
  $exp,
  'parsed the output of colored() and got the same';

eq_or_diff
  $p->parse( Term::ANSIColor::colored( [qw(bold blue underline)], 'bbu' ) ),
  [
    [ [qw(bold blue underline)], 'bbu' ],
  ],
  'parse return of simple colored() call';

done_testing;
