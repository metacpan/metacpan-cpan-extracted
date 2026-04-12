#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Numeric::Matrix qw(from_array add mul scale exp);

print "Element-wise Operations Benchmark: XS (SIMD) vs Pure Perl\n";
print "=" x 60, "\n\n";

# Pure Perl implementations
sub pp_add {
    my ($a, $b) = @_;
    my @c;
    for my $i (0 .. $#$a) {
        $c[$i] = $a->[$i] + $b->[$i];
    }
    return \@c;
}

sub pp_mul {
    my ($a, $b) = @_;
    my @c;
    for my $i (0 .. $#$a) {
        $c[$i] = $a->[$i] * $b->[$i];
    }
    return \@c;
}

sub pp_exp {
    my ($a) = @_;
    my @c;
    for my $i (0 .. $#$a) {
        $c[$i] = exp($a->[$i]);
    }
    return \@c;
}

sub pp_scale {
    my ($a, $s) = @_;
    my @c;
    for my $i (0 .. $#$a) {
        $c[$i] = $a->[$i] * $s;
    }
    return \@c;
}

for my $size (1000, 10000, 100000, 1000000) {
    my $rows = 1000;
    my $cols = $size / $rows;
    next if $cols < 1;
    
    print "Size: $size elements (${rows}x${cols})\n";
    print "-" x 50, "\n";
    
    my @data_a = map { rand() } (1 .. $size);
    my @data_b = map { rand() } (1 .. $size);
    
    my $xs_a = nmat_from_array(\@data_a, $rows, $cols);
    my $xs_b = nmat_from_array(\@data_b, $rows, $cols);
    
    print "Add:\n";
    cmpthese(-1, {
        'XS'        => sub { my $c = nmat_add($xs_a, $xs_b) },
        'Pure Perl' => sub { my $c = pp_add(\@data_a, \@data_b) },
    });
    
    print "\nMul:\n";
    cmpthese(-1, {
        'XS'        => sub { my $c = nmat_mul($xs_a, $xs_b) },
        'Pure Perl' => sub { my $c = pp_mul(\@data_a, \@data_b) },
    });
    
    print "\nScale:\n";
    cmpthese(-1, {
        'XS'        => sub { my $c = nmat_scale($xs_a, 2.5) },
        'Pure Perl' => sub { my $c = pp_scale(\@data_a, 2.5) },
    });
    
    print "\nExp:\n";
    cmpthese(-1, {
        'XS'        => sub { my $c = nmat_exp($xs_a) },
        'Pure Perl' => sub { my $c = pp_exp(\@data_a) },
    });
    
    print "\n\n";
}
