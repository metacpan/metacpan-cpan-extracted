
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use Proch::Seqfu;
use lib $RealBin;
use TestFu;

my $file = catfile($RealBin, "..", "data", "small_test.fa"); # "$RealBin/../data/small_test.fa";
my $bins  = catfile($RealBin, "..", "bin/");
 

SKIP: {
    my $script = catfile($bins, "fu-count");
    skip "Unable to run perl from here" if (not has_perl());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    
    my $seqs = tot("fu-count", "$file");
    ok($seqs == 6, "[fu-count] got $seqs sequences, expected 6");
 
    
}

done_testing();
