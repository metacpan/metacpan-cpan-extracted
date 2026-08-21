use strict;
use warnings;
use Test::More;
use Test::PDL;

use PDL::LiteF;
use PDL::DSP::Fir qw( firwin ir_sinc spectral_reverse spectral_inverse );

is_pdl ir_sinc(.5,5),
    pdl([qw(1.9490859e-17 0.31830989 0.5 0.31830989 1.9490859e-17)]);

is_pdl ir_sinc(.5,6),
    pdl([qw(-0.090031632 0.15005272 0.45015816 0.45015816 0.15005272 -0.090031632)]);

is_pdl firwin( N => 10, fc => .9 ) , firwin( { N => 10, fc => .9 } );

my $data = ir_sinc(.5,20);

is_pdl $data , spectral_reverse(spectral_reverse($data)), {atol=>1e-15};

$data = ir_sinc(.5,21);

is_pdl $data, spectral_inverse(spectral_inverse($data)), {atol=>1e-15};
is_pdl $data, spectral_reverse(spectral_reverse($data)), {atol=>1e-15};

done_testing;
