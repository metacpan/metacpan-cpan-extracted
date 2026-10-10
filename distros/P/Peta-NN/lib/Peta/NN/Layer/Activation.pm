package Peta::NN::Layer::Activation;
# ABSTRACT: relu, tanh and sigmoid

# Element-wise non-linearities. Each derivative is taken in terms of the
# OUTPUT, so the layer keeps only what it returned.

use v5.36;

our $VERSION = '0.2610090';

my %KIND = map { $_ => 1 } qw(relu tanh sigmoid);

sub kinds { return sort keys %KIND }

sub new ($class, %arg) {
    die "unknown activation '$arg{kind}'\n" if !$KIND{ $arg{kind} };
    return bless { kind => $arg{kind} }, $class;
}

sub type ($self) { return $self->{kind} }

sub init ($self, $n_in, $rng, $backend) {
    die "$self->{kind} cannot follow a token input directly\n" if ref $n_in;
    $self->{backend} = $backend;
    return $n_in;
}

sub param_names ($self) { return }

sub forward ($self, $X) {
    return $self->{Y} = $self->{backend}->activate($self->{kind}, $X);
}

sub backward ($self, $dY) {
    return $self->{backend}->activate_grad($self->{kind}, $self->{Y}, $dY);
}

sub spec ($self) { return $self->{kind} }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Layer::Activation - relu, tanh and sigmoid

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 4, layers => [ [dense => 2] ]);     # as one of:
    layers => [ [dense => 8], 'tanh', [dense => 2] ]

=head1 DESCRIPTION

Written as the bare string C<'relu'>, C<'tanh'> or C<'sigmoid'> in a
network's layer list.

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

=head2 kinds

The activations there are.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
