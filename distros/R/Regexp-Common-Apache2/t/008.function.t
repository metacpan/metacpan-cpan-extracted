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
        function        => q{someFunction("parameter1", "parameter2")},
        function_args   => q{"parameter1", "parameter2"},
        function_name   => q{someFunction},
        name            => q{basic function},
        test            => q{someFunction("parameter1", "parameter2")},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Function',
    re => $RE{Apache2}{Function},
});
