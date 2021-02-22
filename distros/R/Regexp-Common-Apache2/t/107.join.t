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
        join            => q{join({"John Paul Doe"}, ', ')},
        join_list       => q{{"John Paul Doe"}},
        join_word       => q{', '},
        name            => q{join},
        test            => q{join({"John Paul Doe"}, ', ')},
    },
    {
        join            => q{join({"John", "Paul", "Doe"}, ', ')},
        join_list       => q{{"John", "Paul", "Doe"}},
        join_word       => q{', '},
        name            => q{join list},
        test            => q{join({"John", "Paul", "Doe"}, ', ')},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Join (Trunk)',
    re => $RE{Apache2}{TrunkJoin},
});
