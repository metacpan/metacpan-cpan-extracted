package Peta::NN::Backend::Plain;
# ABSTRACT: Peta::NN on plain Perl arrays

# The reference backend: a tensor is [ \@numbers, $cols ], row after row, and
# every operation is a plain Perl loop.
#
# Each kernel first aliases the tensors' arrays to lexical arrays (\my @W =
# ...). The loops then read as ordinary array code, which is also the form
# pperl's JIT compiles; through the references themselves it does not.

use v5.36;
use feature 'refaliasing';
no warnings 'experimental::refaliasing';

use parent -norequire, 'Peta::NN::Backend';
use Peta::NN::Backend;

our $VERSION = '0.2610090';

my $SATURATED = 20;        # beyond this exp() adds nothing in a double
my $TINY      = 1e-300;    # keeps log() defined when a probability underflows

sub new ($class) { return bless {}, $class }

sub name ($self) { return 'plain' }

sub tensor ($self, $flat, $cols) { return [ [@$flat], $cols ] }
sub tokens ($self, $flat, $per_row) { return [ [@$flat], $per_row ] }
sub flat ($self, $tensor) { return [ @{ $tensor->[0] } ] }
sub zeros_like ($self, $tensor) { return [ [ (0.0) x @{ $tensor->[0] } ], $tensor->[1] ] }

sub affine ($self, $X, $W, $b) {
    \my @x = $X->[0];
    \my @W = $W->[0];
    \my @b = $b->[0];
    my $n_in  = $X->[1];
    my $n_out = @b;
    my $batch = @x / $n_in;
    my @y     = (0.0) x ($batch * $n_out);
    for my $s (0 .. $batch - 1) {
        my $x_at = $s * $n_in;
        my $y_at = $s * $n_out;
        for my $j (0 .. $n_out - 1) {
            my $sum  = $b[$j];
            my $w_at = $j * $n_in;
            for my $i (0 .. $n_in - 1) {
                $sum += $W[ $w_at + $i ] * $x[ $x_at + $i ];
            }
            $y[ $y_at + $j ] = $sum;
        }
    }
    return [ \@y, $n_out ];
}

sub affine_grad ($self, $X, $W, $dY, $need_dx) {
    \my @x  = $X->[0];
    \my @W  = $W->[0];
    \my @dy = $dY->[0];
    my $n_in  = $X->[1];
    my $n_out = $dY->[1];
    my $batch = @x / $n_in;
    my @gW = (0.0) x @W;
    my @gb = (0.0) x $n_out;
    for my $s (0 .. $batch - 1) {
        my $x_at = $s * $n_in;
        my $y_at = $s * $n_out;
        for my $j (0 .. $n_out - 1) {
            my $d    = $dy[ $y_at + $j ];
            my $w_at = $j * $n_in;
            $gb[$j] += $d;
            for my $i (0 .. $n_in - 1) {
                $gW[ $w_at + $i ] += $d * $x[ $x_at + $i ];
            }
        }
    }
    return ([ \@gW, $n_in ], [ \@gb, $n_out ]) if !$need_dx;

    my @dx = (0.0) x @x;
    for my $s (0 .. $batch - 1) {
        my $x_at = $s * $n_in;
        my $y_at = $s * $n_out;
        for my $j (0 .. $n_out - 1) {
            my $d    = $dy[ $y_at + $j ];
            my $w_at = $j * $n_in;
            for my $i (0 .. $n_in - 1) {
                $dx[ $x_at + $i ] += $W[ $w_at + $i ] * $d;
            }
        }
    }
    return ([ \@gW, $n_in ], [ \@gb, $n_out ], [ \@dx, $n_in ]);
}

