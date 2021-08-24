#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/4Z3h4F/1/
my $tests = 
[
    {
        strike_all      => "~~Hi~~",
        strike_content  => "Hi",
        test            => q{~~Hi~~ Hello, world!},
    },
    {
        strike_all      => "~~This whole sentence is wrong~~",
        strike_content  => "This whole sentence is wrong",
        test            => q{~~This whole sentence is wrong~~},
    },
    {
        strike_all      => "~~has a\n\nnew paragraph~~",
        strike_content  => "has a\n\nnew paragraph",
        test            => <<EOT,
This ~~has a

new paragraph~~.
EOT
    },
    {
        fail => 1,
        test => q{~~Not ok unless ~ is escaped~~},
    },
    {
        strike_all      => "~~Not ok unless \\~ is escaped~~",
        strike_content  => "Not ok unless \\~ is escaped",
        test            => q{~~Not ok unless \~ is escaped~~},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtStrikeThrough},
    type => 'Strikethrough extended',
});
