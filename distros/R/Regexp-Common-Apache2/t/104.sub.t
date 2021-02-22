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
        name            => q{sub},
        sub             => q{sub(s/\w+(?\-\w+)?/Paul/i,"John")},
        sub_regsub      => q{s/\w+(?\-\w+)?/Paul/i},
        sub_word        => q{"John"},
        test            => q{sub(s/\w+(?\-\w+)?/Paul/i,"John")},
    },
    {
        name            => q{sub lax syntax},
        sub             => q{sub( s/\w+(?\-\w+)?/Paul/i, "John" )},
        sub_regsub      => q{s/\w+(?\-\w+)?/Paul/i},
        sub_word        => q{"John"},
        test            => q{sub( s/\w+(?\-\w+)?/Paul/i, "John" )},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Sub (Trunk)',
    re => $RE{Apache2}{TrunkSub},
});
