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
        func_args       => q{"parameter1", "parameter2"},
        func_name       => q{someFunction},
        function        => q{someFunction("parameter1", "parameter2")},
        name            => q{basic function},
        paren_group     => q{("parameter1", "parameter2")},
        test            => q{someFunction("parameter1", "parameter2")},
    },
    {
        fail            => 1,
        name            => q{Modern variable false positive},
        test            => q{v('QUERY_STRING')},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Function (Trunk)',
    re => $RE{Apache2}{TrunkFunction},
});
