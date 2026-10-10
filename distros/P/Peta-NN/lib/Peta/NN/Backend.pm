package Peta::NN::Backend;
# ABSTRACT: the engines Peta::NN can compute on

# Where the arithmetic happens. A backend owns the tensors (a batch of rows:
# inputs, activations, weights, gradients) and implements a dozen operations
# on whole batches; the layers above only say which operation, never how.
#
#   plain   Perl arrays. The reference: every other backend is tested against it.
#   pdl     PDL ndarrays. The efficient CPU form.
#   gpu     WebGPU storage buffers and compute shaders, in 32-bit floats.
#
# What a backend implements (tensors are opaque to the caller):
#
#   tensor(\@flat, $cols)        rows of $cols numbers, row after row
#   tokens(\@flat, $per_row)     rows of token indices, for embed()
#   flat($tensor)                back to a flat Perl list
#   zeros_like($tensor)
#
#   affine($X, $W, $b)                     X W^T + b
#   affine_grad($X, $W, $dY, $need_dx)     (dW, db, dX), summed over the batch
#   activate($kind, $X)
#   activate_grad($kind, $Y, $dY)          in terms of the OUTPUT $Y
#   embed($E, $tokens)                     table rows, concatenated per sample
#   embed_grad($E, $tokens, $dX)           dE
#
#   softmax_ce($logits, \@classes, \@weights)   (summed loss, dlogits)
#   mse($out, \@flat_targets, \@weights)        (summed loss, dout)
#                                          the weights, one per row, are optional
#
#   decay($p, $factor)                     every value times $factor, in place
#
#   sgd_update($p, $g, $velocity, $lr, $momentum, $scale)           in place
#   adam_update($p, $g, $m, $v, $rate, $b1, $b2, $eps, $scale)      in place

use v5.36;

our $VERSION = '0.2610090';

my %CLASS = (
    plain => 'Peta::NN::Backend::Plain',
    pdl   => 'Peta::NN::Backend::PDL',
    gpu   => 'Peta::NN::Backend::WebGPU',
);

# Where a network that is left the choice ('auto') starts: the first of
# these that is there. The GPU is not among them, since opening a device is
# not free; a network goes there from here when it is trained and a few
# timed steps say that pays (Peta::NN, train).
my @AUTO_ORDER = qw(pdl plain);

sub names { return sort keys %CLASS }

# A backend object, or undef when its engine is not in this perl or finds
# nothing to run on (no GPU adapter); $@ then says why.
sub try ($name) {
    my $class = $CLASS{$name} // die "unknown backend '$name' (have: @{[ names() ]}, auto)\n";
    return eval "require $class; $class->new";
}

sub available { return grep { defined try($_) } names() }

sub create ($name) {
    if ($name eq 'auto') {
        for my $candidate (@AUTO_ORDER) {
            my $backend = try($candidate);
            return $backend if $backend;
        }
    }
    return try($name) // die "backend '$name' is not available in this perl: $@";
}

# The index of the largest value in each row. Read through flat(), so every
# backend has it; a batch of outputs is small.
sub argmax_rows ($self, $tensor, $cols) {
    my $flat = $self->flat($tensor);
    my @best;
    for (my $start = 0; $start < @$flat; $start += $cols) {
        my $best = 0;
        for my $i (1 .. $cols - 1) {
            $best = $i if $flat->[ $start + $i ] > $flat->[ $start + $best ];
        }
        push @best, $best;
    }
    return \@best;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Backend - the engines Peta::NN can compute on

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(..., backend => 'pdl');     # or 'plain', 'gpu', 'auto'

    print join ' ', Peta::NN::Backend::available();     # gpu pdl plain

The default is C<plain>, or C<$ENV{PETA_NN_BACKEND}> when set.

=head1 FUNCTIONS

=head2 names

The names of all backends, whether this perl has them or not.

=head2 available

The names of the backends that work in this perl, on this machine.

=head2 try

    my $backend = Peta::NN::Backend::try('gpu') or warn $@;

A backend object, or undef when its engine is not in this perl or finds
nothing to run on; C<$@> then says why.

=head2 create

A backend object for a name or for C<auto>, which takes C<pdl> if it loads
and C<plain> otherwise: that is where a network that is left the choice
starts, and it settles on one of the available backends when it is trained
(L<Peta::NN/train>). Dies if the backend is not available.

=head1 THE BACKEND INTERFACE

A backend owns the tensors (a batch of rows: inputs, activations, weights,
gradients) and implements these operations on whole batches. Tensors are
opaque to the caller.

=over

=item new

A backend object. Dies when the engine is missing.

=item name

The backend's name.

=item tensor

C<tensor(\@flat, $cols)>: rows of C<$cols> numbers, row after row.

=item tokens

C<tokens(\@flat, $per_row)>: rows of token indices, for C<embed>.

=item flat

A tensor as a flat Perl list.

=item zeros_like

A tensor of zeros in the shape of another.

=item affine

C<affine($X, $W, $b)>: X W^T + b.

=item affine_grad

C<affine_grad($X, $W, $dY, $need_dx)>: (dW, db, dX), summed over the batch.

=item activate

C<activate($kind, $X)>: relu, tanh or sigmoid of every value.

=item activate_grad

C<activate_grad($kind, $Y, $dY)>: the gradient, in terms of the output C<$Y>.

=item embed

C<embed($E, $tokens)>: table rows, concatenated per sample.

=item embed_grad

C<embed_grad($E, $tokens, $dX)>: the gradient of the table.

=item softmax_ce

C<softmax_ce($logits, \@classes, \@weights)>: (summed loss, dlogits). The
weights, one per row, are optional.

=item mse

C<mse($out, \@flat_targets, \@weights)>: (summed loss, dout).

=item decay

C<decay($p, $factor)>: every value times C<$factor>, in place.

=item sgd_update

C<sgd_update($p, $g, $velocity, $lr, $momentum, $scale)>, in place.

=item adam_update

C<adam_update($p, $g, $m, $v, $rate, $b1, $b2, $eps, $scale)>, in place.

=item argmax_rows

C<argmax_rows($tensor, $cols)>: the index of the largest value in each row.
Implemented here for every backend.

=back

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
