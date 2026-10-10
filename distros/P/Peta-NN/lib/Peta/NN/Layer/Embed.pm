package Peta::NN::Layer::Embed;
# ABSTRACT: learned vectors for token indices

# Embedding layer: the input is a fixed number of token indices per sample
# (the characters of a window, say), each looked up in a learned table and
# the rows concatenated. It can only be the first layer, so it never
# produces an input gradient.

use v5.36;

our $VERSION = '0.2610090';

my $INIT_SCALE = 0.1;

sub new ($class, %arg) {
    return bless { dim => $arg{dim} }, $class;
}

sub type ($self) { return 'embed' }

# $in is { tokens => count per sample, vocab => table rows }.
sub init ($self, $in, $rng, $backend) {
    die "embed must be the first layer, on a token input\n" if ref $in ne 'HASH';
    my $dim = $self->{dim};
    $self->{backend} = $backend;
    $self->{E} = $backend->tensor([ map { $rng->normal * $INIT_SCALE } 1 .. $in->{vocab} * $dim ], $dim);
    return $in->{tokens} * $dim;
}

sub param_names ($self) { return qw(E) }

# Numbers per row of the table: one row per token.
sub param_cols ($self, $name) { return $self->{dim} }

sub forward ($self, $tokens) {
    $self->{tokens} = $tokens;
    return $self->{backend}->embed($self->{E}, $tokens);
}

sub backward ($self, $dY) {
    $self->{gE} = $self->{backend}->embed_grad($self->{E}, $self->{tokens}, $dY);
    return;
}

sub spec ($self) { return [ embed => $self->{dim} ] }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Layer::Embed - learned vectors for token indices

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 4, layers => [ [dense => 2] ]);     # as one of:
    input  => { tokens => 6, vocab => 40 },
    layers => [ [embed => 8], [dense => 16], 'relu', [dense => 3] ]

=head1 DESCRIPTION

Written as C<[embed =E<gt> $dim]>, first in the layer list of a network
whose input is C<{ tokens =E<gt> $count, vocab =E<gt> $size }>.

=head1 METHODS

A layer is made and driven by L<Peta::NN>; these are what the network calls.

=head2 new

The layer, from what its entry in the layer list says.

=head2 type

The layer's kind, as a model file names it.

=head2 init

C<init($n_in, $rng, $backend)>: sets the layer up for its input size and
returns its output size.

=head2 param_names

The names of the layer's parameter tensors.

=head2 forward

The layer's output for a batch.

=head2 backward

Takes the gradient of the output, leaves the gradients of the parameters
with the layer, and returns the gradient of the input.

=head2 spec

The layer as it is written in a layer list.

=head2 param_cols

C<param_cols($name)>: numbers per row of a parameter tensor.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
