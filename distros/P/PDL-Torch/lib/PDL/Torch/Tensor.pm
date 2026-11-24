package PDL::Torch::Tensor;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

use overload
    '+'      => sub { $_[0]->add($_[1]) },
    '-'      => sub { $_[2] ? $_[1]->sub($_[0]) : $_[0]->sub($_[1]) },
    '*'      => sub { $_[0]->mul($_[1]) },
    '/'      => sub { $_[2] ? $_[1]->div($_[0]) : $_[0]->div($_[1]) },
    'x'      => sub { $_[2] ? $_[1]->matmul($_[0]) : $_[0]->matmul($_[1]) },
    fallback => 1;

my @DTYPE_NAMES = (
    'uint8', 'int8', 'int16', 'int32', 'int64',
    'float32', 'float64', 'complex64', 'complex128',
);

sub dtype {
    my ($self) = @_;
    my $idx = $self->_xs_dtype();
    return ($idx >= 0 && $idx < @DTYPE_NAMES) ? $DTYPE_NAMES[$idx] : undef;
}

sub cpu {
    my ($self) = @_;
    return $self->to('cpu');
}

sub cuda {
    my ($self) = @_;
    return $self->to('cuda');
}

sub pdl {
    my ($self) = @_;
    return PDL::Torch::tensor2pdl($self);
}

sub add    { my ($a, $b) = @_; return _xs_add($a, $b); }
sub sub    { my ($a, $b) = @_; return _xs_sub($a, $b); }
sub mul    { my ($a, $b) = @_; return _xs_mul($a, $b); }
sub div    { my ($a, $b) = @_; return _xs_div($a, $b); }
sub matmul { my ($a, $b) = @_; return _xs_matmul($a, $b); }

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::Torch::Tensor - Opaque LibTorch tensor handle with operator overloading

=head1 SYNOPSIS

    use PDL;
    use PDL::Torch qw(pdl2tensor);

    my $a = pdl2tensor(double([[1, 2], [3, 4]]));
    my $b = pdl2tensor(double([[5, 6], [7, 8]]));

    my $sum  = ($a + $b)->sum()->pdl();
    my $prod = ($a x $b)->pdl();

=head1 DESCRIPTION

C<PDL::Torch::Tensor> wraps an opaque C<torch::Tensor> handle managed by
L<PDL::Torch> XS, providing Perl operator overloading (C<+>, C<->, C<*>, C</>,
C<x> for matrix multiplication) and deterministic VRAM/RAM cleanup via
C<DESTROY>.

=head1 METHODS

=head2 pdl

Transfer the tensor to CPU (if needed) and return a L<PDL> ndarray.

=head2 to( $device )

Return a new tensor moved to C<$device> (e.g., C<'cpu'>, C<'cuda'>, C<'cuda:0'>).

=head2 cpu

Shorthand for C<< $tensor->to('cpu') >>.

=head2 cuda

Shorthand for C<< $tensor->to('cuda') >>.

=head2 device

Return the tensor's current device string (e.g., C<'cpu'>, C<'cuda:0'>).

=head2 dtype

Return the tensor's LibTorch dtype name (e.g., C<'float64'>, C<'complex64'>).

=head2 dims

Return the tensor's shape as a list of dimension sizes.

=head2 add / sub / mul / div / matmul

Binary tensor operations (also bound to C<+>, C<->, C<*>, C</>, and C<x>).

=head2 sum / mean

Reduction operations returning a scalar L<PDL::Torch::Tensor>.

=head1 SEE ALSO

L<PDL::Torch>, L<PDL>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
