#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Numeric::Matrix qw(from_array softmax_rows_inplace);
use List::Util qw(max sum);

print "Softmax Benchmark: XS vs Pure Perl\n";
print "=" x 60, "\n\n";

# Pure Perl softmax (row-wise)
sub pp_softmax {
    my ($data, $rows, $cols) = @_;
    my @result;
    
    for my $r (0 .. $rows - 1) {
        my $offset = $r * $cols;
        my @row = @{$data}[$offset .. $offset + $cols - 1];
        
        # Numerical stability: subtract max
        my $row_max = max(@row);
        my @exp_row = map { exp($_ - $row_max) } @row;
        my $sum = sum(@exp_row);
        
        push @result, map { $_ / $sum } @exp_row;
    }
    return \@result;
}

for my $rows (100, 1000, 10000) {
    for my $cols (64, 256, 1024) {
        my $size = $rows * $cols;
        
        print "Size: ${rows} rows x ${cols} cols = $size elements\n";
        print "-" x 50, "\n";
        
        my @data = map { rand() * 10 - 5 } (1 .. $size);
        
        my $xs_m = nmat_from_array(\@data, $rows, $cols);
        
        cmpthese(-2, {
            'XS'        => sub { 
                my $m = nmat_from_array(\@data, $rows, $cols);
                nmat_softmax_rows_inplace($m);
            },
            'Pure Perl' => sub { my $r = pp_softmax(\@data, $rows, $cols) },
        });
        
        print "\n";
    }
}
