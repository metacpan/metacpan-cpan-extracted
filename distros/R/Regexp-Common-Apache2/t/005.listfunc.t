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
        func_args       => q{"John"},
        func_name       => q{someFunc},
        listfunc        => q{someFunc("John")},
        name            => q{list function},
        test            => q{someFunc("John")},
    },
    {
        func_args       => q{"John", "Paul", "Peter"},
        func_name       => q{someFunc},
        listfunc        => q{someFunc( "John", "Paul", "Peter" )},
        name            => q{list function with list of words},
        test            => q{someFunc( "John", "Paul", "Peter" )},
    },
    {
        func_args       => q{"John", otherListFunc( "Paul" )},
        func_name       => q{someFunc},
        listfunc        => q{someFunc( "John", otherListFunc( "Paul" ) )},
        name            => q{list function with other list function},
        test            => q{someFunc( "John", otherListFunc( "Paul" ) )},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'ListFunc',
    re => $RE{Apache2}{ListFunc},
});
