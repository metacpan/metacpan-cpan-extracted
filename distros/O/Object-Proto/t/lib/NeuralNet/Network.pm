package NeuralNet::Network;
use strict;
use warnings;
use Object::Proto;
use NeuralNet::Layer;
use NeuralNet::Activation;
use NeuralNet::Loss;

our $VERSION = '0.01';

# Demonstrates:
# - Typed slots with defaults
# - Bool type
# - Using singletons (Activation, Loss)
# - Complex methods
# - function-style accessors throughout

BEGIN {
    Object::Proto::define('NeuralNet::Network',
        'layers:ArrayRef:default([])',
        'learning_rate:Num:default(0.01)',
        'activation_type:Str:default(relu)',
        'use_sigmoid_output:Bool:default(1)',
        'act',      # cached activation singleton
        'loss_fn',  # cached loss singleton
    );
    Object::Proto::import_accessors('NeuralNet::Network');
}

sub BUILD {
    my ($self) = @_;
    act $self, NeuralNet::Activation->instance;
    loss_fn $self, NeuralNet::Loss->instance;
}

sub add_layer {
    my ($self, $input_size, $output_size) = @_;
    BUILD($self) unless act $self;

    my $layer = NeuralNet::Layer->new(
        input_size  => $input_size,
        output_size => $output_size,
    );
    $layer->BUILD;

    push @{layers $self}, $layer;
    return $self;
}

sub forward {
    my ($self, $input) = @_;
    my $x = $input;
    my $activation = act $self;
    my @layer_list = @{layers $self};
    my $act_type = activation_type $self;

    for my $i (0 .. $#layer_list) {
        my $layer = $layer_list[$i];
        $x = $layer->forward($x);

        # Apply activation (sigmoid on output if configured, else relu/tanh)
        if ($i < $#layer_list) {
            # Hidden layers
            if ($act_type eq 'relu') {
                $x = $activation->relu->($x);
            } elsif ($act_type eq 'tanh') {
                $x = $activation->tanh_fn->($x);
            } else {
                $x = $activation->sigmoid->($x);
            }
        } elsif (use_sigmoid_output $self) {
            # Output layer with sigmoid
            $x = $activation->sigmoid->($x);
        }
    }

    return $x;
}

sub train_step {
    my ($self, $input, $target) = @_;

    my $output = forward($self, $input);

    my $activation = act $self;
    my $loss = loss_fn $self;

    # Compute loss
    my $loss_val = $loss->mse->($output, $target);

    # Compute initial gradient
    my $grad = $loss->mse_grad->($output, $target);

    my @layer_list = @{layers $self};
    my $act_type = activation_type $self;

    # Backprop through layers
    for my $i (reverse 0 .. $#layer_list) {
        my $layer = $layer_list[$i];

        # Apply activation gradient
        if ($i == $#layer_list && (use_sigmoid_output $self)) {
            my $sig_grad = $activation->sigmoid_deriv->($layer->last_output);
            $grad = [map { $grad->[$_] * $sig_grad->[$_] } 0 .. @$grad - 1];
        } elsif ($i < $#layer_list) {
            if ($act_type eq 'relu') {
                my $relu_grad = $activation->relu_deriv->($layer->last_output);
                $grad = [map { $grad->[$_] * $relu_grad->[$_] } 0 .. @$grad - 1];
            }
        }

        $grad = $layer->backward($grad);
    }

    # Update all layers
    my $lr = learning_rate $self;
    for my $layer (@layer_list) {
        $layer->update($lr);
    }

    return $loss_val;
}

sub predict {
    my ($self, $input) = @_;
    return forward($self, $input);
}

sub summary {
    my ($self) = @_;
    my @layer_list = @{layers $self};
    my $total_params = 0;
    my @lines = ("Network Summary:");
    push @lines, sprintf("  Learning rate: %g", learning_rate $self);
    push @lines, sprintf("  Activation: %s", activation_type $self);
    push @lines, sprintf("  Sigmoid output: %s", (use_sigmoid_output $self) ? 'yes' : 'no');
    push @lines, "  Layers:";

    for my $i (0 .. $#layer_list) {
        my $layer = $layer_list[$i];
        my $params = $layer->num_params;
        $total_params += $params;
        push @lines, sprintf("    [%d] %d -> %d (%d params)",
            $i, $layer->input_size, $layer->output_size, $params);
    }
    push @lines, sprintf("  Total params: %d", $total_params);
    return join("\n", @lines);
}

1;

__END__

=head1 NAME

NeuralNet::Network - Neural network using object module features

=head1 SYNOPSIS

    use NeuralNet::Network;

    my $net = NeuralNet::Network->new(learning_rate => 0.1);
    $net->add_layer(2, 4);
    $net->add_layer(4, 1);

    # Train on XOR
    for (1 .. 1000) {
        $net->train_step([0, 0], [0]);
        $net->train_step([0, 1], [1]);
        $net->train_step([1, 0], [1]);
        $net->train_step([1, 1], [0]);
    }

    my $out = $net->predict([1, 0]);

=head1 DESCRIPTION

Demonstrates typed slots with defaults, Bool type, singleton usage,
and function-style accessors for building a neural network.

=cut
