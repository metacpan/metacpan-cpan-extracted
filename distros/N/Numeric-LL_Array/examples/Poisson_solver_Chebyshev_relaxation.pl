#!/usr/bin/perl -w
use strict;
use blib;
use Numeric::LL_Array qw( access_d packId_d packId_star_d d0_1
			  d2d1_plus_assign d2d1_assign
			  dd2d2_sproduct d2d1_mult_assign );

die <<EOD unless @ARGV==3;
Usage: $0 width+2 height+2 number_of_2x_relaxations
  Runs Chebyshev_relaxation steps for Dirichlet problem for Poisson equation.
EOD

sub typeout ($$$) {
  my ($p, $w, $h) = @_;
  my @a = access_d $p, 0, 2, [1, $w, $w, $h];
  print "@$_\n" for @a;
}

my ($w, $h, $steps) = (shift, shift, shift);	# 10 means: 8, plus 2 for boundary
my ($tile_w, $tile_h) = map int($_/2-1), $w, $h; # Will fill $tile x $tile zone

my $sec = pack packId_star_d, 0..$w+$h+10;

my ($quarter, $half) = map pack(packId_d, $_), 0.25, 0.5;
my $zero = my $p = pack packId_d, 0;
$p x= ($w * $h);		# Main Playground
my $p1 = $p;			# Temporary var
my $fmt = [1, $w, $w, $h];

d0_1 $p, $w+1, 2, [1, $tile_w, $w, $tile_h];
# typeout $p, $w, $h;

d2d1_plus_assign $p, $p, $w+1, $w+2, 2,
  [1,$tile_w, $w, $tile_h], [1,$tile_w-1, $w, $tile_h];
d2d1_plus_assign $p, $p, $w+1, 2*$w+1, 2,
  [1,$tile_w, $w, $tile_h], [1,$tile_w, $w, $tile_h-1];

if (0) {	# On boundary, initialize to a linear function
  d2d1_assign $sec, $p, $w+$h, 0, 1,
    [-1,$w], [1,$w];
  d2d1_assign $sec, $p, $w+1, $w*($h-1), 1,
    [-1,$w], [1,$w];
  d2d1_assign $sec, $p, $w+$h, 0, 1,
    [-1,$w], [$w,$h];
  d2d1_assign $sec, $p, 1+$h, $h-1, 1,
    [-1,$w], [$w,$h];
}
typeout $p, $w, $h if $w*$h < 1000;	# In a quadrant, initialize to x * y

sub Poisson_4__4 ($$$$) {	# Spectrum normalized 4 --> -4
  my ($s_r, $t_r, $w, $h) = @_;		# references to playgrounds
  d2d1_assign $$s_r, $$t_r, 0, 0, 2,	# Exact copy
    [1,$w, $w, $h], [1,$w, $w, $h];
  # Add shift by (-1,1): take shift by (0,1), and add to shift by (1,0)
  d2d1_plus_assign $$t_r, $$t_r, $w, 1, 2,  # correct in $w-1 x $h-1 rectangle
    [1,$w-1, $w, $h-1], [1,$w-1, $w, $h-1]; # starting at (1,0)
  # Add shift by (1,1): take shift by (0,1), and add to shift by (1,0)
  d2d1_plus_assign $$t_r, $$t_r, $w+2, 1, 2,
    [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2];
}  # The result is $w-2 x $w - 2 starting at offset (1,0)

sub Poisson_1_0 ($$$$) {	# Spectrum normalized 1 --> 0
  &Poisson_4__4;		# Second argument: temporary playground
  my ($t_r, $tmp_r, $w, $h) = @_;		# references to playgrounds
  dd2d2_sproduct($quarter, $$tmp_r, $$t_r, 0, 1, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2]);
  d2d1_mult_assign($half, $$t_r, 0, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2]);
}

sub Poisson_1_r ($$$$$) {	# Spectrum normalized 1 --> ? so that $r |--> 0
  &Poisson_4__4;		# Second argument: temporary playground
  my ($t_r, $tmp_r, $w, $h, $r) = @_;		# references to playgrounds
  # Want a+b(4-8x) = 1 - x/r; so b = 1/8r; a = 1-4b = 1-1/(2r)
  my ($a, $b) = map pack(packId_d, $_), 1-1/(2*$r), 1/(8*$r);
  d2d1_mult_assign($a, $$t_r, 0, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2]);
  dd2d2_sproduct($b, $$tmp_r, $$t_r, 0, 1, $w+1, 2,
		 [0,$w-2, 0, $h-2], [1,$w-2, $w, $h-2], [1,$w-2, $w, $h-2]);
}

