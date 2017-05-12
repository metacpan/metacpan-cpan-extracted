use PDLA::LiteF;
use Test::More tests => 33;
use Test::Exception;
use Config;

use strict;
use warnings;

sub tapprox {
	my($pa,$pb,$tol) = @_;
	$tol = 1e-14 unless defined $tol;
	all approx $pa, $pb, $tol;
}


my $tol = 1e-14;

use PDLA::MatrixOps;

{
### Check LU decomposition of a simple matrix

my $pa = pdl([1,2,3],[4,5,6],[7,1,1]);
my ($lu, $perm, $par);
lives_ok { ($lu,$perm,$par) = lu_decomp($pa); }; # ran OK
is($par, -1);			    # parity is right
ok(all($perm == pdl(2,1,0)));	    # permutation is right

my $l = $lu->copy;
my $ldiag;
($ldiag = $l->diagonal(0,1)) .= 1; 
my $tmp;
($tmp = $l->slice("2,1"))   .= 0;
($tmp = $l->slice("1:2,0")) .= 0;

my $u = $lu->copy;
($tmp = $u->slice("1,2"))   .= 0;
($tmp = $u->slice("0,1:2")) .= 0;

ok(tapprox($pa,matmult($l,$u)->slice(":,-1:0"),$tol)); # LU = A (after depermutation)
}

{
### Check LU decomposition of an OK singular matrix

my $pb = pdl([1,2,3],[4,5,6],[7,8,9]);
my ($lu,$perm,$par) = lu_decomp($pb);

ok(defined $lu);
ok($lu->flat->abs->at(-1) < $tol);
}

{
### Check inversion -- this also checks lu_backsub

my $pa = pdl([1,2,3],[4,5,6],[7,1,1]);
my $opt ={s=>1,lu=>\my @a};
my $a1 = inv($pa, $opt);
my $identity = zeroes(3,3); (my $tmp = $identity->diagonal(0,1))++;

ok(defined $a1);
ok(ref ($opt->{lu}->[0]) eq 'PDLA');
ok(tapprox(matmult($a1,$pa),$identity,$tol));
}

{
### Check inv() with added thread dims (simple check)
my $C22 = pdl([5,5],[5,7.5]);
my $C22inv;
lives_ok { $C22inv = $C22->inv };                           # ran OK
ok(tapprox($C22inv,pdl([0.6, -0.4], [-0.4, 0.4])));	    # right answer
my $C222 = $C22->dummy(2,2);
my $C222inv;
lives_ok { $C222inv = $C222->inv };                              # ran OK
ok(tapprox($C222inv,pdl([0.6, -0.4], [-0.4, 0.4])->dummy(2,2)));    # right answer
}

{
### Check inv() for matrices with added thread dims (bug #3172882 on sf.net)
my $a94 = pdl( [  1,  0,  4, -1, -1, -3,  0,  1,  0 ],
	       [  4, -4, -5,  1, -5, -3, -1, -2,  0 ],
	       [ -2,  2, -5, -1,  1, -3, -4,  3, -4 ],
	       [ -1,  4, -4,  2,  1,  3, -3, -4, -3 ],
	     );
my $a334 = $a94->reshape(3,3,4);
my $a334inv;
lives_ok { $a334inv = $a334->inv };                          # ran OK
my $identity = zeroes(3,3); (my $tmp = $identity->diagonal(0,1))++;
ok(tapprox(matmult($a334,$a334inv),$identity->dummy(2,4)));     # right answer

undef $a94;       # clean up variables
undef $a334;      # clean up variables
undef $a334inv;   # clean up variables
}

{
### Check LU backsubstitution (bug #2023711 on sf.net)


my $pa = pdl([[2,1],[1,2]]);
my ($lu,$perm,$par);
lives_ok { ($lu,$perm,$par) = lu_decomp($pa) }; # ran OK
ok($par==1);			     # parity is right
ok(all($perm == pdl(0,1)));	      # permutation is right

my $bb = pdl([1,0]);
my $xx;
lives_ok { $xx = lu_backsub($lu,$perm,$bb) }; # ran OK
my $xx_shape = pdl($xx->dims);
my $bb_shape = pdl($bb->dims);
ok(all($xx_shape == $bb_shape));	# check that soln and input have same shape
ok(tapprox($xx,pdl([2/3, -1/3]),$tol));     # LU = A (after depermutation)
}

