use strict;
use warnings;

use Search::Fzf::AlgoCpp;
use Test::More tests => 2;

open my $fileH, "<t/testfile";

my $tac = 0;
my $caseInsensitive = 0;
my $nth = 0;
my @filter = ();
my $delim = "";
my $headerLines = 2;
my $algo = Search::Fzf::AlgoCpp->newAlgoCpp($tac, $caseInsensitive, $headerLines, $nth, $delim, \@filter);
$algo->asynRead($fileH);
while(1) {
  last if $algo->getReaderStatus() == 1;
}
close $fileH;

my $headerArr = $algo->getHeaderStr();
my $size = scalar(@{$headerArr});
ok($size == 2, "test of getHeadStr.") || print "Bail out!\n";

$algo->setMarkLabel(0);
$algo->setMarkLabel(2);
$algo->setMarkLabel(3);
my $selectList = $algo->getMarkedStr();
$size = scalar(@{$selectList});
ok($size == 3, "test of getMarkedStr.") || print "Bail out!\n";


