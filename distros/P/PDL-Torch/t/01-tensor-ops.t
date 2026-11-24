use strict;
use warnings;
use Test::More;
use PDL;
use PDL::Torch qw(pdl2tensor tensor2pdl cuda_available);

my $a_pdl = double([[1, 2], [3, 4]]);
my $b_pdl = double([[5, 6], [7, 8]]);

my $a = pdl2tensor($a_pdl, 'cpu');
my $b = pdl2tensor($b_pdl, 'cpu');

isa_ok($a, 'PDL::Torch::Tensor');
is($a->device, 'cpu', 'tensor device is cpu');
is($a->dtype, 'float64', 'tensor dtype is float64');
is_deeply([$a->dims], [2, 2], 'tensor dims match 2x2');

my $sum_pdl = ($a + $b)->pdl();
is_deeply($sum_pdl->unpdl, [[6, 8], [10, 12]], 'elementwise addition matches');

my $mul_pdl = ($a * $b)->pdl();
is_deeply($mul_pdl->unpdl, [[5, 12], [21, 32]], 'elementwise multiplication matches');

my $mm_pdl = ($a x $b)->pdl();
is_deeply($mm_pdl->unpdl, [[19, 22], [43, 50]], 'matrix multiplication matches');

is($a->sum()->pdl()->sclr, 10, 'sum reduction matches');
is($a->mean()->pdl()->sclr, 2.5, 'mean reduction matches');

SKIP: {
    skip 'No CUDA GPU available', 2 unless cuda_available();
    my $ga = $a->cuda();
    like($ga->device, qr/^cuda/, 'tensor moved to cuda');
    my $gb = $b->cuda();
    is_deeply(($ga x $gb)->pdl()->unpdl, [[19, 22], [43, 50]], 'CUDA matmul matches');
}

done_testing();
