#!/usr/bin/perl

use strict;
use warnings;

use PDLA::LiteF;
use PDLA::Stats;
use PDLA::NiceSlice;
use Test::More;

BEGIN {
  plan tests => 7;
}

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDLA' and $diff = $diff->max;
  return $diff < $eps;
}

# This is the example from Lorch and Myers (1990),
# a study on how characteristics of sentences affected reading time
# Three within-subject IVs:
# SP -- serial position of sentence
# WORDS -- number of words in sentence
# NEW -- number of new arguments in sentence

my ($data, $idv, $ido) = rtable \*DATA, {V=>0};

my %r = $data( ,4)->ols_rptd( $data( ,3), $data( ,(0)), $data( ,1), $data( ,2) );

print "\n";
print "$_\t$r{$_}\n" for (sort keys %r);

is( tapprox( $r{'(ss_total)'}, 405.188241771429 ) , 1, 'ss_total' );
is( tapprox( $r{'(ss_residual)'}, 58.3754646504336 ) , 1, 'ss_residual' );
is( tapprox( $r{'(ss_subject)'}, 51.8590337714289 ) , 1, 'ss_subject' );
is( tapprox( sumover($r{ss} - pdl(18.450705, 73.813294, 0.57026483)), 0 ) , 1, 'ss' );
is( tapprox( sumover($r{ss_err} - pdl(23.036272, 10.827623, 5.0104731)), 0 ) , 1, 'ss_err' );
is( tapprox( sumover($r{coeff} - pdl(0.33337285, 0.45858933, 0.15162986)), 0 ) , 1, 'coeff' );
is( tapprox( sumover($r{F} - pdl(7.208473, 61.354153, 1.0243311)), 0 ) , 1, 'F' );



# Lorch and Myers (1990) data

__DATA__
Snt	Sp	Wrds	New	subj	DV
1	1	13	1	1	3.429
2	2	16	3	1	6.482
3	3	9	2	1	1.714
4	4	9	2	1	3.679
5	5	10	3	1	4.000
6	6	18	4	1	6.973
7	7	6	1	1	2.634
1	1	13	1	2	2.795
2	2	16	3	2	5.411
3	3	9	2	2	2.339
4	4	9	2	2	3.714
5	5	10	3	2	2.902
6	6	18	4	2	8.018
7	7	6	1	2	1.750
1	1	13	1	3	4.161
2	2	16	3	3	4.491
3	3	9	2	3	3.018
4	4	9	2	3	2.866
5	5	10	3	3	2.991
6	6	18	4	3	6.625
7	7	6	1	3	2.268
1	1	13	1	4	3.071
2	2	16	3	4	5.063
3	3	9	2	4	2.464
4	4	9	2	4	2.732
5	5	10	3	4	2.670
6	6	18	4	4	7.571
7	7	6	1	4	2.884
1	1	13	1	5	3.625
2	2	16	3	5	9.295
3	3	9	2	5	6.045
4	4	9	2	5	4.205
5	5	10	3	5	3.884
6	6	18	4	5	8.795
7	7	6	1	5	3.491
1	1	13	1	6	3.161
2	2	16	3	6	5.643
3	3	9	2	6	2.455
4	4	9	2	6	6.241
5	5	10	3	6	3.223
6	6	18	4	6	13.188
7	7	6	1	6	3.688
1	1	13	1	7	3.232
2	2	16	3	7	8.357
3	3	9	2	7	4.920
4	4	9	2	7	3.723
5	5	10	3	7	3.143
6	6	18	4	7	11.170
7	7	6	1	7	2.054
1	1	13	1	8	7.161
2	2	16	3	8	4.313
3	3	9	2	8	3.366
4	4	9	2	8	6.330
5	5	10	3	8	6.143
6	6	18	4	8	6.071
7	7	6	1	8	1.696
1	1	13	1	9	1.536
2	2	16	3	9	2.946
3	3	9	2	9	1.375
4	4	9	2	9	1.152
5	5	10	3	9	2.759
6	6	18	4	9	7.964
7	7	6	1	9	1.455
1	1	13	1	10	4.063
2	2	16	3	10	6.652
3	3	9	2	10	2.179
4	4	9	2	10	3.661
5	5	10	3	10	3.330
6	6	18	4	10	7.866
7	7	6	1	10	3.705
