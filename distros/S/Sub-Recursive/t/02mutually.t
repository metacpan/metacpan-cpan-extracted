use Test::More tests => 1 + 3;
BEGIN { require_ok('Sub::Recursive') };

#########################

use strict;

BEGIN { use_ok('Sub::Recursive', qw/ mutually_recursive %REC /) }

my ($odd, $even) = mutually_recursive(
    odd  => sub { $_[0] == 0 ? 0 : $REC{even}->($_[0] - 1) },
    even => sub { $_[0] == 0 ? 1 : $REC{odd }->($_[0] - 1) },
);

my @odd  = map $odd ->($_), 1 .. 10;
my @even = map $even->($_), 1 .. 10;

is_deeply(\@odd , [ 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 ], 'odd');
is_deeply(\@even, [ 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 ], 'even');
