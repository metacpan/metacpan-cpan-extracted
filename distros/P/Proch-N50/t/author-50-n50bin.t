
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


SKIP: {
    skip "Unable to run perl from here" if (not has_perl() != 0);
    skip "Input file not found $file" if (! -e "$file");
    my ($status, $out, $err) = run_bin("n50", $file);
    ok($status == 0, "n50 ran successfully");
    ok($out eq "65", "n50 output is correct");
}

done_testing();
