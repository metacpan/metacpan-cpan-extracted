use strict;
use warnings;
use Test::More;
use Switch::Declare;

# An undef scrutinee is handled in the generated code, not by silencing
# warnings at the call site. The rules:
#
#   * `case undef { ... }` matches if and only if the scrutinee is undef.
#   * Every other pattern (number/string/regex/range/list/predicate) is guarded
#     so it neither matches nor warns on undef.
#   * An undef scrutinee not caught by a `case undef` falls through to default.
#
# Crucially: this whole file runs under `use warnings` with NO local
# suppression - an undef scrutinee must be warning-free.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $undef = undef;

# --- case undef matches undef ------------------------------------------
is( (switch ($undef) {
        case undef { "UNDEF" }
        case 1     { "one"   }
        default    { "D"     }
    }), "UNDEF", "case undef matches an undef scrutinee" );

# --- case undef does NOT match a defined value -------------------------
is( (switch (0) {
        case undef { "UNDEF" }
        case 0     { "zero"  }
        default    { "D"     }
    }), "zero", "case undef is skipped when the scrutinee is defined (even 0)" );

is( (switch ("") {
        case undef { "UNDEF" }
        case ""    { "empty" }
        default    { "D"     }
    }), "empty", "case undef is skipped for the empty string" );

# --- without a case undef, undef falls through to default --------------
is( (switch ($undef) {
        case 0     { "zero"  }   # would have matched undef under == before
        case ""    { "empty" }   # would have matched undef under eq before
        case /^$/  { "blank" }   # would have matched undef as "" before
        default    { "DEF"   }
    }), "DEF", "undef matches no value pattern and falls to default" );

# --- value patterns of every kind are undef-safe -----------------------
is( (switch ($undef) { case 42        { "n" } default { "D" } }), "D", "number pattern: no undef match" );
is( (switch ($undef) { case "x"       { "s" } default { "D" } }), "D", "string pattern: no undef match" );
is( (switch ($undef) { case /foo/     { "r" } default { "D" } }), "D", "regex pattern: no undef match" );
is( (switch ($undef) { case [1 .. 9]  { "g" } default { "D" } }), "D", "range pattern: no undef match" );
is( (switch ($undef) { case [1, 2, 3] { "l" } default { "D" } }), "D", "list pattern: no undef match" );

# predicates are not called for an undef scrutinee (undef is handled first)
{
    my $called = 0;
    my $r = switch ($undef) {
        case sub { $called++; 1 } { "pred" }
        default                   { "D"    }
    };
    is( $r, "D", "predicate pattern: no undef match" );
    is( $called, 0, "predicate is not even called for an undef scrutinee" );
}

# --- dispatch mode (>= 4 string->constant arms) is undef-safe too ------
is( (switch ($undef) {
        case "a" { 1 } case "b" { 2 } case "c" { 3 } case "d" { 4 }
        default  { "D" }
    }), "D", "dispatch mode: undef topic misses table -> default" );

is( (switch ("c") {
        case "a" { 1 } case "b" { 2 } case "c" { 3 } case "d" { 4 }
        default  { "D" }
    }), 3, "dispatch mode: a defined topic still hits" );

# a case undef alongside many string arms (this drops out of dispatch mode
# back to a chain, but must still behave)
is( (switch ($undef) {
        case "a" { 1 } case "b" { 2 } case "c" { 3 } case "d" { 4 }
        case undef { "NULL" }
        default  { "D" }
    }), "NULL", "case undef works alongside many string arms" );

# --- defined scrutinees are completely unaffected ----------------------
is( (switch (5) { case undef { "U" } case 5 { "five" } default { "D" } }), "five",
    "defined chain still matches normally with a case undef present" );

# --- the scrutinee is still evaluated exactly once when undef ----------
{
    my $calls = 0;
    my $maker = sub { $calls++; return undef };
    my $r = switch ($maker->()) {
        case undef { "U" }
        case 1     { "one" }
        default    { "D" }
    };
    is( $r, "U", "undef-returning expression scrutinee matches case undef" );
    is( $calls, 1, "undef-returning scrutinee evaluated exactly once" );
}

# --- and the headline: no warnings were produced anywhere above --------
is_deeply( \@warnings, [], "an undef scrutinee produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
