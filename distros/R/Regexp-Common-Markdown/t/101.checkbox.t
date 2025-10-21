#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

my $tests = 
[
    {
        check_all       => " [ ] ",
        check_content   => " ",
        test            => q{- [ ] foo},
    },
    {
        check_all       => " [x] ",
        check_content   => "x",
        test            => q{- [x] bar},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtCheckbox},
    type => 'Checkbox extended',
});
