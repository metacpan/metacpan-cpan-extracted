#!perl
#
# Tests for the bitchange function returning function.

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::Voss;

can_ok( 'Music::Voss', qw(bitchange) );

my $fun = Music::Voss::bitchange( roll => sub { defined $_[0] ? $_[0] : 0 } );

# confirm at least it produces the same wrong numbers as the LISP
# implementation (also written by me so could have similar bugs)
my @seq = map { $fun->($_) } 0 .. 9;
$deeply->( \@seq, [qw/0 1 4 5 12 13 16 17 24 25/], "some numbers");

plan tests => 2;
