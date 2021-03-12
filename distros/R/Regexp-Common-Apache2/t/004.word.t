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
        name            => q{function},
        test            => q{tolower("John")},
        word            => q{tolower("John")},
        word_function   => q{tolower("John")},
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
    type => 'Word',
    re => $RE{Apache2}{Word},
});
