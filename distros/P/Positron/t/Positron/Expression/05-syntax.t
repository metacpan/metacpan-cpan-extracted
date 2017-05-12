#!/usr/bin/perl

# Test syntax hardening

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dump qw( pp );

BEGIN {
    require_ok('Positron::Expression');
}

throws_ok { Positron::Expression::parse('0 blargh'); } qr{Superfluous text}, "Superfluous text";

dies_ok { Positron::Expression::parse('?"'); } "Nonsense";

dies_ok { Positron::Expression::parse('1 ? '); } "Dangling AND";

# A few smoke tests
lives_and{ is_deeply(Positron::Expression::parse( '(((((($a ? $a ? $a ? $a ))))))' ), [
  "expression",
  ["env", ["env", "a"]],
  "?",
  ["env", ["env", "a"]],
  "?",
  ["env", ["env", "a"]],
  "?",
  ["env", ["env", "a"]],
]); } "Nested parentheses";
lives_and{ is_deeply(Positron::Expression::parse( 'func.call("a simple string",3).this(dollar.$lterm) ? (!a : b) : $$deep', ), [
  "expression",
  [
    "dot",
    ["env", "func"],
    ["methcall", "call", "a simple string", 3],
    [
      "methcall",
      "this",
      ["dot", ["env", "dollar"], ["env", "lterm"]],
    ],
  ],
  "?",
  ["expression", ["not", ["env", "a"]], ":", ["env", "b"]],
  ":",
  ["env", ["env", ["env", "deep"]]],
]
); } "Long expression";

lives_and{ is(Positron::Expression::parse(q{"hello"}), q{hello}); } "Complete string";
throws_ok {
    Positron::Expression::parse(q{"hello});
} qr{Missing string delimiter}, "Incomplete string (beginning)t";
throws_ok {
    Positron::Expression::parse(q{hello"});
} qr{Superfluous text}, "Incomplete string (end)";

throws_ok {
    Positron::Expression::parse(q{!});
} qr{Operand expected}, "Lonely NOT";

throws_ok {
    Positron::Expression::parse(q{(a});
} qr{Unbalanced parentheses}, "Unbalanced parentheses in lterm";

throws_ok {
    Positron::Expression::parse(q{ f(a b) });
} qr{Need commas}, "Argument list without commas in funccall";

throws_ok {
    Positron::Expression::parse(q{ f(a, b });
} qr{Unbalanced parentheses}, "Argument list without closing parenthesis";

throws_ok {
    Positron::Expression::parse(q{ a.$ });
} qr{Term expected}, 'Missing lterm after $ in rterm';

throws_ok {
    Positron::Expression::parse(q{ a. (b });
} qr{Unbalanced parentheses}, "Unbalanced parentheses in rterm";

throws_ok {
    Positron::Expression::parse(q{ obj.f(a b) });
} qr{Need commas}, "Argument list without commas in methcall";

throws_ok {
    Positron::Expression::parse(q{ ++ });
} qr{Invalid number}, "Double plus";

throws_ok {
    Positron::Expression::parse(q{ + 1 });
} qr{Invalid number}, "Space in numbers";

throws_ok {
    Positron::Expression::parse(q{ 1. });
} qr{Superfluous text}, "Nothing following period";

throws_ok {
    Positron::Expression::parse(q{ 1..2 });
} qr{Superfluous text}, "Double period";

throws_ok {
    Positron::Expression::parse(q{ a.++ });
} qr{Invalid integer}, "Double plus in integer";

throws_ok {
    Positron::Expression::parse(q{ a.- });
} qr{Invalid integer}, "Lonely minus in integer";

done_testing();
