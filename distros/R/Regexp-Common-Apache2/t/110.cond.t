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
        cond            => q{1},
        cond_true       => q{1},
        name            => q{true},
        test            => q{1},
    },
    {
        cond            => q{0},
        cond_false      => q{0},
        name            => q{false},
        test            => q{0},
    },
    {
        cond            => q{!1},
        cond_neg        => q{!1},
        name            => q{not true},
        test            => q{!1},
    },
    {
        cond            => q{!0},
        cond_neg        => q{!0},
        name            => q{not false},
        test            => q{!0},
    },
    {
        cond            => q{1 && 1},
        cond_and        => q{1 && 1},
        name            => q{true && true},
        test            => q{1 && 1},
    },
    {
        cond            => q{1 && 0},
        cond_and        => q{1 && 0},
        name            => q{true && false},
        test            => q{1 && 0},
    },
    {
        cond            => q{1 || 1},
        cond_or         => q{1 || 1},
        name            => q{true || true},
        test            => q{1 || 1},
    },
    {
        cond            => q{1 || 0},
        cond_or         => q{1 || 0},
        name            => q{true || false},
        test            => q{1 || 0},
    },
    {
        cond            => q{(1)},
        name            => q{(true)},
        test            => q{(1)},
    },
    {
        cond            => q{(0)},
        name            => q{(false)},
        test            => q{(0)},
    },
    {
        cond            => q{(!1)},
        name            => q{(not true)},
        test            => q{(!1)},
    },
    {
        cond            => q{(!0)},
        name            => q{(not false)},
        test            => q{(!0)},
    },
    {
        cond            => q{"John" == "Jack"},
        name            => q{comp == comp with strings},
        test            => q{"John" == "Jack"},
    },
    {
        cond            => q{1 -ne 0},
        name            => q{comp -ne comp with integers},
        test            => q{1 -ne 0},
    },
    {
        cond            => q{!(1 -eq 0)},
        cond_neg        => q{!(1 -eq 0)},
        name            => q{!(comp -eq comp)},
        test            => q{!(1 -eq 0)},
    },
    {
        cond            => q{!-e /some/file.txt},
        cond_neg        => q{!-e /some/file.txt},
        name            => q{!unary-op word},
        test            => q{!-e /some/file.txt},
        unaryop         => q{e},
    },
    {
        cond            => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
        cond_neg        => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
        name            => q{binary-op word},
        test            => q{!(192.168.1.10 -ipmatch 192.168.1.1/24)},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Cond (Trunk)',
    re => $RE{Apache2}{TrunkCond},
});
