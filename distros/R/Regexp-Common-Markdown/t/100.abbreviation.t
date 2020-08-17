#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/ztM2Pw/1
my $tests = 
[
    {
        abbr_all => "*[HTML4]: Hyper Text Markup Language version 4",
        abbr_name => "HTML4",
        abbr_value => "Hyper Text Markup Language version 4",
        test => q{*[HTML4]: Hyper Text Markup Language version 4},
    },
    {
        abbr_all => "*[ATCCE]: Abbreviation \"Testing\" Correct 'Character' < Escapes >",
        abbr_name => "ATCCE",
        abbr_value => "Abbreviation \"Testing\" Correct 'Character' < Escapes >",
        test => q{*[ATCCE]: Abbreviation "Testing" Correct 'Character' < Escapes >},
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtAbbr},
    type => 'Abbreviation',
});
