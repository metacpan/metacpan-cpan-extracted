#!/usr/local/bin/perl
use utf8;
use open ':std' => 'utf8';
use Test::More qw( no_plan );

BEGIN
{
    use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" );
}

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/0B3gR4/5
my $tests = 
[
    {
        para_all => "Mignonne, allons voir si la rose\nQui ce matin avait déclose\nSa robe de pourpre au soleil,\nA point perdu cette vesprée, \nLes plis de sa robe pourprée,\nEt son teint au vôtre pareil.\n",
        para_content => "Mignonne, allons voir si la rose\nQui ce matin avait déclose\nSa robe de pourpre au soleil,\nA point perdu cette vesprée, \nLes plis de sa robe pourprée,\nEt son teint au vôtre pareil.\n",
        para_prefix => "",
        test => <<EOT,
Mignonne, allons voir si la rose
Qui ce matin avait déclose
Sa robe de pourpre au soleil,
A point perdu cette vesprée, 
Les plis de sa robe pourprée,
Et son teint au vôtre pareil.
EOT
    },
    {
        para_all => "The quick brown fox\njumps over the lazy dog\n",
        para_content => "The quick brown fox\njumps over the lazy dog\n",
        para_prefix => "",
        test => <<EOT,
The quick brown fox
jumps over the lazy dog

Lorem Ipsum
EOT
    },
    {
        fail => 1,
        test => <<EOT,

I should match
- I should NOT match

EOT
    },
    {
        para_all => "Le sigh\n",
        para_content => "Le sigh\n",
        para_prefix => "",
        test => <<EOT,

Le sigh

> Why am I matching?
1. Nonononono!
* Aaaagh!
# Stahhhp!

EOT
    },
];

run_tests( $tests,
# dump_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{Paragraph},
    type => 'Paragraph',
});
