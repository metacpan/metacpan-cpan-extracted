use strict;
use warnings;
use Proch::N50;
use FASTX::Reader;
use Test::More;
use FindBin qw($RealBin);

my $v = $FASTX::Reader::VERSION;
my ($v1, $v2, $v3) = split /\./, $v;

my $file = "$RealBin/../data/encodings/test-lf.fa";
my $win  = "$RealBin/../data/encodings/test-crlf.fa";
SKIP: {
	skip "missing input file" if (! -e "$file" or ! -e "$win" or $v1 < 1 or ($v1 == 1 and $v2 < 4));
	my $N50 = getN50($file);
	my $W50 = getN50($win);
	ok($N50 > 0, "got an N50: $N50");
	ok($N50 == $W50, "Under $^O CRLF file has same N50 than LF ($N50 LF vs $W50 CRLF)");
}

done_testing();
