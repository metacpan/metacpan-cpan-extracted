use strict;
use warnings;

use Test::More tests => 9;
use Moose::Autobox;

my $array = [ qw(1 2 3 4 ) ];
is_deeply(
  [ $array->flatten ],
  [ 1, 2, 3, 4 ],
  "flattening an array returns a list",
);

my $hash = { a => 1, b => 2 };
is_deeply(
  [ sort $hash->flatten ],
  [ qw(1 2 a b) ],
  "flattening a hash returns a list",
);

my $scalar = 1;
is_deeply(
  [ $scalar->flatten ],
  [ 1 ],
  "flattening a scalar returns the scalar",
);

my $scalar_ref = \$scalar;
is_deeply(
  [ $scalar_ref->flatten ],
  [ \$scalar ],
  "flattening a reference to a scalar returns the same scalar reference",
);

# flatten_deep on array
is_deeply(
  [ 1 .. 9 ]->flatten_deep,
  [ 1 .. 9 ],
 "default flatten_deep on shallow array returns correct array"
);

is_deeply(
  [ [ 1 .. 3 ], [[ 4 .. 6 ]], [[[ 7 .. 9 ]]] ]->flatten_deep,
  [ 1 .. 9 ],
  "default flatten_deep on array with depth completely flattens array"
);

is_deeply(
  [ [ 1 .. 3 ], [[ 4 .. 6 ]], [[[ 7 .. 9 ]]] ]->flatten_deep(undef),
  [ 1 .. 9 ],
  "flatten_deep with an undef argument on array with depth completely flattens array"
);

is_deeply(
  [ [ 1 .. 3 ], [[ 4 .. 6 ]], [[[ 7 .. 9 ]]] ]->flatten_deep(0),
  [ [ 1 .. 3 ], [[ 4 .. 6 ]], [[[ 7 .. 9 ]]] ],
  "flatten_deep with depth 0 specified on array returns array unchanged"
);

is_deeply(
  [ [ 1 .. 3 ], [[ 4 .. 6 ]], [[[ 7 .. 9 ]]] ]->flatten_deep(2),
  [ 1 .. 6, [ 7 .. 9 ] ],
  "flatten_deep with depth specified returns correct array"
);
