package Numeric::Matrix;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Numeric::Matrix', $VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Numeric::Matrix - SIMD-accelerated 2D matrices with BLAS GEMM

=head1 SYNOPSIS

    use Numeric::Matrix;
    
    # Constructors
    my $A = Numeric::Matrix::zeros(3, 4);    # 3x4 zeros
    my $B = Numeric::Matrix::ones(3, 4);     # 3x4 ones
    my $C = Numeric::Matrix::randn(3, 4);    # 3x4 normal distribution
    my $D = Numeric::Matrix::from_array([1..12], 3, 4);
    
    # Shape & Access
    my ($rows, $cols) = $A->shape;
    my $val = $A->get(0, 0);
    $A->set(0, 0, 42.0);
    
    # Element-wise operations
    my $sum = $A->add($B);
    my $diff = $A->sub($B);
    my $prod = $A->mul($B);      # element-wise
    my $quot = $A->div($B);
    
    # In-place operations
    $A->add_inplace($B);
    $A->scale_inplace(2.0);
    $A->add_scaled_inplace($B, 0.1);  # A += 0.1 * B (for AdamW)
    
    # Matrix multiply (uses BLAS when available)
    my $X = Numeric::Matrix::randn(128, 64);
    my $W = Numeric::Matrix::randn(64, 32);
    my $Y = $X->matmul($W);      # 128x32
    
    # Fused ops for ML
    $Y->softmax_rows_inplace();  # softmax per row
    $Y->silu_inplace();          # x * sigmoid(x)
    $Y->gelu_inplace();          # GELU activation
    
    # Functional interface
    use Numeric::Matrix qw(zeros ones matmul);
    my $m = nmat_zeros(10, 10);
    my $r = nmat_matmul($m, $m);

=head1 DESCRIPTION

Numeric::Matrix provides SIMD-accelerated 2D matrices for Perl.
Uses ARM NEON, x86 AVX2, SSE2, or scalar fallback.
Integrates with BLAS (Accelerate on macOS, OpenBLAS on Linux)
for fast matrix multiplication.

Row-major layout: C<data[r * cols + c]>

=head1 CONSTRUCTORS

=head2 zeros

    my $mat = Numeric::Matrix::zeros($rows, $cols);

=head2 ones

    my $mat = Numeric::Matrix::ones($rows, $cols);

=head2 randn

    my $mat = Numeric::Matrix::randn($rows, $cols);

Box-Muller normal distribution (mean=0, std=1).

=head2 from_array

    my $mat = Numeric::Matrix::from_array(\@data, $rows, $cols);

Create from Perl array (row-major).

=head1 METHODS

=head2 Shape & Access

    $mat->rows()
    $mat->cols()
    $mat->shape()           # returns ($rows, $cols)
    $mat->get($r, $c)
    $mat->set($r, $c, $val)
    $mat->clone()
    $mat->zeros_like()

=head2 Element-wise Binary (return new)

    $mat->add($other)
    $mat->sub($other)
    $mat->mul($other)       # element-wise
    $mat->div($other)

=head2 Element-wise In-place

    $mat->add_inplace($other)
    $mat->sub_inplace($other)
    $mat->mul_inplace($other)
    $mat->div_inplace($other)
    $mat->add_scaled_inplace($other, $scalar)  # mat += scalar * other

=head2 Scalar Operations

    $mat->scale($s)         # return new
    $mat->scale_inplace($s)
    $mat->add_scalar($s)
    $mat->add_scalar_inplace($s)

=head2 Unary Operations

    $mat->sqrt()
    $mat->exp()
    $mat->log()
    $mat->neg()
    $mat->abs()

=head2 Reductions

    $mat->sum()
    $mat->norm()            # L2 norm
    $mat->max()
    $mat->min()

=head2 Matrix Multiply

    $A->matmul($B)          # C = A x B

Uses BLAS dgemm when available (Accelerate on macOS).
Falls back to tiled scalar implementation.

=head2 Fused Ops

    $mat->softmax_rows_inplace()  # numerically stable softmax per row
    $mat->silu_inplace()          # SiLU activation
    $mat->gelu_inplace()          # GELU activation

=head2 Transpose

    $mat->transpose()

=head2 Serialization

    $mat->to_array()        # returns arrayref

=head1 IMPORTING

    use Numeric::Matrix qw(zeros ones matmul);
    
    my $m = nmat_zeros(10, 10);  # installed as nmat_*

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

Artistic License 2.0

=cut
