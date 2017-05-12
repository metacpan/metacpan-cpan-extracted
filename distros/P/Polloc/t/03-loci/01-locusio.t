use strict;
use warnings;

use Test::More tests => 24;

# 1
use_ok('Bio::Polloc::LocusIO');
use_ok('Bio::Polloc::Genome');

# 3
my $I = Bio::Polloc::LocusIO->new(-file=>'t/loci.gff3', -format=>'Gff3');
isa_ok($I, 'Bio::Polloc::LocusIO');
isa_ok($I, 'Bio::Polloc::LocusIO::gff3');

#5
my $loci = $I->read_loci;
isa_ok($loci, 'Bio::Polloc::LociGroup');
is($#{$loci->loci}, 81);

# 7
my $l1 = $loci->loci->[0];
isa_ok($l1, 'Bio::Polloc::LocusI');
isa_ok($l1, 'Bio::Polloc::Locus::repeat');

# 9
ok($l1->error, 'First locus have errors');
is($l1->error, 3);

# 11
is($l1->seq_name, 'Scaffold1');

# 12
my $O = Bio::Polloc::LocusIO->new(-fh=>\*STDOUT, -format=>'Gff3');
isa_ok($O, 'Bio::Polloc::LocusIO');
isa_ok($O, 'Bio::Polloc::LocusIO::gff3');

# 14
$O->write_locus($loci->loci->[0]);
$O->write_locus($loci->loci->[1]);
$O->write_locus($loci->loci->[2]);
$O->close;
my $I2 = Bio::Polloc::LocusIO->new(-file=>'t/loci_out.gff3', -format=>'Gff3');
my $loci2 = $I2->read_loci;
isa_ok($loci2, 'Bio::Polloc::LociGroup');
isa_ok($loci2->loci, 'ARRAY');
is($#{$loci2->loci}, 2);

# 17
my $l1_2 = $loci2->loci->[0];
is($l1->id, $l1_2->id);
is($l1->name, $l1_2->name);
is($l1->seq_name, $l1_2->seq_name);
is($l1->source, $l1_2->source);
is($l1->family, $l1_2->family);

# 22
my $ext = $loci->loci->[71];
isa_ok($ext, 'Bio::Polloc::Locus::extend');
isa_ok($ext->basefeature, 'Bio::Polloc::Locus::repeat');
is($ext->basefeature->id, 'VNTR:2.14');

