use strict;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($RealBin);

my $file = "$RealBin/../data/small_test.fa";
print "$file\n";
SKIP: {
	skip "missing input file" unless (-e "$file");
	my $N50 = getN50($file);
	ok(length($N50) > 0, 'got an N50');
	ok($N50 =~/^\d+$/, 'N50 is a number: ' . $N50);
	ok($N50 == 65, 'N50==65 as expected, got: ' . $N50);
}

done_testing();
