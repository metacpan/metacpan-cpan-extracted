=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

use strict;
use warnings;
use PDL;
use Photonic::LE::NR2::AllH;
use Photonic::LE::NR2::Field;
use Photonic::LE::NR2::SHP;
use Photonic::LE::NR2::SH;
use Photonic::LE::NR2::SHChiTensor;

use Test::More;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
#Check field for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $gl=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
my $nr=Photonic::LE::NR2::AllH->new(geometry=>$gl, nh=>10, keepStates=>1);
my $flo=Photonic::LE::NR2::Field->new(nr=>$nr, nh=>10);
my $flv=$flo->evaluate($ea, $eb);
my $fla=1/$ea;
my $flb=1/$eb;
my $fproml=$fla*(1-$gl->f)+$flb*($gl->f);
($fla, $flb)=map {$_/$fproml} ($fla, $flb);
my $flx=pdl([$fla*(1-$B)+$flb*$B])->mv(0,-1);
ok(Cagree($flv, $flx), "1D long field") or diag "got: $flv\nexpected: $flx";

#View 2D from 1D superlattice.
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt, Direction0=>pdl([1,0])); #trans
my $nt=Photonic::LE::NR2::AllH->new(geometry=>$gt, nh=>10, keepStates=>1);
my $fto=Photonic::LE::NR2::Field->new(nr=>$nt, nh=>10, filter=>ones(1));
my $ftv=$fto->evaluate($ea, $eb);
my $ftx=pdl(r2C(1), r2C(0));
ok(Cagree($ftv, $ftx), "1D trans field");

