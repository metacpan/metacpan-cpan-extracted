package PDL::Torch;

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);
use XSLoader;

use PDL::Core;
use PDL::Types;
use PDL::Slices;
use PDL::Torch::Tensor;

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    pdl2tensor
    tensor2pdl
    cuda_available
    pdl2torch_type
    torch2pdl_type
);

XSLoader::load('PDL::Torch', $VERSION);

my %TORCH_TO_PDL = (
    uint8      => 'byte',
    int8       => 'sbyte',
    int16      => 'short',
    int32      => 'long',
    int64      => 'longlong',
    float32    => 'float',
    float64    => 'double',
    complex64  => 'cfloat',
    complex128 => 'cdouble',
);

my %PDL_TO_TORCH = reverse %TORCH_TO_PDL;

sub torch2pdl_type {
    my ($torch_type) = @_;
    return undef unless defined $torch_type;
    return $TORCH_TO_PDL{ lc($torch_type) };
}

sub pdl2torch_type {
    my ($pdl_type) = @_;
    return undef unless defined $pdl_type;
    return $PDL_TO_TORCH{ lc($pdl_type) };
}

sub pdl2tensor {
    my ($pdl, $device) = @_;
    croak 'pdl2tensor requires a PDL ndarray' unless defined $pdl;
    $device = 'cpu' unless defined $device && length $device;
    return _xs_pdl2tensor($pdl, $device);
}

sub tensor2pdl {
    my ($tensor) = @_;
    croak 'tensor2pdl requires a PDL::Torch::Tensor' unless defined $tensor;
    return _xs_tensor2pdl($tensor);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::Torch - LibTorch (PyTorch C++) GPU/CPU tensor acceleration for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::Torch qw(pdl2tensor tensor2pdl cuda_available);

    my $device = cuda_available() ? 'cuda' : 'cpu';

    my $a = pdl2tensor(double([[1, 2], [3, 4]]), $device);
    my $b = pdl2tensor(double([[5, 6], [7, 8]]), $device);

    my $c = ($a + $b) x $a;   # elementwise add + matrix multiply on GPU/CPU
    my $out = $c->pdl();      # transfer back to PDL ndarray

=head1 DESCRIPTION

C<PDL::Torch> binds L<PDL> ndarrays directly to LibTorch (PyTorch's C++ ATen
tensor engine) via C99 XS and a C++17 bridge, enabling hardware-accelerated
tensor operations on CPU, CUDA, ROCm, and Apple Metal (MPS).

Because Perl uses deterministic reference counting, GPU VRAM held by
L<PDL::Torch::Tensor> objects is released immediately when the Perl scalar
goes out of scope.

=head1 FUNCTIONS

=head2 pdl2tensor

=for ref

Convert a L<PDL> ndarray to a L<PDL::Torch::Tensor> on the requested device.

=for usage

    $tensor = pdl2tensor($pdl);
    $tensor = pdl2tensor($pdl, 'cuda');

=for example

    my $t = pdl2tensor(float([1, 2, 3, 4]), 'cpu');

=head2 tensor2pdl

=for ref

Convert a L<PDL::Torch::Tensor> (from CPU or GPU) back into a L<PDL> ndarray.

=for usage

    $pdl = tensor2pdl($tensor);

=for example

    my $p = tensor2pdl($t);

=head2 cuda_available

=for ref

Returns true (C<1>) if LibTorch detects a usable CUDA GPU, or C<0> otherwise.

=for usage

    $has_cuda = cuda_available();

=head2 pdl2torch_type

=for ref

Map a PDL type name (e.g. C<double>, C<cfloat>) to its LibTorch dtype name.

=for usage

    $torch_dtype = pdl2torch_type($pdl_type);

=head2 torch2pdl_type

=for ref

Map a LibTorch dtype name (e.g. C<float64>, C<complex64>) to its PDL type name.

=for usage

    $pdl_type = torch2pdl_type($torch_dtype);

=head1 SEE ALSO

L<PDL::Torch::Tensor>, L<PDL>, L<PDL::IO::Arrow>, L<PDL::IO::Protobuf>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
