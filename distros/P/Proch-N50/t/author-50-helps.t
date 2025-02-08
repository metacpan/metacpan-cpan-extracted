
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
    my $hashBin = catfile($bins, "fu-hash");

    skip "Directory not found" unless (-d "$bins");
    skip "Skipping binary tests: $hashBin not found" unless (-e "$hashBin");
    skip "Input file not found: $file" unless (-e "$file");
    skip "Failed calling \$^X externally (maybe is perl.exe?)" if (not has_perl());


    test_bin("fu-hash", "--help");

	  test_bin("fu-grep", "--help"); 
    
    test_bin("fu-uniq", "--help");
    
    test_bin("fu-sort", "--help");
    
    test_bin("fu-rename", "--help");
    
    test_bin("fu-extract", "--help");
    
}
done_testing();
