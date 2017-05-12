use strict;
use warnings;

use Test::More tests => 12;

# 1
use_ok('Bio::Polloc::Genome');

# 2
my $T = Bio::Polloc::Genome->new;
isa_ok($T, 'Bio::Polloc::Genome');
isa_ok($T, 'Bio::Polloc::Polloc::Root');

# 4
$T->file('t/multi.fasta');
is($#{$T->get_sequences}, 3);
isa_ok($T->get_sequences->[0], 'Bio::Seq');
isa_ok($T->get_sequences->[1], 'Bio::Seq');
isa_ok($T->get_sequences->[2], 'Bio::Seq');
isa_ok($T->get_sequences->[3], 'Bio::Seq');

# 9
$T = Bio::Polloc::Genome->new(-file=>'t/multi.fasta');
isa_ok($T, 'Bio::Polloc::Genome');
isa_ok($T->get_sequences->[0], 'Bio::Seq');

# 11
isa_ok($T->search_sequence('SEQ2'), 'Bio::Seq');
is($T->search_sequence('SEQ2')->display_id, 'SEQ2');


