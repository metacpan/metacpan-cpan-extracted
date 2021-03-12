#!/usr/local/bin/perl
BEGIN
{
    use Test::More qw( no_plan );
    use_ok( 'Regexp::Common::Apache2' ) || BAIL_OUT( "Unable to load Regexp::Common::Apache2" );
    use lib './lib';
    use Regexp::Common qw( Apache2 );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
};

my $tests = 
[
    {
        integercomp     => q{10 -ne 20},
        integercomp_op  => q{ne},
        integercomp_worda => 10,
        integercomp_wordb => 20,
        name            => q{integer comparison},
        test            => q{10 -ne 20},
    },
    {
        integercomp     => q{%{TIME_HOUR} -gt 9},
        integercomp_op  => q{gt},
        integercomp_worda => q{%{TIME_HOUR}},
        integercomp_wordb => 9,
        name            => q{%{TIME_HOUR} -gt 9},
        test            => q{%{TIME_HOUR} -gt 9},
    },
    {
        integercomp     => q{%{TIME_HOUR} -lt 17},
        integercomp_op  => q{lt},
        integercomp_worda => q{%{TIME_HOUR}},
        integercomp_wordb => 17,
        name            => q{%{TIME_HOUR} -lt 17},
        test            => q{%{TIME_HOUR} -lt 17},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Integer Comparison',
    re => $RE{Apache2}{IntegerComp},
});
