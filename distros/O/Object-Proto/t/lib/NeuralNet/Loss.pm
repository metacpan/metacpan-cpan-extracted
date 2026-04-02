package NeuralNet::Loss;
use strict;
use warnings;
use Object::Proto;

our $VERSION = '0.01';

# Singleton class for loss functions
# Demonstrates singleton pattern with coderefs stored in slots

BEGIN {
    Object::Proto::define('NeuralNet::Loss',
        'mse',           # Mean Squared Error
        'mse_grad',      # MSE gradient
        'cross_entropy', # Cross-entropy loss
        'ce_grad',       # Cross-entropy gradient
    );
    Object::Proto::import_accessors('NeuralNet::Loss');
    Object::Proto::singleton('NeuralNet::Loss');
}

sub BUILD {
    my ($self) = @_;

    # Mean Squared Error: sum((pred - target)^2) / n
    mse $self, sub {
        my ($pred, $target) = @_;
        my $n = @$pred;
        my $sum = 0;
        for my $i (0 .. $n - 1) {
            my $diff = $pred->[$i] - $target->[$i];
            $sum += $diff * $diff;
        }
        return $sum / $n;
    };

    # MSE gradient: 2 * (pred - target) / n
    mse_grad $self, sub {
        my ($pred, $target) = @_;
        my $n = @$pred;
        my $scale = 2.0 / $n;
        return [map { ($pred->[$_] - $target->[$_]) * $scale } 0 .. $n - 1];
    };

    # Cross-entropy: -sum(target * log(pred))
    cross_entropy $self, sub {
        my ($pred, $target) = @_;
        my $sum = 0;
        my $eps = 1e-15;  # prevent log(0)
        for my $i (0 .. @$pred - 1) {
            my $p = $pred->[$i];
            $p = $eps if $p < $eps;
            $p = 1 - $eps if $p > 1 - $eps;
            $sum -= $target->[$i] * log($p);
        }
        return $sum;
    };

    # Cross-entropy gradient
    ce_grad $self, sub {
        my ($pred, $target) = @_;
        my $eps = 1e-15;
        return [map {
            my $p = $pred->[$_];
            $p = $eps if $p < $eps;
            $p = 1 - $eps if $p > 1 - $eps;
            -$target->[$_] / $p;
        } 0 .. @$pred - 1];
    };
}

1;

__END__

=head1 NAME

NeuralNet::Loss - Loss functions as a singleton

=head1 SYNOPSIS

    use NeuralNet::Loss;

    my $loss = NeuralNet::Loss->instance;
    my $error = $loss->mse->([0.9, 0.1], [1.0, 0.0]);

=cut
