package Peta::NN::Layer::Dense;
# ABSTRACT: fully connected layer

# Fully connected layer: Y = X W^T + b, for a whole batch of rows X. The
# weights are a backend tensor of one row per output.

use v5.36;

our $VERSION = '0.2610090';

sub new ($class, %arg) {
    return bless { n_out => $arg{out}, need_dx => 1 }, $class;
}

sub type ($self) { return 'dense' }

# Glorot uniform: keeps the signal's variance about constant through the layer
# for tanh and sigmoid, and is close enough to He's for the small ReLU nets here.
sub init ($self, $n_in, $rng, $backend) {
    die "dense cannot read tokens; put an embed layer first\n" if ref $n_in;
    my $n_out = $self->{n_out};
    my $limit = sqrt(6 / ($n_in + $n_out));
    $self->{backend} = $backend;
    $self->{n_in}    = $n_in;
    $self->{W} = $backend->tensor([ map { (2 * $rng->uniform - 1) * $limit } 1 .. $n_in * $n_out ], $n_in);
    $self->{b} = $backend->tensor([ (0.0) x $n_out ], $n_out);
    return $n_out;
}

sub param_names ($self) { return qw(W b) }

# Numbers per row of a parameter tensor: W has one row per output.
sub param_cols ($self, $name) { return $name eq 'W' ? $self->{n_in} : $self->{n_out} }

sub forward ($self, $X) {
    $self->{X} = $X;
    return $self->{backend}->affine($X, $self->{W}, $self->{b});
}

# Leaves the batch's gradient in gW and gb and returns the gradient with
# respect to the input. The first layer of a net has nobody to hand that to,
# so the net clears need_dx there and the backend skips it.
sub backward ($self, $dY) {
    my @grad = $self->{backend}->affine_grad($self->{X}, $self->{W}, $dY, $self->{need_dx});
    @$self{qw(gW gb)} = @grad[ 0, 1 ];
    return $grad[2];
}

sub spec ($self) { return [ dense => $self->{n_out} ] }

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Layer::Dense - fully connected layer

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 4, layers => [ [dense => 2] ]);     # as one of:
    layers => [ [dense => 8], 'relu', [dense => 2] ]

=head1 DESCRIPTION

Written as C<[dense =E<gt> $outputs]> in a network's layer list. The input
size comes from the layer before it.

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
