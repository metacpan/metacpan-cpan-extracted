#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/6VG46H/1
my $tests = 
[
    {
        br_all => "  \n",
        test => <<EOT,
Mignonne, allons voir si la rose  
Qui ce matin avait déclose  
Sa robe de pourpre au soleil,  
A point perdu cette vesprée,  
Les plis de sa robe pourprée,  
Et son teint au vôtre pareil.
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{LineBreak},
    type => 'Line break',
});
