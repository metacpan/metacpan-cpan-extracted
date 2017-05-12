#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Object::Array qw(Array);

my $arr = Array;
isa_ok($arr, 'Object::Array');
isa_ok($arr, 'ARRAY');

is $arr->size, 0, 'size method';
is @{$arr}, 0, 'size deref';

is $arr->push(qw(a b c)), 3, 'push method';
is $arr->size, 3, 'size after push method';

is_deeply(
  [ [ @{ $arr } ], [ $arr->elements ] ],
  [ [ qw(a b c) ], [ qw(a b c) ] ],
  'all method, all deref',
);

is_deeply(
  [ $arr->slice([ 1, 2 ]) ],
  [ qw(b c) ],
  'slice method get',
);

is $arr->join("."), "a.b.c", "join method";

$arr->slice([ 2, 3 ], [ qw(f d) ]);
is($arr->[2], 'f', 'deref get after slice method set');

is(
  $arr->grep(sub { $_ ne "a" })->join(", "),
  "b, f, d",
  "chained grep and join",
);

$arr->[2] = "c";

is $arr->element(3), 'd', 'method get after slice set';
is $arr->element(2), 'c', 'method get after deref set';
is $#{$arr}, 3, 'last element deref';

is $arr->shift, "a", 'shift method';
is shift(@{$arr}), "b", 'shift builtin';

is $arr->pop, "d", 'pop method';
is pop(@{$arr}), "c", 'pop builtin';

@{$arr}[2,3] = qw(g h);

ok ! $arr->exists(0), 'exists method';
ok ! exists $arr->[1], 'exists builtin';

delete $arr->[2];
$arr->delete(3);

is $arr->size, 0, 'size after delete method/builtin';

$arr->push(1);
is $arr->size, 1, 'size after push method';

@{ $arr } = ();
is $arr->size, 0, 'size after deref clear';

my @orig = qw(a b c);
$arr = Array(\@orig);

is $arr->[0], "a", 'deref get';
is $arr->pop, "c", 'pop method';

is_deeply(
  \@orig,
  [ qw(a b) ],
  'original array',
);

is_deeply(
  [ $arr->grep(sub { defined }) ],
  [ qw(a b) ],
  'grep method',
);

is_deeply(
  [ grep { defined } @$arr ],
  [ qw(a b) ],
  'grep deref',
);

is_deeply(
  [ map { ++$_ } $arr->elements ],
  [ qw(b c) ],
  'map deref',
);

is $arr->map(sub { ++$_ })->[-1], "c", 'map method chained';
