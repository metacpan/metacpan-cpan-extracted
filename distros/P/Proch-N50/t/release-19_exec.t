
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($RealBin);

my $file = "$RealBin/../data/small_test.fa";
my $script = "$RealBin/../bin/n50";

if (-e "$file" and -e "$script") {

	my $output = `$^X "$script" "$file"`;
	ok($? == 0, "'n50' script executed: exit=$?");


}

done_testing();
