use strict;
use warnings;
use Proch::N50;
use Test::More tests => 3;
use FindBin qw($RealBin);
my $file = "$RealBin/../data/small_test.fa";

SKIP: {
	skip "missing input file" unless (-e "$file");
	my $stats = getStats($file, 'JSON');
	ok($stats->{N50} > 0, 'got an N50');
	ok($stats->{N50} == 65, 'N50==65 as expected (in JSON)');
	ok($stats->{seqs} == 6, 'NumSeqs==6 as expected (in JSON)');
}

# {
#    "seqs" : 6,
#    "status" : 1,
#    "filename" : "small_test.fa",
#    "N50" : "65",
#    "dirname" : "data",
#    "size" : 130
# }
