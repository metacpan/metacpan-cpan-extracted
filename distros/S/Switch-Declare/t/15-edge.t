use strict;
use warnings;
use Test::More;
use Switch::Declare;

# --- number literal forms ----------------------------------------------
is( (switch (-5)   { case -5   { "neg" }  default { "no" } }), "neg", "negative literal" );
is( (switch (5)    { case +5   { "pos" }  default { "no" } }), "pos", "explicit-plus literal" );
is( (switch (3.14) { case 3.14 { "pi" }   default { "no" } }), "pi",  "float literal" );
is( (switch (1000) { case 1e3  { "k" }    default { "no" } }), "k",   "exponent literal" );
is( (switch (0)    { case 0    { "zero" } default { "no" } }), "zero","zero literal" );

# --- string literal forms ----------------------------------------------
is( (switch ("a\tb") { case "a\tb" { "tab" } default { "no" } }), "tab", "double-quote escape \\t" );
is( (switch ("a\\b") { case 'a\b'  { "bs" }  default { "no" } }), "bs",  "single-quote literal backslash" );
is( (switch ("")     { case ""     { "empty" } default { "no" } }), "empty", "empty string literal" );

# --- regex flags & quantifiers -----------------------------------------
is( (switch ("ab12cd") { case /\d{2,4}/ { "q" } default { "no" } }), "q", "regex quantifier {2,4}" );
is( (switch ("A")  { case /a/i      { "i" } default { "no" } }), "i", "flag i" );
is( (switch ("a\nb") { case /^b$/m  { "m" } default { "no" } }), "m", "flag m" );
is( (switch ("a\nb") { case /a.b/s  { "s" } default { "no" } }), "s", "flag s" );
is( (switch ("abc") { case / a b c /x { "x" } default { "no" } }), "x", "flag x" );
is( (switch ("ABC") { case /^abc$/im { "im" } default { "no" } }), "im", "combined flags im" );

# --- range edge cases --------------------------------------------------
is( (switch (5)  { case [5 .. 5]  { "pt" } default { "no" } }), "pt", "single-point range" );
is( (switch (5)  { case [10 .. 1] { "in" } default { "out" } }), "out", "reversed range never matches" );
is( (switch (-3) { case [-5 .. -1] { "in" } default { "out" } }), "in", "negative range" );

# --- list edge cases ---------------------------------------------------
is( (switch (3) { case [1, 2, 3,] { "in" } default { "out" } }), "in", "trailing comma in list" );
is( (switch (9) { case [1] { "one" } default { "no" } }), "no", "single-element list miss" );

# mixed-type list works (warns like a hand-written || chain; we just want the value)
{
    local $SIG{__WARN__} = sub { };  # silence the numeric-compare warning
    is( (switch ("two") { case [1, "two", 3] { "in" } default { "out" } }), "in",
        "mixed-type list membership" );
}

# --- predicate forms ---------------------------------------------------
sub is_big { $_[0] > 100 }
is( (switch (150) { case \&is_big { "big" } default { "small" } }), "big", "predicate" );

# forward-referenced predicate (resolved at run time)
is( (switch (5) { case \&defined_later { "L" } default { "D" } }), "L", "forward-ref predicate" );
sub defined_later { $_[0] == 5 }

# package-qualified predicate
{
    package Pkg; sub even { $_[0] % 2 == 0 } package main;
    is( (switch (4) { case \&Pkg::even { "e" } default { "o" } }), "e",
        "package-qualified predicate" );
}

# predicate truthiness: any false value -> no match
sub falsy { return 0 }
is( (switch (1) { case \&falsy { "y" } default { "n" } }), "n", "false predicate -> default" );

done_testing;
