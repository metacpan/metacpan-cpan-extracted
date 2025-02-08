
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
my $program = 'fu-uniq';

sub test_bin {
    my ($prog, @args) = @_;
    my ($status, $out, $err) = run_bin($prog, @args);
    ok($status == 0, "[$prog] ran successfully with @args");
    return ($out, $err);
}


 
SKIP: {
    my $script = catfile($bins, $program);
    skip "Unable to run perl from here" if (not has_perl());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    my ($out, $err) = test_bin("fu-uniq", ("$file"));
    ok(length($out) > 0, "[$program] got output");
    my $seqs = countseqs("fu-uniq", ($file));
    ok($seqs == 4, "[$program] got $seqs sequence lines, expected 4");
      
}

done_testing();