sub activate ($self, $kind, $X) {
    \my @x = $X->[0];
    my @y = (0.0) x @x;
    if ($kind eq 'relu') {
        for my $i (0 .. $#x) { $y[$i] = $x[$i] > 0 ? $x[$i] : 0.0 }
    }
    elsif ($kind eq 'tanh') {
        for my $i (0 .. $#x) {
            my $v = $x[$i];
            if    ($v >  $SATURATED) { $y[$i] =  1.0 }
            elsif ($v < -$SATURATED) { $y[$i] = -1.0 }
            else                     { my $e = exp(2 * $v); $y[$i] = ($e - 1) / ($e + 1) }
        }
    }
    elsif ($kind eq 'sigmoid') {
        for my $i (0 .. $#x) {
            my $v = $x[$i];
            $y[$i] = $v > $SATURATED ? 1.0 : $v < -$SATURATED ? 0.0 : 1 / (1 + exp(-$v));
        }
    }
    else { die "unknown activation '$kind'\n" }
    return [ \@y, $X->[1] ];
}

sub activate_grad ($self, $kind, $Y, $dY) {
    \my @y  = $Y->[0];
    \my @dy = $dY->[0];
    my @dx = (0.0) x @y;
    if ($kind eq 'relu') {
        for my $i (0 .. $#y) { $dx[$i] = $y[$i] > 0 ? $dy[$i] : 0.0 }
    }
    elsif ($kind eq 'tanh') {
        for my $i (0 .. $#y) { $dx[$i] = $dy[$i] * (1 - $y[$i] * $y[$i]) }
    }
    elsif ($kind eq 'sigmoid') {
        for my $i (0 .. $#y) { $dx[$i] = $dy[$i] * $y[$i] * (1 - $y[$i]) }
    }
    else { die "unknown activation '$kind'\n" }
    return [ \@dx, $Y->[1] ];
}

sub embed ($self, $E, $tokens) {
    my ($table, $dim) = @$E;
    my @y;
    for my $token (@{ $tokens->[0] }) {
        my $at = $token * $dim;
        push @y, @$table[ $at .. $at + $dim - 1 ];
    }
    return [ \@y, $tokens->[1] * $dim ];
}

sub embed_grad ($self, $E, $tokens, $dX) {
    \my @dx = $dX->[0];
    my $dim = $E->[1];
    my @gE  = (0.0) x @{ $E->[0] };
    my $pos = 0;
    for my $token (@{ $tokens->[0] }) {
        my $at = $token * $dim;
        for my $k (0 .. $dim - 1) {
            $gE[ $at + $k ] += $dx[ $pos++ ];
        }
    }
    return [ \@gE, $dim ];
}

# Cross entropy on softmax, per row; with both taken together the gradient
# is p - onehot. The row maximum is subtracted first so exp() stays small.
sub softmax_ce ($self, $logits, $classes, $weights = undef) {
    \my @z = $logits->[0];
    my $cols = $logits->[1];
    my @d    = (0.0) x @z;
    my $loss = 0;
    for my $s (0 .. $#$classes) {
        my $at  = $s * $cols;
        my $max = $z[$at];
        for my $i (1 .. $cols - 1) { $max = $z[ $at + $i ] if $z[ $at + $i ] > $max }
        my $sum = 0;
        for my $i (0 .. $cols - 1) {
            my $e = exp($z[ $at + $i ] - $max);
            $d[ $at + $i ] = $e;
            $sum += $e;
        }
        for my $i (0 .. $cols - 1) { $d[ $at + $i ] /= $sum }
        my $target = $at + $classes->[$s];
        my $weight = $weights ? $weights->[$s] : 1;
        $loss -= $weight * log($d[$target] + $TINY);
        $d[$target] -= 1;
        next if $weight == 1;
        for my $i (0 .. $cols - 1) { $d[ $at + $i ] *= $weight }
    }
    return ($loss, [ \@d, $cols ]);
}

# Mean squared error per row, summed over the rows.
sub mse ($self, $out, $targets, $weights = undef) {
    \my @o = $out->[0];
    my $cols = $out->[1];
    my @d    = (0.0) x @o;
    my $loss = 0;
    for my $i (0 .. $#o) {
        my $diff   = $o[$i] - $targets->[$i];
        my $weight = $weights ? $weights->[ int($i / $cols) ] : 1;
        $loss += $weight * $diff * $diff;
        $d[$i] = $weight * 2 * $diff / $cols;
    }
    return ($loss / $cols, [ \@d, $cols ]);
}

# Multiply every value by $factor, in place: weight decay.
sub decay ($self, $P, $factor) {
    \my @p = $P->[0];
    for my $i (0 .. $#p) { $p[$i] *= $factor }
    return;
}

sub sgd_update ($self, $P, $G, $V, $lr, $momentum, $scale) {
    \my @p = $P->[0];
    \my @g = $G->[0];
    \my @v = $V->[0];
    for my $i (0 .. $#p) {
        $v[$i] = $momentum * $v[$i] - $lr * $scale * $g[$i];
        $p[$i] += $v[$i];
    }
    return;
}

sub adam_update ($self, $P, $G, $M, $V, $rate, $b1, $b2, $eps, $scale) {
    \my @p = $P->[0];
    \my @g = $G->[0];
    \my @m = $M->[0];
    \my @v = $V->[0];
    for my $i (0 .. $#p) {
        my $grad = $scale * $g[$i];
        $m[$i] = $b1 * $m[$i] + (1 - $b1) * $grad;
        $v[$i] = $b2 * $v[$i] + (1 - $b2) * $grad * $grad;
        $p[$i] -= $rate * $m[$i] / (sqrt($v[$i]) + $eps);
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Backend::Plain - Peta::NN on plain Perl arrays

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'plain');

=head1 DESCRIPTION

Needs nothing but perl, runs on perl5, and gives bit-identical results on
every perl. See L<Peta::NN::Backend> for the operations.

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
