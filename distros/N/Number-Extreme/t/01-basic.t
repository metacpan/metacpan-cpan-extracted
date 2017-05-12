use strict;
use Test::More;
use List::Util qw(shuffle);
use Number::Extreme;

my @objects = map { { high => $_ } } shuffle (1..100);
my $highest_high = Number::Extreme->max(sub { $_->{high} });

$highest_high->test($_) for @objects;

is($highest_high->current_value, 100);
is_deeply($highest_high->current, { high => 100 });

is($highest_high, 100);


done_testing;
