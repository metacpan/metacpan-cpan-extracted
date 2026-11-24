package PDL::FAISS;

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
    flat_l2
    flat_ip
);

XSLoader::load('PDL::FAISS', $VERSION);

package PDL::FAISS::Index;

sub add {
    my ($self, $vectors) = @_;
    return $self->_xs_add($vectors->float());
}

sub search {
    my ($self, $queries, $k) = @_;
    $k ||= 1;
    return $self->_xs_search($queries->float(), $k);
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDL::FAISS - FAISS vector similarity search bindings for PDL

=head1 SYNOPSIS

    use PDL;
    use PDL::FAISS qw(flat_l2 flat_ip);

    my $index = flat_l2(4);
    my $db    = float([[1,0,0,0], [0,1,0,0], [0,0,1,0]]);
    $index->add($db);

    my ($distances, $indices) = $index->search(float([[0,1,0,0]]), 2);

=head1 DESCRIPTION

C<PDL::FAISS> binds L<PDL> ndarrays to Facebook AI Similarity Search (FAISS)
for fast L2 and inner-product k-NN vector search.

=head1 FUNCTIONS

=head2 flat_l2

=for ref

Create a C<PDL::FAISS::Index> using exact L2 (Euclidean) distance for vectors
of dimension C<$dim>.

=for usage

    $index = flat_l2($dim);

=head2 flat_ip

=for ref

Create a C<PDL::FAISS::Index> using exact inner-product similarity for vectors
of dimension C<$dim>.

=for usage

    $index = flat_ip($dim);

=head1 SEE ALSO

L<PDL>, L<PDL::Torch>, L<PDL::XGBoost>, L<PDL::ONNX>, L<PDL::GGML>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
