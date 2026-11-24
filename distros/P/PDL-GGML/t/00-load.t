use strict;
use warnings;
use Test::More;
use PDL;

use_ok('PDL::GGML', qw(ggml_add ggml_mul ggml_mul_mat));

my $a = float([[1, 2], [3, 4]]);
my $b = float([[5, 6], [7, 8]]);

my $sum = ggml_add($a, $b);
is_deeply($sum->unpdl, [[6, 8], [10, 12]], 'ggml_add matches');

my $mul = ggml_mul($a, $b);
is_deeply($mul->unpdl, [[5, 12], [21, 32]], 'ggml_mul matches');

my $mm = ggml_mul_mat($a, $b);
# ggml_mul_mat computes a * b^T:
# row0: [1*5+2*6, 3*5+4*6] = [17, 39]
# row1: [1*7+2*8, 3*7+4*8] = [23, 53]
is_deeply($mm->unpdl, [[17, 39], [23, 53]], 'ggml_mul_mat matches');

done_testing();
