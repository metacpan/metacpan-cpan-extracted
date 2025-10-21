#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/Vlew4X/2
my $tests = 
[
    { line_all => "---", line_type => "-", test => "---\n" },

    { line_all => "---", line_type => "-", test => " ---\n" },

    { line_all => "---", line_type => "-", test => "  ---\n" },

    { line_all => " ---", line_type => "-", test => "   ---\n" },

    { line_all => "---", line_type => "-", test => "\t---\n" },

    { line_all => "- - -", line_type => "-", test => "- - -\n" },

    { line_all => "- - -", line_type => "-", test => " - - -\n" },

    { line_all => "- - -", line_type => "-", test => "  - - -\n" },

    { line_all => " - - -", line_type => "-", test => "   - - -\n" },

    { line_all => "- - -", line_type => "-", test => "\t- - -\n" },

    { line_all => "***", line_type => "*", test => "***\n" },

    { line_all => "***", line_type => "*", test => " ***\n" },

    { line_all => "***", line_type => "*", test => "  ***\n" },

    { line_all => " ***", line_type => "*", test => "   ***\n" },

    { line_all => "***", line_type => "*", test => "\t***\n" },

    { line_all => "* * *", line_type => "*", test => "* * *\n" },

    { line_all => "* * *", line_type => "*", test => " * * *\n" },

    { line_all => "* * *", line_type => "*", test => "  * * *\n" },

    { line_all => " * * *", line_type => "*", test => "   * * *\n" },

    { line_all => "* * *", line_type => "*", test => "\t* * *\n" },

    { line_all => "___", line_type => "_", test => "___\n" },

    { line_all => "___", line_type => "_", test => " ___\n" },

    { line_all => "___", line_type => "_", test => "  ___\n" },

    { line_all => " ___", line_type => "_", test => "   ___\n" },

    { line_all => "___", line_type => "_", test => "\t___\n" },

    { line_all => "_ _ _", line_type => "_", test => "_ _ _\n" },

    { line_all => "_ _ _", line_type => "_", test => " _ _ _\n" },

    { line_all => "_ _ _", line_type => "_", test => "  _ _ _\n" },

    { line_all => " _ _ _", line_type => "_", test => "   _ _ _\n" },

    { line_all => "_ _ _", line_type => "_", test => "\t_ _ _\n" },
];

run_tests( $tests,
# dump_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Line},
    type => 'Horizontal line',
});

