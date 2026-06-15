use strict;
use warnings;
use Test::More;
use Switch::Declare;

# Numeric patterns (number literal, range, numeric list element) only match a
# topic that really is a number. A non-numeric (or undef) topic neither matches
# nor warns - so `switch("one"){ case 1 {...} }` is silent, and the old
# `"one" == 0` mis-match is gone. Whole file runs under `use warnings` with a
# zero-warning assertion.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# the originally-reported warning case
is( (switch ("one") { case 1 { "one" } default { "D" } }), "D",
    "non-numeric string does not match a numeric case (no warning)" );

# the latent bug: "one" == 0 used to be true and matched case 0
is( (switch ("one") { case 0 { "zero" } default { "D" } }), "D",
    'non-numeric string no longer mis-matches case 0' );

# genuine numbers still match
is( (switch (1)   { case 1 { "one" } default { "D" } }), "one", "integer matches" );
is( (switch (0)   { case 0 { "zero" } default { "D" } }), "zero", "zero matches" );
is( (switch (3.5) { case 3.5 { "pi-ish" } default { "D" } }), "pi-ish", "float matches" );

# numeric strings are numbers for == purposes
is( (switch ("1")    { case 1 { "one" } default { "D" } }), "one", "numeric string '1' matches case 1" );
is( (switch (" 42 ") { case 42 { "n" } default { "D" } }), "n", "whitespace-padded numeric string matches" );

# ranges and numeric lists are guarded the same way
is( (switch ("x") { case [1 .. 9]  { "g" } default { "D" } }), "D", "range: non-numeric -> default" );
is( (switch ("x") { case [1, 2, 3] { "l" } default { "D" } }), "D", "numeric list: non-numeric -> default" );
is( (switch (5)   { case [1 .. 9]  { "g" } default { "D" } }), "g", "range still matches a number" );
is( (switch (2)   { case [1, 2, 3] { "l" } default { "D" } }), "l", "numeric list still matches a number" );

# a mixed list: the string element still matches by eq, no warning
is( (switch ("two") { case [1, "two", 3] { "in" } default { "out" } }), "in",
    "mixed list: string element matches without warning" );

# multi-arm numeric switch over a variable (exercises the hoisted guard) and
# evaluates the scrutinee exactly once
{
    my $calls = 0;
    my $topic = sub { $calls++; "not a number" };
    my $r = switch ($topic->()) {
        case 1 { "a" } case 2 { "b" } case [3 .. 4] { "cd" } default { "D" }
    };
    is( $r, "D", "multi-arm numeric switch: non-numeric expression -> default" );
    is( $calls, 1, "scrutinee evaluated exactly once under the hoisted guard" );
}

is_deeply( \@warnings, [], "numeric guard produced no warnings" )
    or diag("unexpected warnings:\n", @warnings);

done_testing;