{
### Check attempted inversion of a singular matrix
my $b2 = undef; # avoid warning from compiler
my $pb = pdl([1,2,3],[4,5,6],[7,8,9]);
lives_ok { $b2 = inv($pb,{s=>1}) };
ok(!defined $b2);

}

{
### Check threaded determinant -- simultaneous recursive det of four 4x4's
my $pa = pdl([3,4,5,6],[6,7,8,9],[9,0,7,6],[4,3,2,0]); # det=48
my $pb = pdl([1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]); # det=1
my $c = pdl([0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]); # det=-1
my $d = pdl([1,2,3,4],[5,4,3,2],[0,0,3,0],[3,0,1,6]); # det=-216
my $e = ($pa->cat($pb)) -> cat( $c->cat($d) );
my $det = $e->determinant;
ok(all($det == pdl([48,1],[-1,-216])));
}

{
### Check identity and stretcher matrices...
ok((identity(2)->flat == pdl(1,0,0,1))->all);

ok((stretcher(pdl(2,3))->flat == pdl(2,0,0,3))->all);

ok((stretcher(pdl([2,3],[3,4]))->flat == pdl(2,0,0,3,3,0,0,4))->all);
}

{
### Check eigens
my $pa = pdl([3,4],[4,-3]);

### Check that eigens runs OK
my ($vec,$val);
lives_ok { ($vec,$val) = eigens $pa };

### Check that it really returns eigenvectors
my $c = float(($pa x $vec) / $vec);
#print "c is $c\n";
ok(all($c->slice(":,0") == $c->slice(":,1")));

### Check that the eigenvalues are correct for this matrix
ok((float($val->slice("0")) == - float($val->slice("1")) and 
	float($val->slice("0") * $val->slice("1")) == float(-25)));
}

{
### Check computations on larger matrix with known eigenvalue sum.
my $m = pdl(
   [ 1.638,  2.153,  1.482,  1.695, -0.557, -2.443,  -0.71,  1.983],
   [ 2.153,  3.596,  2.461,  2.436, -0.591, -3.711, -0.493,  2.434],
   [ 1.482,  2.461,    2.5,  2.834, -0.665, -2.621,  0.248,  1.738],
   [ 1.695,  2.436,  2.834,  4.704, -0.629, -2.913,  0.576,  2.471],
   [-0.557, -0.591, -0.665, -0.629,     19,  0.896,  8.622, -0.254],
   [-2.443, -3.711, -2.621, -2.913,  0.896,  5.856,  1.357, -2.915],
   [ -0.71, -0.493,  0.248,  0.576,  8.622,  1.357,   20.8, -0.622],
   [ 1.983,  2.434,  1.738,  2.471, -0.254, -2.915, -0.622,  3.214]);

{
my $esum=0;
my ($vec,$val);
eval {
    ($vec,$val) = eigens($m);
    $esum=sprintf "%.3f", sum($val); #signature of eigenvalues
};
#print STDERR "eigensum for the 8x8: $esum\n";
ok($esum == 61.308);
}

{
my $esum=0;
lives_ok {
    $esum = sprintf "%.3f", sum scalar eigens_sym($m);
};
ok($esum == 61.308);
}

}

{
if(0){ #fails because of bad eigenvectors
#Check an assymmetric matrix:
my $pa = pdl ([4,-1], [2,1]);
my $esum;
my ($vec,$val);
lives_ok {
    ($vec,$val) = eigens $pa;
    $esum=sprintf "%.3f", sum($val);
};
ok($esum == 5);
}
}


{
if(0){ #eigens for asymmetric matrices disbled
#The below matrix has complex eigenvalues
my $should_be_nan = eval { sum(scalar eigens(pdl([1,1],[-1,1]))) };
ok( ! ($should_be_nan == $should_be_nan)); #only NaN is not equal to itself
}
}
