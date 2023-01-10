
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
my $program = 'fu-extract';

sub test_bin {
    my ($prog, @args) = @_;
    my ($status, $out, $err) = run_bin($prog, @args);
    ok($status == 0, "[$prog] ran successfully with @args");
}

SKIP: {
    my $script = catfile($bins, $program);
    skip "Unable to run perl from here" if (not has_perl());
    skip "Skipping binary tests: $script not found" unless (-e "$script");
    skip "Input file not found: $file" unless (-e "$file");
    
    # Check "seq" containing headers: none expected
    
    my $seqs = countseqs("fu-extract", ("-p", "seq",  "$file"));
    ok($seqs == 0, "[$program] got $seqs sequences, expected 0");
 
    # 5/6 sequences starts with "Seq"
    $seqs = countseqs("fu-extract", ("-p", "Seq", "$file"));
    ok($seqs == 5, "[$program] got $seqs sequences, expected 5");
    
    # Case insensitive: all sequences match (6)
    my $icmd = qq($^X $script -i -p seq "$script" "$file" );
    my $iseqs = countseqs("fu-extract", ("-p", "seq", "-i", "$file"));
    ok($iseqs == 6, "[$program] got $iseqs sequences, expected 6");    
}

done_testing();
