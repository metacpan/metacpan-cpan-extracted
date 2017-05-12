#!perl
#
# Tests for the bitchange function returning function.

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::Voss;

can_ok('Music::Voss', qw(bitchange));

# TODO actual tests
#my $fun = Music::Voss::bitchange( roll => sub { defined $_[0] ? $_[0] : 0 } );
#
#for my $x (0..21) {
#  diag sprintf "%d %d", $x, $fun->($x);
#}

plan tests => 1;
