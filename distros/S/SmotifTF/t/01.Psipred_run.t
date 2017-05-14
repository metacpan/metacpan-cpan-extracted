#!perl
# Test script for SmotifTF::Psipred
#  working with Psipred *.horiz output data 

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin '$Bin';

#BEGIN {
#    if (eval {require SmotifTF::Psipred; 1}) {
#        plan tests => 1;
#    }
#    else {
#        plan skip_all => 'Optional SmotifTF::Psipred not available';
#    }
#    $ENV{'SMOTIFTF_CONFIG_FILE'} = File::Spec->catfile($Bin, "Data","smotiftf_config.ini");
#}
use Test::More "no_plan";
BEGIN {
	use lib File::Spec->catfile($Bin, "..", "lib");
	#use lib File::Spec->catfile("..", "lib");
	use_ok 'SmotifTF::Psipred' or BAIL_OUT "Cannot load SmotifTF::Psipred";
    
    #$ENV{'SMOTIFTF_CONFIG_FILE'} = File::Spec->catfile("t", "Data", "smotiftf_config.ini");
    $ENV{'SMOTIFTF_CONFIG_FILE'} = File::Spec->catfile("Data", "smotiftf_config.ini");
}

#use lib File::Spec->catfile($Bin, "..", "lib");
#require_ok 'SmotifTF::Psipred' or BAIL_OUT "Cannot load SmotifTF::Psipred";
#use_ok ( 'SmotifTF::Psipred');

my $fasta_file = File::Spec->catfile( $Bin, "Data", "4uzx.fasta" );
#print "fatsa file =$fasta_file\n";
# my %psipred = SmotifTF::Psipred::run( sequence => $fasta_file, directory => "./t/Data" );
my ($seq, $n_motifs) = SmotifTF::Psipred::analyze_psipred( 
		pdb       => "4uzx", 
		directory => "./t/Data"
);

diag "Testing analyze_psipred()";
is( $seq, "GSALSPEEIKAKALDLLNKKLHRANKFGQDQADIDSLQRQINRVEKFGVDLNSKLAEELGLVSRKNE", "AA sequence is correct");

END {
    $ENV{'SMOTIFTF_CONFIG_FILE'} = '';
}
