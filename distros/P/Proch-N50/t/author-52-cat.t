
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
sub test_bin {
    my ($prog, @args) = @_;
    my ($status, $out, $err) = run_bin($prog, @args);
    ok($status == 0, "[$prog] ran successfully with @args");
}



SKIP: {
    my $script = catfile($bins, "fu-cat");
    skip "Unable to run perl from here" if (not has_perl() != 0);
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    my $seqs = countseqs("fu-cat", "$file");
    ok($seqs == 6, "[fu-cat] got $seqs sequences, expected 6");

    $seqs = countseqs( "fu-cat", ("-l", 50, "$file"));
    ok($seqs == 1, "[fu-cat] got $seqs sequences > 50, expected 1");

    
}

done_testing();
