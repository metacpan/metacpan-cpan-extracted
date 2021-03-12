#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'Regexp::Common::Apache2', qw( $ap_true $ap_false ) ) || BAIL_OUT( "Unable to load Regexp::Common::Apache2" );
    use lib './lib';
    use Regexp::Common qw( Apache2 );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
};

ok( $ap_true == 1, 'true value' );
ok( $ap_false == 0, 'false value' );

my $tests = 
[
    {
        cond            => 1,
        cond_true       => 1,
        name            => q{true},
        test            => 1,
    },
    {
        cond            => 0,
        cond_false      => 0,
        name            => q{false},
        test            => 0,
    },
    {
        cond            => q{!1},
        cond_expr       => 1,
        cond_neg        => q{!1},
        name            => q{not true},
        test            => q{!1},
    },
    {
        cond            => q{!0},
        cond_expr       => 0,
        cond_neg        => q{!0},
        name            => q{not false},
        test            => q{!0},
    },
    {
        cond            => q{1 && 1},
        cond_and        => q{1 && 1},
        cond_and_expr1  => 1,
        cond_and_expr2  => 1,
        name            => q{true && true},
        test            => q{1 && 1},
    },
    {
        cond            => q{1 && 0},
        cond_and        => q{1 && 0},
        cond_and_expr1  => 1,
        cond_and_expr2  => 0,
        name            => q{true && false},
        test            => q{1 && 0},
    },
    {
        cond            => q{1 || 1},
        cond_or         => q{1 || 1},
        cond_or_expr1   => 1,
        cond_or_expr2   => 1,
        name            => q{true || true},
        test            => q{1 || 1},
    },
    {
        cond            => q{1 || 0},
        cond_or         => q{1 || 0},
        cond_or_expr1   => 1,
        cond_or_expr2   => 0,
        name            => q{true || false},
        test            => q{1 || 0},
    },
    {
        cond            => q{(1)},
        cond_parenthesis => 1,
        name            => q{(true)},
        test            => q{(1)},
    },
    {
        cond            => q{(0)},
        cond_parenthesis => 0,
        name            => q{(false)},
        test            => q{(0)},
    },
    {
        cond            => q{(!1)},
        cond_parenthesis => q{!1},
        name            => q{(not true)},
        test            => q{(!1)},
    },
    {
        cond            => q{(!0)},
        cond_parenthesis => q{!0},
        name            => q{(not false)},
        test            => q{(!0)},
    },
    {
        cond            => q{"John" == "Jack"},
        cond_comp       => q{"John" == "Jack"},
        name            => q{comp == comp with strings},
        test            => q{"John" == "Jack"},
    },
    {
        cond            => q{1 -ne 0},
        cond_comp       => q{1 -ne 0},
        name            => q{comp -ne comp with integers},
        test            => q{1 -ne 0},
    },
    {
        cond            => q{!(1 -eq 0)},
        cond_expr       => q{(1 -eq 0)},
        cond_neg        => q{!(1 -eq 0)},
        name            => q{!(comp -eq comp)},
        test            => q{!(1 -eq 0)},
    },
    {
        cond            => q{!-e /some/file.txt},
        cond_expr       => q{-e /some/file.txt},
        cond_neg        => q{!-e /some/file.txt},
        name            => q{!unary-op word},
        test            => q{!-e /some/file.txt},
    },
    {
        cond            => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
        cond_expr       => q{(192.168.1.10 -ipmatch 192.168.1.1/24)},
        cond_neg        => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
        name            => q{binary-op word},
        test            => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
    },
    {
        cond            => q{-R '192.168.2.0/24' || -R '127.0.0.1/24'},
        cond_or         => q{-R '192.168.2.0/24' || -R '127.0.0.1/24'},
        cond_or_expr1   => q{-R '192.168.2.0/24'},
        cond_or_expr2   => q{-R '127.0.0.1/24'},
        name            => q{Priority of expression: condition over unary operation},
        test            => q{-R '192.168.2.0/24' || -R '127.0.0.1/24'},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Cond (Trunk)',
    re => $RE{Apache2}{TrunkCond},
});
