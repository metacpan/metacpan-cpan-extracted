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
        list            => q{{"John", "Doe"}},
        list_words      => q{"John", "Doe"},
        name            => q{list {}},
        test            => q{{"John", "Doe"}},
    },
    {
        list            => q{({"John", "Doe"})},
        list_list       => q{{"John", "Doe"}},
        name            => q{list ({})},
        test            => q{({"John", "Doe"})},
    },
    {
        list            => q{( { "John", "Doe" } )},
        list_list       => q{{ "John", "Doe" }},
        name            => q{list ({}) with lose spaces},
        test            => q{( { "John", "Doe" } )},
    },
    {
        list            => q{split( /\w+/, "John Doe" )},
        list_split      => q{split( /\w+/, "John Doe" )},
        name            => q{list based on split},
        test            => q{split( /\w+/, "John Doe" )},
    },
    {
        list            => q{(split( /\w+/, "John Doe" ))},
        list_list       => q{split( /\w+/, "John Doe" )},
        name            => q{list based on split enclosed in ()},
        test            => q{(split( /\w+/, "John Doe" ))},
    },
    {
        list            => q{someListFunction("John")},
        list_func       => q{someListFunction("John")},
        name            => q{list based on list function},
        test            => q{someListFunction("John")},
    },
    {
        list            => q{someListFunction("John", {"Paul", "Peter"})},
        list_func       => q{someListFunction("John", {"Paul", "Peter"})},
        name            => q{list based on list function {variant}},
        test            => q{someListFunction("John", {"Paul", "Peter"})},
    },
    {
        list            => q{someListFunction( "John" )},
        list_func       => q{someListFunction( "John" )},
        name            => q{list based on list function with lose spaces},
        test            => q{someListFunction( "John" )},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'List (Trunk)',
    re => $RE{Apache2}{TrunkList},
});
