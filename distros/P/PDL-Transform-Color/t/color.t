use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::Transform;
use PDL::Transform::Color;
use Test::PDL;

##########
## test t_gamma
my $t = PDL::Transform::Color::t_gamma(2);
my $itriplet = pdl(0.5,0,1.0);
is_pdl $itriplet->apply($t), $itriplet**2, "gamma=2 squares the output";
is_pdl $itriplet->invert($t), $itriplet**0.5, "gamma=2 inverse square-roots the output";

$itriplet = pdl(-0.5,0,1);
is_pdl $itriplet->apply($t), pdl('-0.25 0 1'), "gamma=2 correct with negative inputs";
is_pdl $itriplet->invert($t), pdl('-0.707106 0 1'), "gamma=2 inverse correct with negative inputs";

##########
# test t_brgb
$t = t_brgb(display_gamma=>1);
$itriplet = pdl(0,0.5,1.0);
my $otriplet = $itriplet->apply($t);
is_pdl $otriplet, byte(0,128,255), {atol=>1,test_name=>"gives correct values"};
is_pdl $otriplet->invert($t), $itriplet, {atol=>1e-2, test_name=>"reverse transform gives correct values"};
$t = t_brgb(b=>1, display_gamma=>1);
$otriplet = $itriplet->apply($t);
is_pdl $otriplet, byte(0,128,255),{atol=>1,test_name=>"with b option gives correct byte values"};
is_pdl $otriplet->invert($t), $itriplet, {atol=>1e-2, test_name=>"reverse transform gives correct values"};
is_pdl $itriplet->apply(t_brgb(gamma=>0.5,b=>1,display_gamma=>1)), byte(0, 180, 255),{atol=>1,test_name=>"gamma correction on nRGB side works (got $otriplet)"};
is_pdl $itriplet->apply(t_brgb()), pdl(byte, 0, 186, 255), {atol=>1,test_name=>"default output gamma correction is 2.2 for t_brgb)"};

##########
# test t_cmyk
$t = t_cmyk();
$itriplet = pdl(0.341,0.341,0.341);
$otriplet = $itriplet->apply($t);
is_pdl $otriplet, pdl('[0 0 0 0.659]'), 't_cmyk';
is_pdl $otriplet->invert($t), $itriplet, {atol=>1e-4, test_name=>"reverse gets the original"};
$itriplet = pdl(0.25,0.35,0.45);
$otriplet = $itriplet->apply($t);
is_pdl $otriplet, pdl(0.444444,0.222222,0,0.55), {atol=>1e-4, test_name=>"random non-grey sample"};
is_pdl $otriplet->invert($t), $itriplet, {atol=>1e-4, test_name=>"non-grey sample inverts correctly"};

##########
# test t_xyz
$itriplet = pdl([1,0,0],[0,1,0],[0,0,1]);
for my $trans (t_xyz(), t_xyz(rgb_system=>'sRGB')) {
  $otriplet = $itriplet->apply($trans);
  # Check against chromaticities of the sRGB primaries
  my $xpypzptriplet = $otriplet / $otriplet->sumover->slice('*1');
  is_pdl $xpypzptriplet->slice('0:1'),
    pdl('0.640 0.330; 0.300 0.600; 0.150 0.060'),
    {atol=>1e-3, test_name=>"XYZ translation works for R, G, and B vectors ($trans)"};
  my $i2triplet = $otriplet->invert($trans);
  is_pdl $i2triplet, $itriplet, {atol=>1e-3, test_name=>"t_xyz inverse works OK ($trans)"};
}

##########
# test t_rgi
my $brgbcmyw = pdl([0,0,0],
		   [1,0,0],[0,1,0],[0,0,1],
		   [0,1,1],[1,0,1],[1,1,0],
		   [1,1,1]);
is_pdl $brgbcmyw->apply(t_rgi()), pdl(
  [0,0,0],
  [1 , 0 ,   0.3333333 ], [ 0 , 1 ,   0.3333333 ], [ 0 , 0 ,    0.3333333],
  [0 , 0.5 , 0.6666667 ], [ 0.5 , 0 , 0.6666667 ], [0.5 , 0.5 , 0.6666667],
  [0.3333333 , 0.3333333 , 1]
), {atol=>1e-4, test_name=>"t_rgi passees 8-color test"};

##########
# test t_hsl and t_hsv
$t = t_hsl();
my $hsltest = $brgbcmyw->apply($t);
is_pdl $hsltest,
  pdl([0,0,0],[0,1,0.5],[0.333,1,0.5],[0.667,1,0.5],[0.500,1,0.5],[0.833,1,0.5],[0.167,1,0.5],[0,0,1]),
  {atol=>1e-3, test_name=>"hsl forward yielded correct values"};
is_pdl $hsltest->invert($t), $brgbcmyw, {atol=>1e-4, test_name=>"t_hsl gave good reverse answers"};

$t = t_hsv();
$hsltest = $brgbcmyw->apply($t);
is_pdl $hsltest,
  pdl([0,0,0],[0,1,1],[0.333,1,1],[0.667,1,1],[0.500,1,1],[0.833,1,1],[0.167,1,1],[0,0,1]),
  {atol=>1e-3, test_name=>"hsv forward yielded correct values"};
is_pdl $hsltest->invert($t), $brgbcmyw, {atol=>1e-4, test_name=>"t_hsv gave good reverse answers"};

{
##########
# test _srgb_encode and _srgb_decode
my $a = sequence(3,8)/255;
my $t = t_srgb();
my $b = (my $bfull = $a->apply($t))->flat;
ok(all($b+1e-10 > $a->flat), "_srgb_encode output is always larger than input on [0,1]");
my $slope1 = $b->slice('1:-1');
my $slope2 = $b->slice('0:-2');
ok(all($slope1>$slope2),"_srgb_encode output is monotonically increasing") or diag $slope1, $slope2;
my $slope = $slope1 - $slope2;
my $slope1a = $slope->slice('1:9');
my $slope2a = $slope->slice('0:8');
ok(all($slope1a <= $slope2a),"early slope is non-increasing") or diag $slope1a, "\n", $slope2a, "\n", $slope1a <= $slope2a;
is_pdl $bfull->apply(!$t), $a, {atol=>1e-3, test_name=>"decoding undoes coding"};
}

##############################
# test t_pc
# (minimal testing)
eval {t_pc();};
like $@, qr/^Usage\:/, "t_pc with no arguments died and threw out an info message";
is_pdl +(xvals(6)/5)->apply(t_pc('sepia')), byte('0 0 0; 178 124 56; 208 170 111; 228 203 162; 243 231 209; 255 255 255'), "t_pc created an RGB output";

is_pdl pdl(1,1,1)->apply(t_xyz2lab()), pdl(100, 8.5945916, 5.5564131), 't_xyz2lab right values';

for my $rgb (pdl(255, 0, 0), pdl(0, 255, 0), pdl(0, 0, 255)) {
    my $t = t_lab() x !t_srgb();
    my $lab = $rgb->apply($t);
    my $rgb2 = $lab->invert($t);
    is_pdl $rgb2, $rgb->byte, "t_lab loop $rgb";
}

done_testing;
