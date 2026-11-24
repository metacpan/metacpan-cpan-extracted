#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use PDL;
use PDL::Torch qw(pdl2tensor cuda_available);

my $n = $ARGV[0] || 1024;
my $has_cuda = cuda_available();

print 'PDL::Torch GPU/CPU Exercise (N=' . $n . 'x' . $n . ")\n";
print 'CUDA available: ' . ($has_cuda ? 'YES' : 'NO') . "\n";

my $a_pdl = float(random($n, $n));
my $b_pdl = float(random($n, $n));

my $t0 = time();
my $a_cpu = pdl2tensor($a_pdl, 'cpu');
my $b_cpu = pdl2tensor($b_pdl, 'cpu');
my $c_cpu = ($a_cpu x $b_cpu)->pdl();
my $cpu_s = time() - $t0;
printf "CPU matmul:  %.4fs (sum=%.4f)\n", $cpu_s, $c_cpu->sum();

if ($has_cuda) {
    my $t1 = time();
    my $a_gpu = pdl2tensor($a_pdl, 'cuda');
    my $b_gpu = pdl2tensor($b_pdl, 'cuda');
    my $c_gpu = ($a_gpu x $b_gpu)->pdl();
    my $gpu_s = time() - $t1;
    my $max_diff = abs($c_cpu - $c_gpu)->max();
    printf "CUDA matmul: %.4fs (sum=%.4f, max_diff=%.3e, speedup=%.2fx)\n",
        $gpu_s, $c_gpu->sum(), $max_diff, ($gpu_s > 0 ? $cpu_s / $gpu_s : 0);
}
else {
    print "No CUDA GPU detected; skipping GPU benchmark.\n";
}
