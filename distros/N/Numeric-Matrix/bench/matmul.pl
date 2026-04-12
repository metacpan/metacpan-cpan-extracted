#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use Numeric::Matrix qw(from_array matmul);

print "Matrix Multiplication Benchmark: XS (BLAS) vs Pure Perl\n";
print "=" x 60, "\n\n";

# Pure Perl matmul
sub pp_matmul {
    my ($A, $B) = @_;
    my $rows_a = scalar @$A;
    my $cols_a = scalar @{$A->[0]};
    my $cols_b = scalar @{$B->[0]};
    
    my @C;
    for my $i (0 .. $rows_a - 1) {
        for my $j (0 .. $cols_b - 1) {
            my $sum = 0;
            for my $k (0 .. $cols_a - 1) {
                $sum += $A->[$i][$k] * $B->[$k][$j];
            }
            $C[$i][$j] = $sum;
        }
    }
    return \@C;
}

for my $size (32, 64, 128, 256) {
    print "Size: ${size}x${size}\n";
    print "-" x 40, "\n";
    
    # Create random data
    my @data_a = map { rand() } (1 .. $size * $size);
    my @data_b = map { rand() } (1 .. $size * $size);
    
    # XS matrices
    my $xs_a = nmat_from_array(\@data_a, $size, $size);
    my $xs_b = nmat_from_array(\@data_b, $size, $size);
    
    # Pure Perl 2D arrays
    my @pp_a;
    my @pp_b;
    for my $i (0 .. $size - 1) {
        $pp_a[$i] = [ @data_a[$i * $size .. ($i + 1) * $size - 1] ];
        $pp_b[$i] = [ @data_b[$i * $size .. ($i + 1) * $size - 1] ];
    }
    
    cmpthese(-1, {
        'XS (BLAS)' => sub { my $c = nmat_matmul($xs_a, $xs_b) },
        'Pure Perl' => sub { my $c = pp_matmul(\@pp_a, \@pp_b) },
    });
    
    print "\n";
}
