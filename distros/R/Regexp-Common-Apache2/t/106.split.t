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
        name            => q{split},
        split           => q{split(/\w+/,"John Doe")},
        split_regex     => q{/\w+/},
        split_word      => q{"John Doe"},
        test            => q{split(/\w+/,"John Doe")},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Split (Trunk)',
    re => $RE{Apache2}{TrunkSplit},
});