sub norm ($$$$) {
  my ($p, $off, $d, $format) = @_;
  my $res = $zero;
  my $s_format = [@$format];
  $s_format->[2*$_] = 0 for 0..$d-1;
  dd2d2_sproduct $$p, $$p, $res, $off, $off, 0, $d, $format, $format, $s_format;
  sqrt unpack packId_d, $res;
}

# Poisson_1_r \$p, \$p1, $w, $h, 1;
# typeout $p, $w, $h;

sub permute3 ($);
sub permute3 ($) {	# known to behave well (is mixing) for 3^n
  my $n = shift;
  return [0..$n-1] if $n <= 2;
  my $n1 = int($n/3);
  my $p = permute3($n1);
  my $r = [];
  for my $k (0 .. $n1-1) {
    my $pk = $p->[$k];
    push @$r, $pk, 2*$n1 - 1 - $pk, $n - 1 - $pk;
  }
  my $n2 = $n % 3;     # $n2 elements 2 $n1 , etc not included; tackle at end
  push @$r, 2*$n1..(2*$n1+$n2-1);
  $r
}		# Experiments show it is good for "many" n

# my $p5 = permute3(5); print "<<@$p5>>\n";
# my $p16 = permute3(16); print "<<@$p16>>\n";

# Min wavenumber is 1/2(W-1), 1/2(H-1), max is (1,0).
# So min normalized eigenvalue is (2-cos(pi/(w-1))-cos(pi/(h-1)))/4
# approx. pi^2/8*(1/($w-1)^2 + 1/($h-1)^2)

# Chebyshev poly Tn takes value 2 at cosh(1.32/n), approx 1 + 1.32^2/2n^2;
# so one can get below 1/2 on the interval [1.74/4n^2, 1].  So if the minimal
# eigenvalue is a, n=1.32/2sqrt(a) is good.
# One gets sqrt(2)/pi (w-1)(h-1)/sqrt((w-1)^2 + (h-1)^2).

my $pi = 4*atan2(1,1);
# Asymptotic approximation; later we overwrite this (it is too optimistic!):
my $min_eigen = $pi**2/8 * (1/($w-1)**2 + 1/($h-1)**2);
my $N = 1 + int(1.32/2/sqrt($min_eigen));
my $P = permute3($N);
my $d = $pi/$N;
print "N=$N,   eigen=$min_eigen..1;    <<@$P>>\n";

$_ = cos(($_ + 0.5)*$d)		for @$P;	# map to zeros of Tn, in [-1,1]
$_ = 1-(1-$min_eigen)*(1+$_)/2	for @$P;	# map -1 to 1, 1 to $min_eigen

my $expect = 1 + $min_eigen * 2/(1-$min_eigen); # Rescale back to [-1,1]
# a+1/a = 2 $expect; or a = $expect + sqrt($expect^2 - 1)
$expect = $N*log($expect + sqrt($expect**2 - 1));	# $N * inv cosh
$expect = (exp($expect) + exp(-$expect))/2;	# cosh
print "expected relaxation = $expect\nzeros <<@$P>>\n";

# Just in case, calculate actual eigenvalues of Dirichlet problem
my($min, $max, $relax, $relax1) = (1e100, 0, 1e100, 1e100);
for my $hor (1..$w-2) {
  for my $vert (1..$h-2) {
    my $eigen = 2 - cos($pi*$hor/($w-1)) - cos($pi*$vert/($h-1));
    $eigen /= 4;		# Normalize to 1 at Nyquist
    $min = $eigen  if $eigen < $min;
    $max = $eigen  if $eigen > $max;
    my $val = 1;
    $val *= 1 - $eigen/$P->[$_] for 0..$N-1;
    $relax = 1/$val  if $val > 1/$relax;
    $relax1 = 1/$val  if $val > 1/$relax1 and $hor * $vert > 1;
  }
}
my $relax_error = $relax/$expect;
print "eigenvalues min .. max = $min .. $max; relaxation = $relax\n";
print "relaxation_error (better be 1 or more) = $relax_error\n";
print "relaxation above (1,1) mode = $relax1\n";
$expect = $relax;

my $pre = my $prev = norm(\$p, 0, 2, [1,$w, $w, $h]);
# k-th root of n-th Chebyshev polynomial is cos (k-1/2) pi/n
# rescaling from [-1,1] to [0,1], get 0.5 - 0.5*cos (k-1/2) pi/n
for my $iter (1..$steps) {
  for my $step (0..$N-1) {
    Poisson_1_r \$p, \$p1, $w, $h, $P->[$step];
  }
  my $n = norm(\$p, 0, 2, [1,$w, $w, $h]);
  my @relax = map $expect/$_, ($prev/$n, ($pre/$n)**(1/(1+$iter)));
  #print "post-$iter: norm=$n\n";
  print "post-$iter: loc/glob relax (rel to expect, must be 1 or less): @relax\n";
  $prev = $n;
}
# typeout $p, $w, $h;
