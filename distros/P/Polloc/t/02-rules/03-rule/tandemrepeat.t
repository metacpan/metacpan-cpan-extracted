use strict;
use warnings;

use Test::More tests => 9;

# 1
use_ok('Bio::Polloc::Rule::tandemrepeat');
use_ok('Bio::Seq');

# -------------------------------------------- tandemrepeat
# 3
SKIP: {
skip 'trf is not installed', 7 unless Bio::Polloc::Rule::tandemrepeat->_executable;
my $r = Bio::Polloc::RuleI->new(-type=>'tandemrepeat');
isa_ok($r, 'Bio::Polloc::Rule::tandemrepeat');

# 4
$r->value({	-minsize => 3,
		-minperiod => 2,
		-exp => 3,
		-minscore => 30});
my $loci = $r->execute(-seq=>Bio::Seq->new(-seq=>'CCCACTGACTGACTGACTGACTGACTGGGGTACGTTAGCCCC'));
isa_ok($loci, 'ARRAY');
is($#$loci, 0, 'Correct number of loci');

# 6
isa_ok($loci->[0], 'Bio::Polloc::Locus::repeat');
is($loci->[0]->from, 4, 'Correct origin of locus 1');
is($loci->[0]->strand, '+', 'Correct strand of locus 1');
is($loci->[0]->score, 48, 'Correct score of locus 1');
}

