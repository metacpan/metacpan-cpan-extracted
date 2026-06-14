use strict;
use warnings;
use Test::More;
use Switch::Declare;

# The scrutinee may be any expression; this exercises each lowering path:
#   lexical (SDT_PAD), constant (SDT_CONST), everything else (SDT_TEMP).

# lexical
my $lex = "b";
is( (switch ($lex) { case "a" { 1 } case "b" { 2 } default { 0 } }), 2, "lexical scrutinee" );

# constant
is( (switch (3) { case 3 { "three" } default { "no" } }), "three", "constant scrutinee" );

# our / package global
our $glob = "g";
is( (switch ($glob) { case "g" { "got" } default { "no" } }), "got", "package global scrutinee" );

# $_
for ("z") {
    is( (switch ($_) { case "z" { "uz" } default { "no" } }), "uz", '$_ scrutinee' );
}

# hash element
my %h = (key => "val");
is( (switch ($h{key}) { case "val" { "hv" } default { "no" } }), "hv", "hash-element scrutinee" );

# array element
my @a = (10, 20, 30);
is( (switch ($a[1]) { case 20 { "a20" } default { "no" } }), "a20", "array-element scrutinee" );

# arithmetic expression (evaluated once into a temp)
my $calls = 0;
sub bump { $calls++; 6 }
is( (switch (bump() * 1) { case 6 { "six" } default { "no" } }), "six", "expression scrutinee" );
is( $calls, 1, "expression scrutinee evaluated exactly once" );

# method call as scrutinee
{
    package Thing;
    sub new   { bless {}, shift }
    sub kind  { "widget" }
    package main;
    my $obj = Thing->new;
    is( (switch ($obj->kind) { case "widget" { "w" } default { "no" } }), "w",
        "method-call scrutinee" );
}

# default-only with each scrutinee kind
is( (switch ("anything") { default { "D" } }), "D", "default-only, constant-ish scrutinee" );
$calls = 0;
is( (switch (bump()) { default { "D" } }), "D", "default-only, expression scrutinee" );
is( $calls, 1, "default-only still evaluates expression scrutinee once" );

done_testing;
