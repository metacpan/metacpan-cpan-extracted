use strict;
use warnings;
use Test::More;
use Switch::Declare;

# numeric exact match
is( (switch (200) { case 200 { "ok" } default { "no" } }), "ok",  "numeric match" );
is( (switch (500) { case 200 { "ok" } default { "no" } }), "no",  "numeric default" );

# string exact match
is( (switch ("GET")  { case "GET" { "g" } default { "?" } }), "g", "string match" );
is( (switch ("POST") { case "GET" { "g" } default { "?" } }), "?", "string default" );

# numeric vs string distinction
is( (switch ("0")  { case 0 { "num-zero" } default { "str" } }), "num-zero",
    "numeric == coerces string topic" );

# multiple arms, first match wins
for my $pair ([1,"a"],[2,"b"],[3,"c"],[9,"z"]) {
    my ($v, $want) = @$pair;
    my $r = switch ($v) {
        case 1 { "a" } case 2 { "b" } case 3 { "c" } default { "z" }
    };
    is( $r, $want, "multi-arm v=$v" );
}

# no match, no default -> undef
my $u = switch (42) { case 1 { "x" } };
ok( !defined $u, "no match, no default -> undef" );

# statement form (no assignment) executes the matched block
my $side;
switch ("b") { case "a" { $side = "A" } case "b" { $side = "B" } default { $side = "D" } };
is( $side, "B", "statement form runs matched block" );

done_testing;
