package NeuralNet::Layer;
use strict;
use warnings;
use Object::Proto;

our $VERSION = '0.01';

# Demonstrates:
# - Typed slots (Int, ArrayRef)
# - Required slots
# - Default values
# - function-style accessors
# - Custom methods

BEGIN {
    Object::Proto::define('NeuralNet::Layer',
        'input_size:Int:required',
        'output_size:Int:required',
        'weights:ArrayRef',
        'biases:ArrayRef',
        'last_input:ArrayRef',
        'last_output:ArrayRef',
        'weight_grads:ArrayRef',
        'bias_grads:ArrayRef',
    );
    Object::Proto::import_accessors('NeuralNet::Layer');
}

sub BUILD {
    my ($self) = @_;
    my $in = input_size $self;
    my $out = output_size $self;

    # Initialize weights with small random values (Xavier-ish)
    my $scale = sqrt(2.0 / ($in + $out));
    my @w;
    for my $i (0 .. $out - 1) {
        my @row;
        for my $j (0 .. $in - 1) {
            push @row, (rand() - 0.5) * 2 * $scale;
        }
        push @w, \@row;
    }
    weights $self, \@w;

    # Initialize biases to zero
    biases $self, [(0) x $out];

    # Initialize gradient accumulators
    weight_grads $self, [map { [(0) x $in] } 1 .. $out];
    bias_grads $self, [(0) x $out];
}

sub forward {
    my ($self, $input) = @_;
    last_input $self, $input;

    my $w = weights $self;
    my $b = biases $self;
    my $out_size = output_size $self;

    my @output;
    for my $i (0 .. $out_size - 1) {
        my $sum = $b->[$i];
        for my $j (0 .. @$input - 1) {
            $sum += $w->[$i][$j] * $input->[$j];
        }
        push @output, $sum;
    }

    last_output $self, \@output;
    return \@output;
}

sub backward {
    my ($self, $grad) = @_;
    my $input = last_input $self;
    my $w = weights $self;
    my $in_size = input_size $self;
    my $out_size = output_size $self;

    # Compute weight gradients
    my $wg = weight_grads $self;
    my $bg = bias_grads $self;

    for my $i (0 .. $out_size - 1) {
        $bg->[$i] += $grad->[$i];
        for my $j (0 .. $in_size - 1) {
            $wg->[$i][$j] += $grad->[$i] * $input->[$j];
        }
    }

    # Compute gradient w.r.t. input
    my @input_grad = (0) x $in_size;
    for my $j (0 .. $in_size - 1) {
        for my $i (0 .. $out_size - 1) {
            $input_grad[$j] += $w->[$i][$j] * $grad->[$i];
        }
    }

    return \@input_grad;
}

sub update {
    my ($self, $lr) = @_;
    my $w = weights $self;
    my $b = biases $self;
    my $wg = weight_grads $self;
    my $bg = bias_grads $self;

    my $out_size = output_size $self;
    my $in_size = input_size $self;

    # Update weights and biases
    for my $i (0 .. $out_size - 1) {
        $b->[$i] -= $lr * $bg->[$i];
        $bg->[$i] = 0;  # Reset gradient
        for my $j (0 .. $in_size - 1) {
            $w->[$i][$j] -= $lr * $wg->[$i][$j];
            $wg->[$i][$j] = 0;  # Reset gradient
        }
    }
}

sub num_params {
    my ($self) = @_;
    my $in = input_size $self;
    my $out = output_size $self;
    return $in * $out + $out;  # weights + biases
}

1;

__END__

=head1 NAME

NeuralNet::Layer - Dense layer with typed slots

=head1 SYNOPSIS

    use NeuralNet::Layer;

    my $layer = NeuralNet::Layer->new(
        input_size  => 4,
        output_size => 2,
    );
    $layer->BUILD;

    my $out = $layer->forward([1, 2, 3, 4]);

=head1 DESCRIPTION

Demonstrates typed slots (Int:required), ArrayRef slots,
function-style accessors, and custom methods.

=cut
