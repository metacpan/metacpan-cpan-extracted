use strict;
use warnings;
use Test::More;
use Switch::Declare;

sub is_even { $_[0] % 2 == 0 }
sub is_big  { $_[0] > 100 }

is( (switch (2) { case \&is_even { "even" } default { "odd" } }), "even", "predicate true" );
is( (switch (3) { case \&is_even { "even" } default { "odd" } }), "odd",  "predicate false" );

# predicate receives the topic as its argument
my $seen;
sub spy { $seen = $_[0]; 1 }
switch ("hello") { case \&spy { 1 } default { 0 } };
is( $seen, "hello", "predicate receives the topic" );

# predicate among other arms, first match wins
is( (switch (150) {
        case 1         { "one" }
        case \&is_big  { "big" }
        default        { "small" }
    }), "big", "predicate arm in a chain" );

# --- inline anonymous-sub predicates:  case sub { ... } { ... } ---------

is( (switch (4) { case sub { $_[0] % 2 == 0 } { "even" } default { "odd" } }),
    "even", "inline sub predicate true" );
is( (switch (5) { case sub { $_[0] % 2 == 0 } { "even" } default { "odd" } }),
    "odd", "inline sub predicate false" );

# inline sub receives the topic as its argument
my $got;
switch ("hi") { case sub { $got = $_[0]; 1 } { 1 } default { 0 } };
is( $got, "hi", "inline sub predicate receives the topic" );

# closure: the inline sub captures enclosing lexicals
my $limit = 50;
is( (switch (60) { case sub { $_[0] > $limit } { "over" } default { "under" } }),
    "over", "inline sub predicate closes over a lexical" );
$limit = 100;
is( (switch (60) { case sub { $_[0] > $limit } { "over" } default { "under" } }),
    "under", "closure sees the current lexical value" );

# multiple inline-sub arms, first match wins
is( (switch (150) {
        case sub { $_[0] < 0 }   { "neg" }
        case sub { $_[0] > 100 } { "big" }
        default                  { "mid" }
    }), "big", "multiple inline-sub arms, first match wins" );

# mixed with other pattern kinds
is( (switch (7) {
        case 0                   { "zero" }
        case [1 .. 5]            { "low" }
        case sub { $_[0] % 7 == 0 } { "seven" }
        default                  { "other" }
    }), "seven", "inline sub mixed with literal and range arms" );

# infix / expression use
is( 1 + switch (5) { case sub { $_[0] == 5 } { 40 } default { 0 } } + 1, 42,
    "inline sub predicate is infix-safe" );

# error: sub without a block
eval 'switch (1) { case sub 5 { 1 } default { 0 } }';
like( $@, qr/expected '\{' after 'sub'/, "sub predicate without a block croaks" );

# Regression: a predicate-arm switch must not corrupt a surrounding list's
# mark stack (the predicate call must not leave a dangling pushmark). This bit
# both \&name and sub {} when wrapped in arithmetic inside a list.
sub _eq5 { $_[0] == 5 }
{
    my @a = (1 + switch (5) { case \&_eq5 { 40 } default { 0 } } + 1, 99, "z");
    is_deeply( \@a, [42, 99, "z"], "\\&name predicate keeps the enclosing list intact" );
}
{
    my @b = (1 + switch (5) { case sub { $_[0] == 5 } { 40 } default { 0 } } + 1, 99, "z");
    is_deeply( \@b, [42, 99, "z"], "sub {} predicate keeps the enclosing list intact" );
}

done_testing;
