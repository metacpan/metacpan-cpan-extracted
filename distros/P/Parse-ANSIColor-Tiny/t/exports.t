use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

use Parse::ANSIColor::Tiny map { "${_}_ansicolor" } qw( identify normalize parse );

eq_or_diff
  [ identify_ansicolor(qw(1;31 104)) ],
  [ qw(bold red on_bright_blue) ],
  'identify_ansicolor exported and working';

eq_or_diff
  [ normalize_ansicolor(qw( bold blue clear red underline on_blue green )) ],
  [ qw(underline on_blue green) ],
  'normalize_ansicolor exported and working';

eq_or_diff
  parse_ansicolor("\e[31myo\e[32mho\e[33mho"),
  [
    [ ['red'   ], 'yo' ],
    [ ['green' ], 'ho' ],
    [ ['yellow'], 'ho' ],
  ],
  'identify_ansicolor exported and working';

my $mod = 'Parse::ANSIColor::Tiny';
is eval qq{ use $mod 'identify'; 1; }, undef, 'eval died for bad export';
like $@, qr/'identify' is not exported by $mod/, 'error message mentions bad export';

done_testing;
