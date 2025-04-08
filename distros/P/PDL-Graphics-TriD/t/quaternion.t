use strict;
use warnings;
use Test::More;

use PDL::Graphics::TriD::Quaternion;
use PDL::LiteF;
use Test::PDL;

sub is_qua {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($got, $exp) = map PDL->pdl(@$_), @_;
  is_pdl $got, $exp;
}

my $q = PDL::Graphics::TriD::Quaternion->new(0,0,0,1);
isa_ok $q, 'PDL::Graphics::TriD::Quaternion';
is_qua $q, [0,0,0,1];

is_qua +PDL::Graphics::TriD::Quaternion->new(0,0,0,2)->normalise, [0,0,0,1];

my ($q1, $q2) = map PDL::Graphics::TriD::Quaternion->new(@$_), [1,2,3,4], [5,6,7,8];

is_qua $q1->multiply($q2), my $q1_q2 = [
  5-12-21-32, # $a0*$b0 - $a1*$b1 - $a2*$b2 - $a3*$b3,
  6+10+24-28, # $a0*$b1 + $b0*$a1 + $a2*$b3 - $a3*$b2,
  7+15+24-16, # $a0*$b2 + $b0*$a2 + $a3*$b1 - $a1*$b3,
  8+20+14-18, # $a0*$b3 + $b0*$a3 + $a1*$b2 - $a2*$b1
];
is_qua $q1 * $q2, $q1_q2;

is_qua $q1->invert, my $q1_inv = [0.033333,-0.066666,-0.1,-0.133333];
is_qua !$q1, $q1_inv;
is_qua 1 / $q1, $q1_inv;
is_qua $q1 / 4, [0.25,0.5,0.75,1];
is_qua $q1 / !$q2, $q1_q2;

is_qua $q2 * 2, [10,12,14,16];
is_qua 2 * $q2, [10,12,14,16];
is_qua $q2 + 2, [7,6,7,8];
is_qua 2 + $q2, [7,6,7,8];
is_qua $q1 + $q2, [6,8,10,12];
my $q2_copy = $q2->copy;
$q2_copy += 2;
is_qua $q2_copy, [7,6,7,8];
$q2_copy /= 2;
is_qua $q2_copy, [3.5,3,3.5,4];

my $q3 = PDL::Graphics::TriD::Quaternion->new(2,0,0,0);
is_qua $q3, [2,0,0,0];
$q3 .= [3,4,5,6];
is_qua $q3, [3,4,5,6];
$q3 .= $q2;
is_qua $q3, [5,6,7,8];
my $this = {Quat=>$q3};
$this->{Quat} .= $q2;

my $q4 = $q1->copy;
is_qua $q4, [1,2,3,4];
$q4 *= 2;
is_qua $q4, [2,4,6,8];
$q4 *= [0.5,0,0,0];
is_qua $q4, [1,2,3,4];
$q4 *= $q2;
is_qua $q4, $q1_q2;

done_testing;
