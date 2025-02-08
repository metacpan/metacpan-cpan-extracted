use strict;
use warnings;
use Proch::Seqfu;
use Test::More;
use FindBin qw($RealBin);
my $seq = "CAGATA";

my $rc = Proch::Seqfu::rc($seq);
ok($rc eq "TATCTG", "reverse complement: $rc");
my $prot = "MARKWASHERE";
ok( Proch::Seqfu::is_seq($seq) == 1, "DNA Sequence is a sequence");
ok( Proch::Seqfu::is_seq($prot) == 0, "Protein not a DNA sequence");
done_testing();
