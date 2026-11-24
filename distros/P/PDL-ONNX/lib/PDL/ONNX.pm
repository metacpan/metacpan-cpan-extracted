package PDL::ONNX;

use strict;
use warnings;
use Exporter 'import';
use Carp qw(croak);
use XSLoader;

use PDL::Core;
use PDL::Types;
use PDL::Slices;

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    onnx_version
    available_providers
    load_session
);

XSLoader::load('PDL::ONNX', $VERSION);

sub load_session {
    my ($path) = @_;
    croak 'load_session requires a model path' unless defined $path && length $path;
    return PDL::ONNX::Session::_xs_create($path);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::ONNX - ONNX Runtime C API bindings for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::ONNX qw(onnx_version available_providers load_session);

    print 'ONNX Runtime: ', onnx_version(), "\n";
    print 'Providers: ', join(', ', available_providers()), "\n";

    my $sess = load_session('model.onnx');
    my @inputs  = $sess->input_names();
    my @outputs = $sess->output_names();

=head1 DESCRIPTION

C<PDL::ONNX> binds L<PDL> to ONNX Runtime's pure-C API
(C<onnxruntime_c_api.h>) via C99 XS for cross-framework ML model inspection
and inference (PyTorch, TensorFlow, XGBoost, scikit-learn).

=head1 FUNCTIONS

=head2 onnx_version

=for ref

Return the linked ONNX Runtime version string.

=for usage

    $ver = onnx_version();

=head2 available_providers

=for ref

Return the list of available ONNX Runtime execution providers (e.g.,
C<CPUExecutionProvider>, C<CUDAExecutionProvider>).

=for usage

    @providers = available_providers();

=head2 load_session

=for ref

Load an C<.onnx> model file into a C<PDL::ONNX::Session>.

=for usage

    $sess = load_session($path);

=head1 SEE ALSO

L<PDL>, L<PDL::Torch>, L<PDL::XGBoost>, L<PDL::FAISS>, L<PDL::GGML>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
