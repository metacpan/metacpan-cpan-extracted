package Peta::NN::Backend::PDL;
# ABSTRACT: Peta::NN on PDL ndarrays

# The CPU backend on PDL: a tensor is an ndarray of dims (cols, rows), which
# is PDL's own order for "rows of cols numbers", so a flat row-after-row list
# maps onto it without rearranging. Every operation is a handful of whole-array
# expressions; the batch never passes through a Perl loop.

use v5.36;

# PDL exports dozens of functions, flat() among them, which is a method here.
# They are imported into a package of their own; this one calls PDL by name.
{
    package Peta::NN::Backend::PDL::Imports;
    use PDL::LiteF;
}

use parent -norequire, 'Peta::NN::Backend';
use Peta::NN::Backend;

our $VERSION = '0.2610090';

my $TINY = 1e-300;    # keeps log() defined when a probability underflows

sub new ($class) { return bless {}, $class }

sub name ($self) { return 'pdl' }

sub tensor ($self, $flat, $cols) {
    return PDL->pdl(PDL::double(), $flat)->reshape($cols, @$flat / $cols);
}

# Tokens stay a Perl list: all a backend does with them is build an index.
sub tokens ($self, $flat, $per_row) { return [ [@$flat], $per_row ] }

sub flat ($self, $tensor) { return [ $tensor->list ] }

sub zeros_like ($self, $tensor) { return PDL->zeroes(PDL::double(), $tensor->dims) }

# X is (in, batch), W is (in, out): X x W^T is (out, batch), and b of dims
# (out) broadcasts over the rows.
sub affine ($self, $X, $W, $b) {
    return ($X x $W->transpose) + $b;
}

sub affine_grad ($self, $X, $W, $dY, $need_dx) {
    my $gW = $dY->transpose x $X;         # (in, out)
    my $gb = $dY->mv(1, 0)->sumover;      # summed over the batch: (out)
    return ($gW, $gb) if !$need_dx;
    return ($gW, $gb, $dY x $W);          # (in, batch)
}

my %ACTIVATE = (
    relu    => sub ($x) { $x * ($x > 0) },
    tanh    => sub ($x) { PDL::tanh($x) },
    sigmoid => sub ($x) { 1 / (1 + exp(-$x)) },
);

my %ACTIVATE_GRAD = (
    relu    => sub ($y, $dy) { $dy * ($y > 0) },
    tanh    => sub ($y, $dy) { $dy * (1 - $y * $y) },
    sigmoid => sub ($y, $dy) { $dy * $y * (1 - $y) },
);

sub activate ($self, $kind, $X) {
    my $f = $ACTIVATE{$kind} // die "unknown activation '$kind'\n";
    return $f->($X);
}

sub activate_grad ($self, $kind, $Y, $dY) {
    my $f = $ACTIVATE_GRAD{$kind} // die "unknown activation '$kind'\n";
    return $f->($Y, $dY);
}

# One row per token, a single 1 in the column of its index: (vocab, tokens).
# Lookup and its gradient are then both one matrix product.
sub _one_hot ($tokens, $vocab) {
    my $index = PDL->pdl(PDL::long(), $tokens->[0]);
    my $hot   = PDL->zeroes(PDL::double(), $vocab, $index->nelem);
    (my $ones = $hot->index($index)) .= 1;
    return $hot;
}

sub embed ($self, $E, $tokens) {
    my ($dim, $vocab) = $E->dims;
    my $rows = _one_hot($tokens, $vocab) x $E;                # (dim, tokens)
    my $per_row = $tokens->[1];
    return $rows->reshape($dim * $per_row, @{ $tokens->[0] } / $per_row);
}

sub embed_grad ($self, $E, $tokens, $dX) {
    my ($dim, $vocab) = $E->dims;
    my $count = @{ $tokens->[0] };
    return _one_hot($tokens, $vocab)->transpose x $dX->copy->reshape($dim, $count);
}

sub softmax_ce ($self, $logits, $classes, $weights = undef) {
    my $class = PDL->pdl(PDL::long(), $classes);
    my $p     = exp($logits - $logits->maximum->dummy(0));
    $p /= $p->sumover->dummy(0);
    my $row_loss = -log($p->index($class) + $TINY);
    (my $hit = $p->index($class)) -= 1;
    return ($row_loss->sum, $p) if !$weights;
    my $weight = PDL->pdl(PDL::double(), $weights);          # one per row
    return (($row_loss * $weight)->sum, $p * $weight->dummy(0));
}

sub mse ($self, $out, $targets, $weights = undef) {
    my ($cols) = $out->dims;
    my $diff = $out - $self->tensor($targets, $cols);
    return (($diff * $diff)->sum / $cols, 2 * $diff / $cols) if !$weights;
    my $weight = PDL->pdl(PDL::double(), $weights);
    return ((($diff * $diff)->sumover * $weight)->sum / $cols, 2 * $diff * $weight->dummy(0) / $cols);
}

# Multiply every value by $factor, in place: weight decay.
sub decay ($self, $P, $factor) {
    $P *= $factor;
    return;
}

sub sgd_update ($self, $P, $G, $V, $lr, $momentum, $scale) {
    $V *= $momentum;
    $V -= ($lr * $scale) * $G;
    $P += $V;
    return;
}

sub adam_update ($self, $P, $G, $M, $V, $rate, $b1, $b2, $eps, $scale) {
    my $grad = $scale * $G;
    $M *= $b1;
    $M += (1 - $b1) * $grad;
    $V *= $b2;
    $V += (1 - $b2) * $grad * $grad;
    $P -= $rate * $M / (sqrt($V) + $eps);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Backend::PDL - Peta::NN on PDL ndarrays

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'pdl');

=head1 DESCRIPTION

Double precision, on the CPU. Results agree with the plain backend to
rounding, not to the bit: a matrix product sums in another order. See
L<Peta::NN::Backend> for the operations.

=head1 METHODS

This class implements the backend interface described in
L<Peta::NN::Backend/"THE BACKEND INTERFACE"> and adds nothing to it.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
