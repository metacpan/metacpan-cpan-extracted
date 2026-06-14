use strict;
use warnings;
use Test::More;
use Switch::Declare;

# Exercises the three lowering paths and their boundaries:
#   * plain lexical/const scrutinee + simple arms  -> bare conditional
#   * multi-statement arm                          -> single enclosing scope
#   * non-trivial scrutinee                        -> evaluate-once temp

# --- infix / sub-expression use (bare-conditional path) ----------------
my $v = 2;
is( 100 + switch ($v) { case 2 { 40 } default { 0 } }, 140, "N + switch" );
is( 1 + switch ($v) { case 2 { 40 } default { 0 } } + 1, 42, "N + switch + N" );
is( (switch ($v) { case 2 { 40 } default { 0 } }) * 2, 80, "switch * N" );

# constant scrutinee
is( 5 + switch (3) { case 3 { 10 } default { 0 } }, 15, "const scrutinee infix" );

# --- multi-statement arm (scoped path) ---------------------------------
my $r = switch (1) {
    case 1 { my $x = 10; my $y = 4; $x * $y }
    default { 0 }
};
is( $r, 40, "multi-statement arm value" );
is( 1000 + switch (1) { case 1 { my $t = 5; $t + 1 } default { 0 } }, 1006,
    "multi-statement arm is infix-safe" );

# multiple arms each declaring the same lexical must not warn or collide
my $warn = "";
local $SIG{__WARN__} = sub { $warn .= $_[0] };
my $m = switch (2) {
    case 1 { my $z = "a"; $z }
    case 2 { my $z = "b"; $z }
    default { my $z = "c"; $z }
};
is( $m, "b", "per-arm lexical scoping" );
is( $warn, "", "no redeclaration warnings across arms" );

# --- non-trivial scrutinee (evaluate-once temp path) -------------------
my $calls = 0;
sub topic { $calls++; 7 }
is( 1 + switch (topic()) { case 7 { 70 } default { 0 } } + 1, 72,
    "expression scrutinee infix-safe" );
is( $calls, 1, "expression scrutinee evaluated exactly once" );

done_testing;
