#!perl
use Test::More;
use Term::ANSIColor 2.01 qw(colorstrip color);
use Term::DNAColor qw(colordna colorrna);

use lib 't/lib';
use Test::RandomDNASeq;

for (1..20) {
    my $random_seq = random_rna();
    my $color_dna_seq = colordna($random_seq);
    my $color_rna_seq = colorrna($random_seq);
    is($color_rna_seq, $color_dna_seq, "colorrna produced the same output as colordna");
}

done_testing();
