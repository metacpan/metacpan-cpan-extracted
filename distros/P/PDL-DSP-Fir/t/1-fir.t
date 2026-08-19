use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::DSP::Fir qw( firwin ir_sinc spectral_reverse spectral_inverse );
use PDL::Core qw( topdl );

sub tapprox {
  my($a,$b, $eps) = @_;
  $a = topdl $a;
  $b = topdl $b;
  $eps ||= 1e-7;
  my $diff = abs($a-$b);
  return $diff->sum < $eps;
}

ok( tapprox( ir_sinc(.5,5), 
    [qw(1.9490859e-17 0.31830989 0.5 0.31830989 1.9490859e-17)] ));

ok( tapprox( ir_sinc(.5,6), 
    [qw(-0.090031632 0.15005272 0.45015816 0.45015816 0.15005272 -0.090031632)] ));

ok( tapprox( firwin( N => 10, fc => .9 ) , firwin( { N => 10, fc => .9 } ) ));

my $data = ir_sinc(.5,20);

ok(tapprox( $data , spectral_reverse(spectral_reverse($data)), 1e-15));

$data = ir_sinc(.5,21);

ok(tapprox( $data , spectral_inverse(spectral_inverse($data)), 1e-15));
ok(tapprox( $data , spectral_reverse(spectral_reverse($data)), 1e-15));

done_testing;
