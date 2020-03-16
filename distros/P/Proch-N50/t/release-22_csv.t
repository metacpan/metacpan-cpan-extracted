
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
use File::Basename;

my $file = "$RealBin/../data/sim2.fa";
my $script = "$RealBin/../bin/n50";
# #path,seqs,size,N50,min,max
# data/sim2.fa,21,7530,493,68,989
if (-e "$file" and -e "$script") {
	# TSV FORMAT

	my @data = `perl "$script" --format csv "$file" 2>/dev/null`;
	ok($? == 0, "OK: perl \"$script\" --format csv \"$file\"");


	my @header = split /,/, $data[0];
	my @stats  = split /,/, $data[1];
	ok($header[0] =~/^#/, "Header found: <$header[0]>");
	ok(basename($file) eq basename($stats[0]), 
			"First column is filename: <$stats[0]>");
	ok($stats[2] == 7530, "Col 3: Total size is 7530: <$stats[2]>");
	ok($stats[3] == 493,  "Col 4: N50 is 493: <$stats[3]>");
	
}

done_testing();
