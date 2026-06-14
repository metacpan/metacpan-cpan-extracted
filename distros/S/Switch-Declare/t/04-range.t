use strict;
use warnings;
use Test::More;
use Switch::Declare;

my @cases = (399=>"out", 400=>"in", 450=>"in", 499=>"in", 500=>"out");
while (@cases) {
    my ($v, $want) = splice @cases, 0, 2;
    my $r = switch ($v) { case [400 .. 499] { "in" } default { "out" } };
    is( $r, $want, "numeric range v=$v" );
}

# inclusive boundaries, negative and float bounds
is( (switch (-5) { case [-10 .. 0] { "neg" } default { "no" } }), "neg", "negative range" );
is( (switch (1.5) { case [1.0 .. 2.0] { "mid" } default { "no" } }), "mid", "float range" );

# tight no-space form
is( (switch (5) { case [1..10] { "y" } default { "n" } }), "y", "no-space range" );

# string range
is( (switch ("c") { case ["a" .. "m"] { "early" } default { "late" } }),
    "early", "string range" );

done_testing;
