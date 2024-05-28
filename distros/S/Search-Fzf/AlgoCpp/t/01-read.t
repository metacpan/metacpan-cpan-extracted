use strict;
use warnings;

use Search::Fzf::AlgoCpp;
use Test::More tests => 1;

my @perlArr = qw(Hello fzf world);
my $tac = 0;
my $caseInsensitive = 1;
my $headerLines = 0;
my $algo = Search::Fzf::AlgoCpp->new($tac, $caseInsensitive, $headerLines);
$algo->read(\@perlArr);

ok($algo->getCatArraySize == 3, "simple read from array.") || print "Bail out!\n";

