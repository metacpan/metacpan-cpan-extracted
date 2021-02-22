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
        listfunc        => q{someFunc("John")},
        listfunc_args   => q{"John"},
        listfunc_name   => q{someFunc},
        name            => q{list function},
        test            => q{someFunc("John")},
    },
    {
        listfunc        => q{someFunc( "John", "Paul", "Peter" )},
        listfunc_args   => q{"John", "Paul", "Peter"},
        listfunc_name   => q{someFunc},
        name            => q{list function with list of words},
        test            => q{someFunc( "John", "Paul", "Peter" )},
    },
    {
        listfunc        => q{someFunc( "John", otherListFunc( "Paul" ) )},
        listfunc_args   => q{"John", otherListFunc( "Paul" )},
        listfunc_name   => q{someFunc},
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
