
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
	print STDERR "Testing: $script\n";
	print STDERR "\$ cat \"$file\" | $^X \"$script\" - \n";
	my $output = `cat "$file" | $^X "$script" - `;
	ok($? == 0, "'n50' script executed: exit=$?");
	
	chomp($output);
	ok($output == 65,  "N50==65 as expected: got $output");

}

done_testing();
