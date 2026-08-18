use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps qw(identity stretcher gurney);
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Trans qw //;
use PDL::LinearAlgebra::Real;
use Test::More;
use Test::PDL;

sub runtest {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($in, $method, $expected, $extra) = @_;
  $_ = $_->copy for $in;
  ($expected, my $expected_cplx) = ref($expected) eq 'ARRAY' ? @$expected : ($expected, $expected);
  $_ = PDL->topdl($_) for grep defined && !ref, $expected, $expected_cplx;
  my @extra = map UNIVERSAL::isa($_, 'PDL') ? $_->copy : $_, @{$extra||[]};
  if (defined $expected) {
    my ($got) = $in->$method(@extra);
    is_pdl +PDL->topdl($got), $expected, {test_name=>$method, require_equal_types=>0, atol=>1e-3};
  }
  $_ = $_->r2C for $in;
  my ($got) = $in->$method(map ref() && ref() ne 'CODE' ? $_->r2C : $_, @extra);
  $got = PDL->topdl($got);
  my @cplx = ref($expected_cplx) eq 'ARRAY' ? @$expected_cplx : $expected_cplx;
  @cplx = map PDL->topdl($_)->r2C, @cplx;
  my @res = map [Test::PDL::eq_pdl($got, $_, {require_equal_types=>0, atol=>1e-3})], @cplx;
  my $ok = grep $_->[0], @res;
  ok $ok, "native complex $method" or diag explain map $_->[1], @res;
}

my $aa = random(2,2,2);
$aa = czip($aa->slice('(0)'), $aa->slice('(1)'));
runtest($aa, 't', [undef,$aa->xchg(0,1)->conj], [1]);

do './t/common.pl'; die if $@;

is_pdl pdl([1,1,-1],[-1,-1,2])->positivise, pdl([1,1,-1],[1,1,-2]), 'positivise'; # real only

my $a = pdl([[1.7,3.2],[9.2,7.3]]);
my $id = identity(2);
is_pdl $a->minv x $a,$id;

is_pdl $a->mcrossprod->mposinv->tritosym x $a->mcrossprod,$id;

ok($a->mcrossprod->mposdet !=0);

my $A = identity(4) + ones(4, 4);
$A->slice('2,0') .= 0; # if don't break symmetry, don't show need transpose
my $B = sequence(2, 4);
getrf(my $lu=$A->copy, my $ipiv=null, my $info=null);
# if don't transpose the $B input, get memory crashes
getrs($lu, 1, my $x=$B->xchg(0,1)->copy, $ipiv, $info=null);
is_pdl $A x $x->t, $B;

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
is_pdl $A x $x, $B->dummy(0);
is_pdl +((1+sequence(2,2))*i())->mdet, cdouble(2), "Complex mdet";

$A = pdl '[[1+i 2+i][3+i 4+i]]';
$B = identity(2);
is_pdl $A x $B, $A, 'complex first';
is_pdl $B x $A, $A, 'complex second';

my $d = (identity(2) * 2)->sqrt;
is_pdl scalar $d->minv, my $exp = pdl('0.70710678 0; 0 0.70710678'), 'simple minv of double';
my $ld = (identity(2)->ldouble * 2)->sqrt;
is_pdl scalar $ld->minv, $exp->ldouble, 'simple minv of ldouble';

$A=pdl <<'EOF';
[
 [ 3  1]
 [-1  3]
 [-2  3]
]
EOF
my ($u, $s, $vt) = msvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "msvd 2,3";
($u, $s, $vt) = mdsvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "mdsvd 2,3";
$A = sequence(2,3) + i;
($u, $s, $vt) = mdsvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "mdsvd complex 2,3";
($u, $s, $vt) = msvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "msvd complex 2,3";

$A=pdl <<'EOF';
[
 [ 3  1  2]
 [-1  3  0]
]
EOF
($u, $s, $vt) = msvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "msvd 3,2";
($u, $s, $vt) = mdsvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "mdsvd 3,2";
$A = sequence(3,2) + i;
($u, $s, $vt) = mdsvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "mdsvd complex 3,2";
($u, $s, $vt) = msvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "msvd complex 3,2";

$A = pdl([0.43,0.03],[0.75,0.72]);
$B = sequence(2,2);
(my $c, $s, my %ret) = mgsvd($A, $B, U => 1, V => 1, X => 1);
($u, my $v, $x) = @ret{qw(U V X)};
is_pdl $u x stretcher($c) x $x->t, $A, 'mgsvd A';
is_pdl $v x stretcher($s) x $x->t, $B, 'mgsvd B';

$A = pdl '1 2 3 4 21; 5 6 7 8 22; 9 10 11 12 20';
($u, $s, $vt) = mdsvd($A);
is_pdl $u x gurney($s, $A->dims) x $vt, $A, "mdsvd 5,3";
is_pdl $u->t x $u, identity(3), 'U is orthonormal';
is_pdl $vt->t x $vt, identity(5), 'Vt is orthonormal';
my $v_null = $vt->slice(",-1");
is_pdl $A x $v_null->t, zeroes(1,3), 'correct right null-space';

my $rank2 = pdl([1,0,1],[-2,-3,1],[3,3,0]);
for my $in ($rank2, $rank2->cdouble) {
  my $res = $in->mnull;
  is_pdl $in x $res, zeroes($in->type, $res->dim(0), $in->dim(1)), 'mnull '.$in->type;
}

$A = sequence(2,3);
is_pdl $A x $A->mpinv x $A, $A, 'mpinv tall works';
$A = sequence(3,2);
is_pdl $A x $A->mpinv x $A, $A, 'mpinv wide works';
$A = sequence(2,3) + i;
is_pdl $A x $A->mpinv x $A, $A, 'mpinv complex tall works';
$A = sequence(3,2) + i;
is_pdl $A x $A->mpinv x $A, $A, 'mpinv complex wide works';
$A = sequence(2,3,2);
is_pdl $A x $A->mpinv x $A, $A, 'mpinv tall broadcast works';
$A = sequence(2,3,2) + i;
is_pdl $A x $A->mpinv x $A, $A, 'mpinv tall complex broadcast works';

$A = pdl('[0 0 0; 1 2 3; 4 5 6] [1 2 3; 4 8 6; 7 8 9]');
is_pdl $A->mrank, pdl('2 3'), 'mrank broadcasts';

done_testing;
