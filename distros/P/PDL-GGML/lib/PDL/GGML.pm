package PDL::GGML;

use strict;
use warnings;
use Exporter 'import';
use XSLoader;

use PDL::Core;
use PDL::Types;
use PDL::Slices;

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    ggml_add
    ggml_mul
    ggml_mul_mat
);

XSLoader::load('PDL::GGML', $VERSION);

sub ggml_add     { my ($a, $b) = @_; return _xs_add($a->float(), $b->float()); }
sub ggml_mul     { my ($a, $b) = @_; return _xs_mul($a->float(), $b->float()); }
sub ggml_mul_mat { my ($a, $b) = @_; return _xs_mul_mat($a->float(), $b->float()); }

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::GGML - GGML tensor computation graph bindings for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::GGML qw(ggml_add ggml_mul ggml_mul_mat);

    my $a = float([[1, 2], [3, 4]]);
    my $b = float([[5, 6], [7, 8]]);

    my $sum = ggml_add($a, $b);
    my $mul = ggml_mul($a, $b);
    my $mm  = ggml_mul_mat($a, $b);

=head1 DESCRIPTION

C<PDL::GGML> binds L<PDL> ndarrays directly to GGML's C tensor computation
graph API (C<ggml.h> / C<ggml-cpu.h>) via C99 XS.

=head1 FUNCTIONS

=head2 ggml_add

=for ref

Compute elementwise addition of two float L<PDL> ndarrays using GGML.

=for usage

    $c = ggml_add($a, $b);

=head2 ggml_mul

=for ref

Compute elementwise multiplication of two float L<PDL> ndarrays using GGML.

=for usage

    $c = ggml_mul($a, $b);

=head2 ggml_mul_mat

=for ref

Compute GGML matrix multiplication C<a * b^T> on two 2D float L<PDL> ndarrays.

=for usage

    $c = ggml_mul_mat($a, $b);

=head1 SEE ALSO

L<PDL>, L<PDL::Torch>, L<PDL::XGBoost>, L<PDL::ONNX>, L<PDL::FAISS>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
