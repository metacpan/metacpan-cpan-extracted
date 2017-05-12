use strict;
use warnings;

use Test::More tests => 12;

# 1
use_ok('Bio::Polloc::Rule::pattern');
use_ok('Bio::Seq');

# -------------------------------------------- pattern
# 3
SKIP: {
skip 'fuzznuc not installed', 10 unless Bio::Polloc::Rule::pattern->_executable;
my $r = Bio::Polloc::RuleI->new(-type=>'pattern');
isa_ok($r, 'Bio::Polloc::Rule::pattern');

# 4
$r->value({-pattern=> 'AC[GCA]'});
my $loci = $r->execute(-seq=>Bio::Seq->new(-seq=>'ACGGCATCGACTAGCGAGCGGACGATCGACTACGACTTACGCTATCGTCTAC'));
isa_ok($loci, 'ARRAY');
is($#$loci, 4, 'Correct number of loci');

# 6
isa_ok($loci->[0], 'Bio::Polloc::Locus::pattern');
is($loci->[0]->from, 1, 'Correct origin of locus 1');
is($loci->[4]->from, 46, 'Correct origin of locus 5');
is($loci->[0]->strand, '+', 'Correct strand of locus 1');
is($loci->[4]->strand, '-', 'Correct strand of locus 5');
is($loci->[0]->score, 3, 'Correct score of locus 1');

# 12
is($loci->[0]->pattern, 'AC[GCA]', 'Pattern passed from Rule to Locus');

}

