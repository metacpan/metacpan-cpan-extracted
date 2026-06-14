use strict;
use warnings;
use Test::More;
use Switch::Declare;

# The O(1) dispatch-table lowering (string-literal keys -> constant values,
# >= 4 arms) must be behaviourally identical to the conditional chain.

# basic many-arm lookup table
for my $pair (["a",1],["b",2],["c",3],["d",4],["e",5],["zz",-1]) {
    my ($v, $want) = @$pair;
    my $r = switch ($v) {
        case "a" { 1 } case "b" { 2 } case "c" { 3 }
        case "d" { 4 } case "e" { 5 } default { -1 }
    };
    is( $r, $want, "dispatch lookup v=$v" );
}

# miss with no default -> undef
my $u = switch ("nope") {
    case "a" { 1 } case "b" { 2 } case "c" { 3 } case "d" { 4 }
};
ok( !defined $u, "dispatch miss, no default -> undef" );

# a constant undef value is distinguished from a miss
my $hit_undef = switch ("a") {
    case "a" { undef } case "b" { 2 } case "c" { 3 } case "d" { 4 }
    default { "MISS" }
};
ok( !defined $hit_undef, "matched arm with undef value is a hit, not a miss" );
my $real_miss = switch ("z") {
    case "a" { undef } case "b" { 2 } case "c" { 3 } case "d" { 4 }
    default { "MISS" }
};
is( $real_miss, "MISS", "true miss still reaches default" );

# computed (non-constant) default in an otherwise-dispatchable switch
is( (switch ("z") {
        case "a" { 1 } case "b" { 2 } case "c" { 3 } case "d" { 4 }
        default { "D" . uc("x") }
    }), "DX", "computed default works with dispatch" );

# a non-constant arm forces the chain; side effects and order preserved
my @log;
my $r = switch ("b") {
    case "a" { 1 }
    case "b" { push @log, "b"; 2 }
    case "c" { 3 }
    case "d" { 4 }
    default  { 0 }
};
is( $r, 2, "non-const arm value" );
is( "@log", "b", "non-const arm side effect ran" );

# numeric many-arm keeps == semantics (NOT string-hash dispatch)
is( (switch ("01") { case 1 {"one"} case 2 {"two"} case 3 {"three"}
                     case 4 {"four"} default {"def"} }), "one",
    'numeric switch uses == ("01" == 1), not string dispatch' );

# duplicate keys: first match wins (dispatch declines, chain honours order)
is( (switch ("a") { case "a" {"first"} case "b" {2} case "a" {"second"}
                    case "c" {3} default {0} }), "first",
    "duplicate keys -> first wins" );

# dispatch is infix-safe and evaluated once
my $calls = 0;
sub topic { $calls++; "c" }
is( 1 + switch (topic()) {
        case "a" {10} case "b" {20} case "c" {30} case "d" {40} default {0}
    } + 1, 32, "dispatch infix-safe with expression scrutinee" );
is( $calls, 1, "expression scrutinee evaluated once under dispatch" );

done_testing;
