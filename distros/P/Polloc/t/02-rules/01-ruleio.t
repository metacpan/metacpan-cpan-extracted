use strict;
use warnings;

use Test::More tests => 46;

# 1
use_ok('Bio::Polloc::RuleIO');
use_ok('Bio::Polloc::Genome');

# 3
my $T = Bio::Polloc::RuleIO->new(-file=>'t/vntrs.bme');
isa_ok($T, 'Bio::Polloc::RuleIO');
isa_ok($T, 'Bio::Polloc::RuleSet::cfg');

# 5
is($T->prefix_id, 'VNTR');

# 6
is($T->init_id, 1);

# 7
is($T->format, 'cfg');

# 8
is($#{$T->get_rules}, 1);

# 9
isa_ok($T->get_rule(0), 'Bio::Polloc::RuleI');
isa_ok($T->get_rule(0), 'Bio::Polloc::Rule::tandemrepeat');
isa_ok($T->get_rule(1), 'Bio::Polloc::Rule::boolean');

# 12
my $i = 0;
while($T->next_rule){ $i++ }
is($i, 2);

# 13
isa_ok($T->groupcriteria, 'ARRAY');
is($#{$T->groupcriteria}, 0);
isa_ok($T->groupcriteria->[0], 'Bio::Polloc::GroupCriteria');
isa_ok($T->grouprules->[0], 'Bio::Polloc::GroupCriteria');

# 17
my $G = [Bio::Polloc::Genome->new(-file=>'t/multi.fasta'),
	Bio::Polloc::Genome->new(-file=>'t/repeats.fasta')];
$T->genomes($G);
isa_ok($T->genomes, 'ARRAY');
isa_ok($T->genomes->[0], 'Bio::Polloc::Genome');
isa_ok($T->genomes->[1], 'Bio::Polloc::Genome');

SKIP: {
use Bio::Polloc::Rule::tandemrepeat;
skip 'trf not installed', 27 unless Bio::Polloc::Rule::tandemrepeat->_executable;

# 20
my $L = $T->execute;
isa_ok($L, 'Bio::Polloc::LociGroup');

# 21
isa_ok($L->loci, 'ARRAY');
is($#{$L->loci}, 1);
isa_ok($L->loci->[0], 'Bio::Polloc::Locus::repeat');
isa_ok($L->loci->[1], 'Bio::Polloc::Locus::repeat');
is($L->loci->[0]->from, 697);
is($L->loci->[1]->from, 667);
is($L->loci->[0]->length, 67);
is($L->loci->[1]->length, 98);
isa_ok($L->loci->[0]->genome, 'Bio::Polloc::Genome');

# 30
my $crit = $T->groupcriteria->[0];
isa_ok($crit->locigroup($L), 'Bio::Polloc::LociGroup');
is($#{$crit->get_loci}, 1);

# 32
my $groups = $crit->build_groups;
isa_ok($groups, 'ARRAY');
is($#$groups, 0);
isa_ok($groups->[0], 'Bio::Polloc::LociGroup');
is($#{$groups->[0]->loci}, 1);

# 36
# Genomes passed from $crit to $groups->[0]:
isa_ok($groups->[0]->genomes, 'ARRAY');
is($#{$groups->[0]->genomes}, 1);
isa_ok($groups->[0]->genomes->[0], 'Bio::Polloc::Genome');

# 39
eval { $T->_load_module('Bio::Tools::Run::StandAloneBlast') };
skip 'Bio::Tools::Run::StandAloneBlast not installed', 8 if $@;

my $nL = $crit->extend(-loci=>$groups->[0]);
isa_ok($nL, 'Bio::Polloc::LociGroup');
# Genomes passed from $groups->[0] to $nL:
isa_ok($nL->genomes, 'ARRAY');
isa_ok($nL->genomes->[0], 'Bio::Polloc::Genome');

# 42
is($#{$nL->loci}, 1);
isa_ok($nL->loci->[0]->genome, 'Bio::Polloc::Genome');
is($nL->loci->[0]->genome->name, 'multi');
is($nL->loci->[1]->genome->name, 'repeats');
is($nL->loci->[1]->seq_name, 'Scaffold3_woRep');
}

