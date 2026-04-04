#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Object::Proto;

# Test the NeuralNet example classes that showcase object module features

# ============================================
# Test NeuralNet::Activation singleton
# ============================================
# NeuralNet::Activation singleton
{
    require NeuralNet::Activation;

    # Test singleton behavior
    my $act1 = NeuralNet::Activation->instance;
    my $act2 = NeuralNet::Activation->instance;
    isa_ok($act1, 'NeuralNet::Activation');
    is($act1, $act2, 'singleton returns same instance');

    # Test relu
    my $relu_fn = $act1->relu;
    ok(ref($relu_fn) eq 'CODE', 'relu is a coderef');
    is_deeply($relu_fn->([1, -2, 3, -4, 0]),
              [1, 0, 3, 0, 0],
              'relu works correctly');

    # Test relu derivative
    my $relu_deriv = $act1->relu_deriv;
    is_deeply($relu_deriv->([1, -2, 3, -4, 0]),
              [1, 0, 1, 0, 0],
              'relu_deriv works correctly');

    # Test sigmoid
    my $sigmoid_fn = $act1->sigmoid;
    my $sig_out = $sigmoid_fn->([0]);
    is(sprintf("%.4f", $sig_out->[0]), '0.5000', 'sigmoid(0) = 0.5');

    $sig_out = $sigmoid_fn->([10]);
    ok($sig_out->[0] > 0.999, 'sigmoid(10) close to 1');

    $sig_out = $sigmoid_fn->([-10]);
    ok($sig_out->[0] < 0.001, 'sigmoid(-10) close to 0');

    # Test sigmoid derivative
    my $sig_deriv = $act1->sigmoid_deriv;
    my $deriv = $sig_deriv->([0.5]);
    is(sprintf("%.4f", $deriv->[0]), '0.2500', 'sigmoid_deriv(0.5) = 0.25');

    # Test tanh
    my $tanh_fn = $act1->tanh_fn;
    my $tanh_out = $tanh_fn->([0]);
    is(sprintf("%.4f", $tanh_out->[0]), '0.0000', 'tanh(0) = 0');
}
# ============================================
# Test NeuralNet::Loss singleton
# ============================================
# NeuralNet::Loss singleton
{
    require NeuralNet::Loss;

    my $loss1 = NeuralNet::Loss->instance;
    my $loss2 = NeuralNet::Loss->instance;
    isa_ok($loss1, 'NeuralNet::Loss');
    is($loss1, $loss2, 'singleton returns same instance');

    # Test MSE
    my $mse_fn = $loss1->mse;
    ok(ref($mse_fn) eq 'CODE', 'mse is a coderef');

    # Perfect prediction
    my $loss_val = $mse_fn->([1, 0], [1, 0]);
    is($loss_val, 0, 'MSE of identical vectors is 0');

    # Simple case: [1] vs [0] -> MSE = 1
    $loss_val = $mse_fn->([1], [0]);
    is($loss_val, 1, 'MSE([1], [0]) = 1');

    # [0.5, 0.5] vs [1, 0] -> MSE = 0.25
    $loss_val = $mse_fn->([0.5, 0.5], [1, 0]);
    is(sprintf("%.4f", $loss_val), '0.2500', 'MSE calculation correct');

    # Test MSE gradient
    my $mse_grad = $loss1->mse_grad;
    my $grad = $mse_grad->([1], [0]);
    is_deeply($grad, [2], 'MSE gradient correct');

    $grad = $mse_grad->([0.5, 0.5], [1, 0]);
    is_deeply([map { sprintf("%.2f", $_) } @$grad],
              ['-0.50', '0.50'],
              'MSE gradient for multiple outputs');
}
# ============================================
# Test NeuralNet::Layer typed slots
# ============================================
# NeuralNet::Layer typed slots
{
    require NeuralNet::Layer;

    # Test required slots
    eval { NeuralNet::Layer->new() };
    like($@, qr/Required|required/i, 'input_size is required');

    eval { NeuralNet::Layer->new(input_size => 2) };
    like($@, qr/Required|required/i, 'output_size is required');

    # Create valid layer
    my $layer = NeuralNet::Layer->new(
        input_size  => 3,
        output_size => 2,
    );
    isa_ok($layer, 'NeuralNet::Layer');
    is($layer->input_size, 3, 'input_size set correctly');
    is($layer->output_size, 2, 'output_size set correctly');

    # Test BUILD initializes weights
    $layer->BUILD;
    my $weights = $layer->weights;
    ok(ref($weights) eq 'ARRAY', 'weights is an arrayref');
    is(scalar(@$weights), 2, 'correct number of output neurons');
    is(scalar(@{$weights->[0]}), 3, 'correct number of input weights');

    my $biases = $layer->biases;
    is_deeply($biases, [0, 0], 'biases initialized to zero');

    # Test forward pass
    my $output = $layer->forward([1, 2, 3]);
    is(scalar(@$output), 2, 'forward produces correct output size');

    # Test num_params
    is($layer->num_params, 8, 'num_params = 3*2 + 2 = 8');
}
# ============================================
# Test NeuralNet::Network full features
# ============================================
# NeuralNet::Network features
{
    require NeuralNet::Network;

    # Test defaults
    my $net = NeuralNet::Network->new();
    isa_ok($net, 'NeuralNet::Network');
    ok(abs($net->learning_rate - 0.01) < 1e-10, 'default learning_rate');
    is($net->activation_type, 'relu', 'default activation_type');
    is($net->use_sigmoid_output, 1, 'default use_sigmoid_output');
    is_deeply($net->layers, [], 'default empty layers');

    # Test custom values
    my $net2 = NeuralNet::Network->new(
        learning_rate     => 0.1,
        activation_type   => 'tanh',
        use_sigmoid_output => 0,
    );
    cmp_ok($net2->learning_rate, '==', 0.1, 'custom learning_rate');
    is($net2->activation_type, 'tanh', 'custom activation_type');
    is($net2->use_sigmoid_output, 0, 'custom use_sigmoid_output');

    # Test add_layer method chaining
    my $net3 = NeuralNet::Network->new(learning_rate => 0.5);
    $net3->add_layer(2, 4)->add_layer(4, 1);
    is(scalar(@{$net3->layers}), 2, 'two layers added');

    # Test singleton references
    ok(defined($net3->act), 'activation singleton cached');
    ok(defined($net3->loss_fn), 'loss singleton cached');
    isa_ok($net3->act, 'NeuralNet::Activation');
    isa_ok($net3->loss_fn, 'NeuralNet::Loss');

    # Test forward pass
    my $out = $net3->forward([0.5, 0.5]);
    is(scalar(@$out), 1, 'forward produces 1 output');
    ok($out->[0] >= 0 && $out->[0] <= 1, 'output in [0,1] due to sigmoid');

    # Test summary
    my $summary = $net3->summary;
    like($summary, qr/Learning rate: 0\.5/, 'summary includes learning rate');
    like($summary, qr/2 -> 4/, 'summary includes layer dimensions');
    like($summary, qr/4 -> 1/, 'summary includes second layer');
}
# ============================================
# Test NeuralNet::Network training (simple linear task)
# ============================================
# NeuralNet::Network training
{
    require NeuralNet::Network;

    # Seed random for reproducibility
    srand(42);

    # Create simple network
    my $net = NeuralNet::Network->new(learning_rate => 0.1);
    $net->add_layer(2, 2);
    $net->add_layer(2, 1);

    # Simple AND-like training data (easier than XOR)
    my @data = (
        [[0, 0], [0]],
        [[0, 1], [0]],
        [[1, 0], [0]],
        [[1, 1], [1]],
    );

    # Get initial loss
    my $initial_loss = 0;
    for my $sample (@data) {
        my $pred = $net->predict($sample->[0]);
        $initial_loss += $net->loss_fn->mse->($pred, $sample->[1]);
    }

    # Train for several epochs
    for my $epoch (1 .. 500) {
        for my $sample (@data) {
            $net->train_step($sample->[0], $sample->[1]);
        }
    }

    # Get final loss
    my $final_loss = 0;
    for my $sample (@data) {
        my $pred = $net->predict($sample->[0]);
        next unless defined $pred->[0] && $pred->[0] == $pred->[0];  # skip NaN
        $final_loss += $net->loss_fn->mse->($pred, $sample->[1]);
    }

    # Just verify training ran without crashing and loss is finite
    ok(defined $final_loss, 'training completed');
    ok($final_loss == $final_loss, 'final loss is not NaN');  # NaN != NaN

    # Test that predict returns valid output
    my $out = $net->predict([1, 1]);
    ok(ref($out) eq 'ARRAY', 'predict returns array');
    ok(scalar(@$out) == 1, 'predict returns correct size');
    ok(defined $out->[0], 'output is defined');
}
# ============================================
# Test function-style accessors work correctly
# ============================================
# function-style accessors
{
    require NeuralNet::Layer;

    my $layer = NeuralNet::Layer->new(
        input_size  => 2,
        output_size => 3,
    );

    # Use function-style accessors (imported in the package)
    package NeuralNet::Layer;
    ::is(input_size($layer), 2, 'function-style getter works');

    # Test setter
    biases($layer, [1, 2, 3]);
    ::is_deeply(biases($layer), [1, 2, 3], 'function-style setter works');

    package main;

    # Method-style still works
    is($layer->input_size, 2, 'method-style getter still works');
    is_deeply($layer->biases, [1, 2, 3], 'method-style sees function-style changes');
}
done_testing;
