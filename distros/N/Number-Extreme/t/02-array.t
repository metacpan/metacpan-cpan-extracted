use strict;
use Test::More;
use List::Util qw(shuffle);
use Number::Extreme;

my @array = shuffle (1..100);

my $which;
for (0..99) {
    $which = $_ if $array[$_] == 100;
}

my $high = Number::Extreme->amax(\@array);
$high->test($_) for(0..99);
is($high->current_value, 100);

is($high->current, $which);


done_testing;
