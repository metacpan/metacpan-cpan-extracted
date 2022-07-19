use strict;
use warnings;

use Search::Fzf::AlgoCpp;
use Test::More tests => 4;

open my $fileH, "<t/testfile";

my $tac = 0;
my $caseInsensitive = 1;
my $headerLines = 0;
my $algo = Search::Fzf::AlgoCpp->new($tac, $caseInsensitive, $headerLines);
$algo->asynRead($fileH);
while(1) {
  last if $algo->getReaderStatus() == 1;
}
close $fileH;

ok($algo->getCatArraySize == 13, "simple read from array.") || print "Bail out!\n";

my $iPattern = "9";
my $isSort = 0;
my $threadNum = 0;
my $algoType = 2; # 0---Exact 1---V1 2---V2
#first match
my $ret = $algo->matchList($iPattern, $isSort, $caseInsensitive, $algoType, $threadNum);
my $matchNum = scalar @{$ret};

ok($matchNum == 4, "test of algo V2.") || print "Bail out!\n";

$iPattern = "99";
$isSort = 0;
$threadNum = 4;
$ret = $algo->matchList($iPattern, $isSort, $caseInsensitive, $algoType, $threadNum);

$matchNum = scalar @{$ret};
ok($matchNum == 2, "continue test of algo V2.") || print "Bail out!\n";

my $nullArr = $algo->getNullMatchList();
my $size = scalar @{$nullArr};
ok($size == 13, "test getNullMatchList.");

