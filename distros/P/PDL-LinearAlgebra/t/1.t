use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps qw(identity);
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Trans qw //;
use PDL::LinearAlgebra::Real;
use PDL::Complex;
use Test::More;

sub fapprox {
	my($a,$b) = @_;
	($a-$b)->abs->max < 0.0001;
}

my $a = pdl([[1.7,3.2],[9.2,7.3]]);
ok(fapprox($a->t,$a->xchg(0,1)));

my $aa = cplx random(2,2,2);
ok(fapprox($aa->t(0),$aa->xchg(1,2)));

my $id = pdl([[1,0],[0,1]]);
ok(fapprox($a->minv x $a,$id));

ok(fapprox($a->mcrossprod->mposinv->tritosym x $a->mcrossprod,$id));

ok(fapprox($a->mdet ,-17.03 ));

ok($a->mcrossprod->mposdet !=0);


ok(fapprox($a->mcos->macos,pdl([[1.7018092, 0.093001244],[0.26737858,1.8645614]])));
ok(fapprox($a->msin->masin,pdl([[ -1.4397834,0.093001244],[0.26737858,-1.2770313]])));
ok(fapprox($a->mexp->mlog,$a));

my $A = identity(4) + ones(4, 4);
$A->slice('2,0') .= 0; # if don't break symmetry, don't show need transpose
my $B = sequence(2, 4);
getrf(my $lu=$A->copy, my $ipiv=null, my $info=null);
# if don't transpose the $B input, get memory crashes
getrs($lu, 1, my $x=$B->xchg(0,1)->copy, $ipiv, $info=null);
$x = $x->inplace->xchg(0,1);
my $got = $A x $x;
ok fapprox($got, $B) or diag "got: $got";

$A=pdl cdouble, <<'EOF';
[
 [  1   0   0   0   0   0]
 [0.5   1   0 0.5   0   0]
 [0.5   0   1   0   0 0.5]
 [  0   0   0   1   0   0]
 [  0   0   0 0.5   1 0.5]
 [  0   0   0   0   0   1]
]
EOF
PDL::LinearAlgebra::Complex::cgetrf($lu=$A->copy, $ipiv=null, $info=null);
is $info, 0, 'cgetrf native worked';
is $ipiv->nelem, 6, 'cgetrf gave right-sized ipiv';
$B=pdl q[0.233178433563939+0.298197173371207i 1.09431208340166+1.30493506686269i 1.09216041861621+0.794394153882734i 0.55609433247125+0.515431151337765i 0.439100406078467+1.39139453403467i 0.252359761958406+0.570614019329113i];
PDL::LinearAlgebra::Complex::cgetrs($lu, 1, $x=$B->copy, $ipiv, $info=null);
is $info, 0;
$x = $x->dummy(0); # transpose; xchg rightly fails if 1-D
$got = $A x $x;
ok fapprox($got, $B->dummy(0)) or diag "got: $got";

done_testing;
