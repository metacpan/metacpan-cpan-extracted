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
        name            => q{digits},
        test            => 12345,
        word            => 12345,
        word_digits     => 12345,
    },
    {
        name            => q{single quote string},
        test            => q{'John'},
        word            => q{'John'},
        word_enclosed   => q{John},
        word_quote      => q{'},
    },
    {
        name            => q{double quote string},
        test            => q{"John"},
        word            => q{"John"},
        word_enclosed   => q{John},
        word_quote      => q{"},
    },
    {
        name            => q{dot separated string},
        test            => q{"John"."Doe"},
        word            => q{"John"."Doe"},
        word_dot_word   => q{"John"."Doe"},
    },
    {
        name            => q{dot separated string - single quote},
        test            => q{'John'.'Doe'},
        word            => q{'John'.'Doe'},
        word_dot_word   => q{'John'.'Doe'},
    },
    {
        name            => q{variable},
        test            => q{%{REQUEST_URI}},
        word            => q{%{REQUEST_URI}},
        word_variable   => q{%{REQUEST_URI}},
    },
    {
        name            => q{sub},
        test            => q{sub(s/\w+/Paul/g,"John")},
        word            => q{sub(s/\w+/Paul/g,"John")},
        word_sub        => q{sub(s/\w+/Paul/g,"John")},
    },
    {
        name            => q{join},
        test            => q{join({"John", "Paul", "Peter"})},
        word            => q{join({"John", "Paul", "Peter"})},
        word_join       => q{join({"John", "Paul", "Peter"})},
    },
    {
        name            => q{function},
        test            => q{tolower("John")},
        word            => q{tolower("John")},
        word_function   => q{tolower("John")},
    },
    {
        name            => q{parenthesis enclosing},
        test            => q{("John")},
        word            => q{("John")},
        word_enclosed   => q{"John"},
        word_parens_close => q{)},
        word_parens_open => q{(},
    },
    {
        name            => q{parenthesis enclosing single quote},
        test            => q{('John')},
        word            => q{('John')},
        word_enclosed   => q{'John'},
        word_parens_close => q{)},
        word_parens_open => q{(},
    },
    {
        name            => q{parenthesis enclosing dotted},
        test            => q{("John"."Peter")},
        word            => q{("John"."Peter")},
        word_enclosed   => q{"John"."Peter"},
        word_parens_close => q{)},
        word_parens_open => q{(},
    },
    {
        name            => q{parenthesis enclosing variable},
        test            => q{(%{REQUEST_URI})},
        word            => q{(%{REQUEST_URI})},
        word_enclosed   => q{%{REQUEST_URI}},
        word_parens_close => q{)},
        word_parens_open => q{(},
    },
    {
        name            => q{ipv4 address},
        test            => q{127.0.0.1},
        word            => q{127.0.0.1},
        word_ip         => q{127.0.0.1},
        word_ip4        => q{127.0.0.1},
    },
    {
        name            => q{ipv6 address},
        test            => q{0000:0000:0000:0000:0000:FFFF:7F00:0001},
        word            => q{0000:0000:0000:0000:0000:FFFF:7F00:0001},
        word_ip         => q{0000:0000:0000:0000:0000:FFFF:7F00:0001},
        word_ip6        => q{0000:0000:0000:0000:0000:FFFF:7F00:0001},
    },
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Word (Trunk)',
    re => $RE{Apache2}{TrunkWord},
});
