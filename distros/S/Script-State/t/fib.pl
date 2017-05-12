use strict;
use Script::State;
use Data::Dumper;

$Data::Dumper::Terse = 1;

script_state my $x = 1;
script_state my $y = 1;

print $x;

($x, $y) = ($y, $x + $y);
