use strict;
use warnings;
use PDL::LiteF;
use PDL::MatrixOps qw(identity);
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Trans qw //;
use PDL::LinearAlgebra::Real;
use Test::More;

sub fapprox {
	my($a,$b) = @_;
	(PDL->topdl($a)-$b)->abs->max < 0.001;
}
sub runtest {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($in, $method, $expected, $extra) = @_;
  ($expected, my $expected_cplx) = ref($expected) eq 'ARRAY' ? @$expected : ($expected, $expected);
  if (defined $expected) {
    my ($got) = $in->$method(@{$extra||[]});
    ok fapprox($got, $expected), $method or diag "got(".ref($got)."): $got";
  }
  $_ = PDL->topdl($_)->r2C for $in;
  my ($got) = $in->$method(map ref() && ref() ne 'CODE' ? $_->r2C : $_, @{$extra||[]});
  my @cplx = ref($expected_cplx) eq 'ARRAY' ? @$expected_cplx : $expected_cplx;
  my $ok = grep fapprox($got, PDL->topdl($_)->r2C), @cplx;
  ok $ok, "native complex $method" or diag "got(".ref($got)."): $got\nexpected:@cplx";
}

my $aa = random(2,2,2);
$aa = czip($aa->slice('(0)'), $aa->slice('(1)'));
runtest($aa, 't', [undef,$aa->xchg(0,1)->conj], [1]);

do './t/common.pl'; die if $@;

ok all(approx pdl([1,1,-1],[-1,-1,2])->positivise, pdl([1,1,-1],[1,1,-2])), 'positivise'; # real only

my $a = pdl([[1.7,3.2],[9.2,7.3]]);
my $id = identity(2);
ok(fapprox($a->minv x $a,$id));

ok(fapprox($a->mcrossprod->mposinv->tritosym x $a->mcrossprod,$id));

ok($a->mcrossprod->mposdet !=0);

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
my $i=pdl('i'); # Can't use i() as it gets confused by PDL::Complex's i()
my $complex_matrix=(1+sequence(2,2))*$i;
$got=$complex_matrix->mdet;
ok(fapprox($got, 2), "Complex mdet") or diag "got $got";

done_testing;
