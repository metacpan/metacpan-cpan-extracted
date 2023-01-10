use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Spec::Functions;
use lib $RealBin;
use TestFu;

my $file = catfile($RealBin, "..", "data", "small_test.fa"); # "$RealBin/../data/small_test.fa";
my $bins  = catfile($RealBin, "..", "bin/");
 
SKIP: {
    my $n50bin = catfile($bins, "n50");

    skip "Skipping binary tests: $n50bin not found" unless (-e "$n50bin");
    skip "Input file not found: $file" unless (-e "$file");
    
    # check if perl can run
    skip "Unable to run perl from here" if (not has_perl());

    my ($ok, $output, $err) = run_bin("n50", ("$file"));
    ok($ok == 0, "ran n50");
    ok($output == 65, "n50 of small_test.fa is 65");
}

done_testing();