my ($dA, $dB) = (0, 1); # vacuum, then anything as is normalised to dB
my $nrshp=Photonic::LE::NR2::SHP->new(
  nrf=>$fto, densityA=>$dA, densityB=>$dB,
);
my $nrsh=Photonic::LE::NR2::SH->new(
  shp=>$nrshp, epsA1=>$ea, epsB1=>$eb,
  epsA2=>$ea*$ea, epsB2=>$eb*$eb, filterflag => 1
);
my $got=$nrsh->dipolar;
my $expected = pdl(<<'EOF');
[
 [ [ 0 0 ] ]
 [ [ 0 -7.9823116e-17+1.1403302e-17i ] ]
 [ [ 0  4.1596509e-17-5.9423584e-18i ] ]
 [ [ 0 -2.9756908e-17+4.2509868e-18i ] ]
 [ [ 0  2.4722933e-17-3.5318475e-18i ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
]
EOF
ok(Cagree($got, $expected), "dipolar") or diag "got: $got\nexpected: $expected";
$got=$nrsh->quadrupolar;
$expected = r2C(pdl <<'EOF');
[
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
]
EOF
ok(Cagree($got, $expected), "quadrupolar") or diag "got: $got\nexpected: $expected";
$got=$nrsh->external_G;
$expected = pdl(<<'EOF');
[
 [ [ 0 -4.3260582e-17+6.1800832e-18i ] ]
 [ [ 0 -5.9528635e-17+2.4920212e-17i ] ]
 [ [ 0 -2.7186406e-17+6.2313278e-17i ] ]
 [ [ 0 -1.2929662e-17+5.3169197e-17i ] ]
 [ [ 0 1.3401775e-17+1.10965e-16i ] ]
 [ [ 0 1.5419056e-16+6.9763677e-17i ] ]
 [ [ 0  1.2848911e-16-1.1014649e-16i ] ]
 [ [ 0 -1.8204495e-17-1.1027889e-16i ] ]
 [ [ 0  -2.729985e-17-4.7422124e-17i ] ]
 [ [ 0 -4.3546668e-17-5.2208553e-17i ] ]
 [ [ 0 -6.4125149e-17-7.2553859e-18i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-33), "external_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->externalL_G;
$expected = pdl(<<'EOF');
[
 [ 0 ]
 [ -5.9528635e-17+2.4920212e-17i ]
 [ -2.7186406e-17+6.2313278e-17i ]
 [ -1.2929662e-17+5.3169197e-17i ]
 [ 1.3401775e-17+1.10965e-16i ]
 [ 1.5419056e-16+6.9763677e-17i ]
 [ -1.2848911e-16+1.1014649e-16i ]
 [ 1.8204495e-17+1.1027889e-16i ]
 [  2.729985e-17+4.7422124e-17i ]
 [ 4.3546668e-17+5.2208553e-17i ]
 [ 6.4125149e-17+7.2553859e-18i ]
]
EOF
ok(Cagree($got, $expected, 1e-33), "externalL_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->externalVecL_G;
$expected = pdl(<<'EOF');
[
 [ [ 0 0 ] ]
 [ [ 0 -5.9528635e-17+2.4920212e-17i ] ]
 [ [ 0 -2.7186406e-17+6.2313278e-17i ] ]
 [ [ 0 -1.2929662e-17+5.3169197e-17i ] ]
 [ [ 0 1.3401775e-17+1.10965e-16i ] ]
 [ [ 0 1.5419056e-16+6.9763677e-17i ] ]
 [ [ 0  1.2848911e-16-1.1014649e-16i ] ]
 [ [ 0 -1.8204495e-17-1.1027889e-16i ] ]
 [ [ 0  -2.729985e-17-4.7422124e-17i ] ]
 [ [ 0 -4.3546668e-17-5.2208553e-17i ] ]
 [ [ 0 -6.4125149e-17-7.2553859e-18i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-33), "externalVecL_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->externalVecL;
$expected = pdl(<<'EOF');
[
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0 -7.5890335e-17+1.0841476e-17i ] ]
 [ [ 0  4.5529289e-17-6.5041841e-18i ] ]
 [ [ 0 -2.5824128e-17+3.6891611e-18i ] ]
 [ [ 0  2.8655713e-17-4.0936733e-18i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
 [ [ 0  3.9327802e-18-5.6182574e-19i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-33), "externalVecL") or diag "got: $got\nexpected: $expected";
$got=$nrsh->externalL_n;
$expected = pdl(<<'EOF');
[
 3.2531646e-16-8.2814988e-33i
 0
]
EOF
ok(Cagree($got, $expected, 1e-33), "externalL_n") or diag "got: $got\nexpected: $expected";
$got=$nrsh->externalL_G;
$expected = pdl(<<'EOF');
[
 [ 0 ]
 [ -5.9528635e-17+2.4920212e-17i ]
 [ -2.7186406e-17+6.2313278e-17i ]
 [ -1.2929662e-17+5.3169197e-17i ]
 [ 1.3401775e-17+1.10965e-16i ]
 [ 1.5419056e-16+6.9763677e-17i ]
 [ -1.2848911e-16+1.1014649e-16i ]
 [ 1.8204495e-17+1.1027889e-16i ]
 [  2.729985e-17+4.7422124e-17i ]
 [ 4.3546668e-17+5.2208553e-17i ]
 [ 6.4125149e-17+7.2553859e-18i ]
]
EOF
ok(Cagree($got, $expected, 1e-33), "externalL_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->selfConsistentL_G;
$expected = pdl(<<'EOF');
[
 [ 0 ]
 [ 2.3385878e-18+1.910126e-18i ]
 [ 2.7283262e-18+2.436351e-19i ]
 [ 2.3719287e-18+6.4418678e-20i ]
 [ 4.2223945e-18-1.807201e-18i ]
 [  9.5067349e-19-6.5454932e-18i ]
 [ 5.5266405e-18+3.6340151e-18i ]
 [  4.1237233e-18-2.0133211e-18i ]
 [  1.4476152e-18-1.8171605e-18i ]
 [  1.6228705e-18-2.2408099e-18i ]
 [ -4.4470906e-20-3.1472783e-18i ]
]
EOF
ok(Cagree($got, $expected, 1e-35), "selfConsistentL_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->selfConsistentVecL_G;
$expected = pdl(<<'EOF');
[
 [ [ 0 0 ] ]
 [ [ 0 2.3385878e-18+1.910126e-18i ] ]
 [ [ 0 2.7283262e-18+2.436351e-19i ] ]
 [ [ 0 2.3719287e-18+6.4418678e-20i ] ]
 [ [ 0 4.2223945e-18-1.807201e-18i ] ]
 [ [ 0  9.5067349e-19-6.5454932e-18i ] ]
 [ [ 0 -5.5266405e-18-3.6340151e-18i ] ]
 [ [ 0 -4.1237233e-18+2.0133211e-18i ] ]
 [ [ 0 -1.4476152e-18+1.8171605e-18i ] ]
 [ [ 0 -1.6228705e-18+2.2408099e-18i ] ]
 [ [ 0 4.4470906e-20+3.1472783e-18i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-35), "selfConsistentVecL_G") or diag "got: $got\nexpected: $expected";
$got=$nrsh->selfConsistentVecL;
$expected = pdl(<<'EOF');
[
 [ [ 0 -5.8607157e-21-4.999633e-20i ] ]
 [ [ 0  1.326045e-18+2.8874943e-18i ] ]
 [ [ 0 -6.9992818e-19-1.5807479e-18i ] ]
 [ [ 0  4.9065455e-19+1.0450579e-18i ] ]
 [ [ 0 -4.183805e-19-9.5980025e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
 [ [ 0 -1.1542169e-19-2.2366796e-19i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-35), "selfConsistentVecL") or diag "got: $got\nexpected: $expected";
$got=$nrsh->alpha1;
$expected = pdl(<<'EOF');
[
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
]
EOF
ok(Cagree($got, $expected), "alpha1") or diag "got: $got\nexpected: $expected";
$got=$nrsh->alpha1;
$expected = pdl(<<'EOF');
[
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
 [ 0.15915494+0.31830989i ]
]
EOF
ok(Cagree($got, $expected), "alpha2") or diag "got: $got\nexpected: $expected";
$got=$nrsh->field2;
$expected = pdl(<<'EOF');
-0.6756993-0.10576923i
EOF
ok(Cagree($got, $expected), "field2") or diag "got: $got\nexpected: $expected";
$got=$nrsh->P2;
$expected = pdl(<<'EOF');
[
 [ [ 0 -1.2467976e-18-2.5931346e-19i ] ]
 [ [ 0 8.5108064e-20+2.6781772e-18i ] ]
 [ [ 0 -1.9408651e-18-1.790065e-18i ] ]
 [ [ 0 -7.5028237e-19+8.3574075e-19i ] ]
 [ [ 0 -1.6593174e-18-1.1691174e-18i ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
 [ [ 0 0 ] ]
]
EOF
ok(Cagree($got, $expected), "P2") or diag "got: $got\nexpected: $expected";
$got=$nrsh->u1;
$expected = pdl(<<'EOF');
-0.22115385-0.10576923i
EOF
ok(Cagree($got, $expected), "u1") or diag "got: $got\nexpected: $expected";
$got=$nrsh->P2LMCalt;
$expected = pdl(<<'EOF');
[
 [ [ 0 -4.7586641e-16+6.7980915e-17i ] ]
]
EOF
ok(Cagree($got, $expected, 1e-46), "P2LMCalt") or diag "got: $got\nexpected: $expected";

my $chi=Photonic::LE::NR2::SHChiTensor->new(
  geometry=>$gl,
  densityA=>$dA, densityB=>$dB, nhf=>10, nh=>10,
  keepStates=>1,
);
$got = Photonic::LE::NR2::SH->new(
  shp=>$chi->nrshp->[0], epsA1=>$ea, epsB1=>$eb,
  epsA2=>$ea*$ea, epsB2=>$eb*$eb, filterflag=>0
)->P2;
$expected = pdl(<<'EOF');
[
 [ 0.0070072648+0.0097445079i ]
 [ -0.0019177555-0.002666887i ]
 [ -2.7383241e-17+8.8425853e-18i ]
 [ 0.0019177555+0.002666887i ]
 [ -0.0070072648-0.0097445079i ]
 [  0.014991596-0.011757369i ]
 [ -0.0083074514+0.0065152354i ]
 [  0.0067611307-0.0053025117i ]
 [ -0.0067611307+0.0053025117i ]
 [  0.0083074514-0.0065152354i ]
 [ -0.014991596+0.011757369i ]
]
EOF
ok(Cagree($got, $expected, 1e-18), "SHChiTensor SHPs P2") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb);
$expected = pdl(<<'EOF');
[ [ [ 2.06087e-17+3.64698e-17i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-41), "P2") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'f', mask => pdl(1));
$expected = pdl(<<'EOF');
[ [ [ 4.0239976e-18-9.855343e-19i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-50), "P2") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'l');
$expected = pdl(<<'EOF');
[ [ [ 1.4979937e-18+3.6442788e-18i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-51), "selfConsistentVecL") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'a');
$expected = pdl(<<'EOF');
[ [ [ -4.890401e-16+5.6504395e-16i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-47), "P2LMCalt") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'd');
$expected = pdl(<<'EOF');
[ [ [ 5.0464683e-18+2.5232341e-18i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-50), "dipolar") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'q');
$expected = pdl(<<'EOF');
[ [ [ 1.5770213e-19+3.1540427e-19i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-50), "quadrupolar") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'e');
$expected = pdl(<<'EOF');
[ [ [ 9.9352345e-18+1.5770213e-18i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-50), "external") or diag "got: $got\nexpected: $expected";
$got = $chi->evaluate($ea, $eb, $ea*$ea, $eb*$eb, kind => 'el');
$expected = pdl(<<'EOF');
[ [ [ 7.2542982e-18+1.4193192e-18i ] ] ]
EOF
ok(Cagree($got, $expected, 1e-50), "externalVecL") or diag "got: $got\nexpected: $expected";

done_testing;
