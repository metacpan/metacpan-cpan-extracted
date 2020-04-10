use strict;
use warnings;
use Proch::N50;
use Test::More tests => 3;
use FindBin qw($RealBin);
my $file = "$RealBin/../data/small_test.fa";

# evaluate statistica calculated since 1.2.0
SKIP: {
	skip "missing input file" unless (-e "$file");
	my $stats = getStats($file, 'JSON');
	ok($stats->{N75} > 0, 'got an N75');
	ok($stats->{N90} > 0, 'got an N90');
	ok($stats->{auN} > 0, 'got an auN');
}

# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
