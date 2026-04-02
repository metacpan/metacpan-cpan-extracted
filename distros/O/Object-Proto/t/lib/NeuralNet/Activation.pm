package NeuralNet::Activation;
use strict;
use warnings;
use Object::Proto;
use POSIX qw(tanh);

our $VERSION = '0.01';

# Singleton class demonstrating:
# - Object::Proto::define with slots
# - Object::Proto::import_accessors for function-style access
# - Object::Proto::singleton for auto-generated instance() method
# - BUILD method for initialization

BEGIN {
    Object::Proto::define('NeuralNet::Activation',
        'relu',
        'relu_deriv',
        'sigmoid',
        'sigmoid_deriv',
        'tanh_fn',
        'tanh_deriv',
    );
    Object::Proto::import_accessors('NeuralNet::Activation');
    Object::Proto::singleton('NeuralNet::Activation');
}

sub BUILD {
    my ($self) = @_;

    # ReLU: max(0, x)
    relu $self, sub {
        my ($x) = @_;
        return [map { $_ > 0 ? $_ : 0 } @$x];
    };

    # ReLU derivative: 1 if x > 0, else 0
    relu_deriv $self, sub {
        my ($x) = @_;
        return [map { $_ > 0 ? 1 : 0 } @$x];
    };

    # Sigmoid: 1 / (1 + exp(-x))
    sigmoid $self, sub {
        my ($x) = @_;
        return [map { 1.0 / (1.0 + exp(-$_)) } @$x];
    };

    # Sigmoid derivative: s * (1 - s) where s is sigmoid output
    sigmoid_deriv $self, sub {
        my ($s) = @_;  # expects sigmoid output, not raw input
        return [map { $_ * (1 - $_) } @$s];
    };

    # Tanh
    tanh_fn $self, sub {
        my ($x) = @_;
        return [map { tanh($_) } @$x];
    };

    # Tanh derivative: 1 - tanh^2
    tanh_deriv $self, sub {
        my ($t) = @_;  # expects tanh output
        return [map { 1 - $_ * $_ } @$t];
    };
}

1;

__END__

=head1 NAME

NeuralNet::Activation - Activation functions as a singleton

=head1 SYNOPSIS

    use NeuralNet::Activation;

    my $act = NeuralNet::Activation->instance;
    my $output = $act->relu->([1, -2, 3, -4]);
    # [1, 0, 3, 0]

=head1 DESCRIPTION

Demonstrates singleton pattern with Object::Proto::singleton().

=cut
