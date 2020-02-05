
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
use FindBin qw($Bin);

my $file = "$Bin/../data/small_test.fa";
my $script = "$Bin/../bin/n50";

if (-e "$file" and -e "$script") {
	my $output = `cat "$file" | perl "$script" - 2>/dev/null`;
	ok($? == 0, '"n50" script executed');
	
	chomp($output);
	ok($output == 65,  'N50==65 as expected');

}

done_testing();
