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
        test            => q{12345},
        word            => q{12345},
        word_digits     => q{12345},
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
        word_enclosed   => q{John"."Doe},
        word_quote      => q{"},
    },
    {
        name            => q{dot separated string - single quote},
        test            => q{'John'.'Doe'},
        word            => q{'John'.'Doe'},
        word_enclosed   => q{John'.'Doe},
        word_quote      => q{'},
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
];

my $sub = $ENV{AUTHOR_TESTING} ? \&dump_tests : \&run_tests;
$sub->( $tests,
{
    type => 'Word',
    re => $RE{Apache2}{Word},
});
