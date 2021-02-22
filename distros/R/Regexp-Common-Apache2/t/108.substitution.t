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
        name            => q{substitution},
        sub             => q{sub(s/\w+/Paul/g,"John")},
        sub_regsub      => q{s/\w+/Paul/g},
        sub_word        => q{"John"},
        test            => q{sub(s/\w+/Paul/g,"John")},
    },
    {
        name            => q{substitute digits},
        sub             => q{sub(s/\d/67890/g,"12345")},
        sub_regsub      => q{s/\d/67890/g},
        sub_word        => q{"12345"},
        test            => q{sub(s/\d/67890/g,"12345")},
    },
    {
        name            => q{substitute single quote string},
        sub             => q{sub(s/\w+/Paul/g,'John')},
        sub_regsub      => q{s/\w+/Paul/g},
        sub_word        => q{'John'},
        test            => q{sub(s/\w+/Paul/g,'John')},
    },
    {
        name            => q{substitute double quote string},
        sub             => q{sub(s/\w+/Paul/g,"John")},
        sub_regsub      => q{s/\w+/Paul/g},
        sub_word        => q{"John"},
        test            => q{sub(s/\w+/Paul/g,"John")},
    },
    {
        name            => q{substitute join},
        sub             => q{sub(s/\w+/Paul/g, join({"John", "Paul"}, ', ') )},
        sub_regsub      => q{s/\w+/Paul/g},
        sub_word        => q{join({"John", "Paul"}, ', ')},
        test            => q{sub(s/\w+/Paul/g, join({"John", "Paul"}, ', ') )},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Sub (Trunk)',
    re => $RE{Apache2}{TrunkSub},
});
