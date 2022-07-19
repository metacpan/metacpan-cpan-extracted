use strict;
use warnings;

use Search::Fzf::AlgoCpp;
use Test::More tests => 2;

open my $fileH, "<t/testfile";

my $tac = 1;
my $caseInsensitive = 1;
my $nth = 1;
my @filter=(1,3,4);
my $delim = "\\s+";
my $headerLines = 0;
my $algo = Search::Fzf::AlgoCpp->newAlgoCpp($tac, $caseInsensitive, $headerLines, $nth, $delim, \@filter);
$algo->asynRead($fileH);
while(1) {
  last if $algo->getReaderStatus() == 1;
}
close $fileH;

my $iPattern = "9";
my $isSort = 1;
my $threadNum = 4;
my $algoType = 1; # 0---Exact 1---V1 2---V2
#first match
my $ret = $algo->matchList($iPattern, $isSort, $caseInsensitive, $algoType, $threadNum);
my $matchNum = scalar @{$ret};

ok($matchNum == 3, "test of algo V2.") || print "Bail out!\n";

$iPattern = "99";
$ret = $algo->matchList($iPattern, $isSort, $caseInsensitive, $algoType, $threadNum);

$matchNum = scalar @{$ret};
ok($matchNum == 2, "continue test of algo V2.") || print "Bail out!\n";

