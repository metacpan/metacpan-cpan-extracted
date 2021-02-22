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
        name            => q{string},
        string          => q{John},
        test            => q{John},
    },
    {
        name            => q{string substring},
        string          => q{John Doe},
        test            => q{John Doe},
    },
    {
        name            => q{string substring (2)},
        string          => q{, },
        test            => q{, },
    },
    {
        name            => q{string with variable},
        string          => q{Hello %{NAME}},
        test            => q{Hello %{NAME}},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'String (Trunk)',
    re => $RE{Apache2}{TrunkString},
});
