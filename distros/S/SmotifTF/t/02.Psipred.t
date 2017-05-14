#!perl
# Test script for SmotifTF::Psipred
#  working with Psipred *.horiz output data 

use strict;
use warnings;
use Test::More 'no_plan';
use File::Spec;
use FindBin '$Bin';

#BEGIN {
#    if (eval {require SmotifTF::Psipred; 1}) {
#        plan tests => 3;
#    }
#    else {
#        plan skip_all => 'Optional SmotifTF::Psipred not available';
#    }
#    $ENV{'SMOTIFTF_CONFIG_FILE'} = File::Spec->catfile($Bin, "Data","smotiftf_config.ini");
#}

BEGIN{
    use lib File::Spec->catfile( $Bin, "..", "lib" );
    use_ok 'SmotifTF::Psipred' or BAIL_OUT "Cannot load SmotifTF::Psipred";
#use_ok( 'SmotifTF::Psipred');
}

my $horiz_file = File::Spec->catfile( $Bin, "Data", "4uzx.horiz" );
my %psipred    = SmotifTF::Psipred::parse( "$horiz_file" );

diag "Testing parse Psipred output file";
is( $psipred{'AA'}  , "GSALSPEEIKAKALDLLNKKLHRANKFGQDQADIDSLQRQINRVEKFGVDLNSKLAEELGLVSRKNE", "AA is ok"  );
is( $psipred{'Conf'}, "9979999999999999999999999806639889999999999998767988699999678886769", "Conf is ok");
is( $psipred{'Pred'}, "CCCCCHHHHHHHHHHHHHHHHHHHHHHCCCHHHHHHHHHHHHHHHHHCCCCCCHHHHHHCCCCCCCC", "Pred is ok");

#Conf: 997999999999999999999999980663988999999999999876798869999967
#Pred: CCCCCHHHHHHHHHHHHHHHHHHHHHHCCCHHHHHHHHHHHHHHHHHCCCCCCHHHHHHC
#  AA: GSALSPEEIKAKALDLLNKKLHRANKFGQDQADIDSLQRQINRVEKFGVDLNSKLAEELG
#              10        20        30        40        50        60
#
#
#Conf: 8886769
#Pred: CCCCCCC
#  AA: LVSRKNE
#           
