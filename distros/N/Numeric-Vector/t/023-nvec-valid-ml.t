#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use lib 't/lib';

use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

# ============================================
# Machine Learning Style Integration Tests
# ============================================

subtest 'feature normalization (min-max scaling)' => sub {
    my $features = Numeric::Vector::new([10, 20, 30, 40, 50]);

    my $min = $features->min();
    my $max = $features->max();

    # Scale to [0, 1]: (x - min) / (max - min)
    my $shifted = $features->add_scalar(-$min);
    my $scaled = $shifted->scale(1.0 / ($max - $min));

    within_tolerance($scaled->min(), 0, 'min-max scaled min = 0');
    within_tolerance($scaled->max(), 1, 'min-max scaled max = 1');
};

subtest 'L2 normalization (unit vectors)' => sub {
    my $v = Numeric::Vector::new([3, 4]);  # 3-4-5 triangle

    my $unit = $v->normalize();

    within_tolerance($unit->norm(), 1, 'normalized vector has unit norm');
    within_tolerance($unit->get(0), 0.6, 'normalized x = 3/5');
    within_tolerance($unit->get(1), 0.8, 'normalized y = 4/5');
};

subtest 'cosine similarity for document vectors' => sub {
    # Two similar vectors
    my $doc1 = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $doc2 = Numeric::Vector::new([1, 2, 3, 4, 6]);  # Slightly different

    my $sim = $doc1->cosine_similarity($doc2);
    ok($sim > 0.99, 'similar vectors have high cosine similarity');

    # Orthogonal vectors
    my $v1 = Numeric::Vector::new([1, 0]);
    my $v2 = Numeric::Vector::new([0, 1]);
    within_tolerance($v1->cosine_similarity($v2), 0, 'orthogonal vectors have 0 similarity');

    # Identical vectors
    within_tolerance($doc1->cosine_similarity($doc1), 1, 'identical vectors have similarity 1');
};

subtest 'euclidean distance' => sub {
    my $a = Numeric::Vector::new([0, 0, 0]);
    my $b = Numeric::Vector::new([3, 4, 0]);  # 3-4-5

    within_tolerance($a->distance($b), 5, 'euclidean distance = 5');

    # Distance to self
    within_tolerance($a->distance($a), 0, 'distance to self = 0');
};

subtest 'dot product for similarity' => sub {
    my $a = Numeric::Vector::new([1, 0, 1]);
    my $b = Numeric::Vector::new([1, 1, 0]);

    within_tolerance($a->dot($b), 1, 'dot product = 1');

    # Self dot = squared norm
    my $self_dot = $a->dot($a);
    my $norm_sq = $a->norm() ** 2;
    within_tolerance($self_dot, $norm_sq, 'self dot = norm^2');
};

subtest 'simple gradient descent simulation' => sub {
    # Minimize f(x) = sum(x^2) starting from x = [10, 10, 10]
    my $x = Numeric::Vector::new([10, 10, 10]);
    my $lr = 0.1;  # Learning rate

    for my $iter (1..50) {
        # Gradient of sum(x^2) is 2*x
        my $grad = $x->scale(2);

        # Update: x = x - lr * grad
        my $update = $grad->scale($lr);
        $x = $x->sub($update);
    }

    # Should converge near zero
    ok($x->norm() < 0.01, 'gradient descent converges near optimum');
};

subtest 'softmax-like operation' => sub {
    my $logits = Numeric::Vector::new([1, 2, 3]);

    # Softmax: exp(x) / sum(exp(x))
    my $exp_logits = $logits->exp();
    my $sum_exp = $exp_logits->sum();
    my $softmax = $exp_logits->scale(1.0 / $sum_exp);

    # Should sum to 1
    within_tolerance($softmax->sum(), 1, 'softmax sums to 1', 1e-6);

    # All values should be positive
    ok($softmax->min() > 0, 'softmax values are positive');

    # Larger inputs should have larger outputs
    ok($softmax->get(2) > $softmax->get(1), 'softmax preserves ordering');
    ok($softmax->get(1) > $softmax->get(0), 'softmax preserves ordering');
};

subtest 'ReLU activation' => sub {
    my $x = Numeric::Vector::new([-2, -1, 0, 1, 2]);

    # ReLU: max(0, x)
    my $zeros = Numeric::Vector::zeros($x->len());
    my $mask = $x->gt($zeros);  # 1 where x > 0
    my $relu = $x->mul($mask);

    my $expected = Numeric::Vector::new([0, 0, 0, 1, 2]);
    ok(vec_approx_eq($relu, $expected), 'ReLU activation works');
};

subtest 'sigmoid activation' => sub {
    my $x = Numeric::Vector::new([-5, -1, 0, 1, 5]);

    # Sigmoid: 1 / (1 + exp(-x))
    my $neg_x = $x->neg();
    my $exp_neg = $neg_x->exp();
    my $one_plus_exp = $exp_neg->add_scalar(1);

    # Build ones vector and divide
    my $ones = Numeric::Vector::ones($x->len());
    my $sigmoid = $ones->div($one_plus_exp);

    # sigmoid(0) = 0.5
    within_tolerance($sigmoid->get(2), 0.5, 'sigmoid(0) = 0.5');

    # sigmoid(large) ≈ 1
    ok($sigmoid->get(4) > 0.99, 'sigmoid(5) ≈ 1');

    # sigmoid(small) ≈ 0
    ok($sigmoid->get(0) < 0.01, 'sigmoid(-5) ≈ 0');
};

subtest 'batch normalization workflow' => sub {
    # Simulate batch of feature vectors
    my $batch = Numeric::Vector::new([2, 4, 6, 8, 10]);

    my $mean = $batch->mean();
    my $var = $batch->variance();
    my $eps = 1e-5;

    # Normalize: (x - mean) / sqrt(var + eps)
    my $centered = $batch->add_scalar(-$mean);
    my $normalized = $centered->scale(1.0 / sqrt($var + $eps));

    within_tolerance($normalized->mean(), 0, 'batch norm mean ≈ 0', 1e-6);
    within_tolerance($normalized->std(), 1, 'batch norm std ≈ 1', 0.1);
};

subtest 'linear layer simulation (axpy)' => sub {
    # y = W*x + b (simplified to vectors using axpy: y = a*x + y)
    my $x = Numeric::Vector::new([1, 2, 3, 4]);
    my $weights = 2.5;
    my $bias = Numeric::Vector::new([0.1, 0.2, 0.3, 0.4]);

    # Compute: output = weights * x + bias
    my $output = $bias->copy();
    $output->axpy($weights, $x);

    my $expected = Numeric::Vector::new([2.6, 5.2, 7.8, 10.4]);
    ok(vec_approx_eq($output, $expected), 'linear layer via axpy');
};

subtest 'fused multiply-add (FMA)' => sub {
    my $a = Numeric::Vector::new([1, 2, 3]);
    my $b = Numeric::Vector::new([4, 5, 6]);
    my $c = Numeric::Vector::new([0.1, 0.2, 0.3]);

    # c = a*b + c (in-place)
    $c->fma_inplace($a, $b);

    # c[i] = a[i]*b[i] + old_c[i]
    # [1*4+0.1, 2*5+0.2, 3*6+0.3] = [4.1, 10.2, 18.3]
    my $expected = Numeric::Vector::new([4.1, 10.2, 18.3]);
    ok(vec_approx_eq($c, $expected), 'FMA computes correctly');
};

subtest 'tanh activation (hyperbolic)' => sub {
    my $x = Numeric::Vector::new([-2, -1, 0, 1, 2]);
    my $tanh = $x->tanh();

    within_tolerance($tanh->get(2), 0, 'tanh(0) = 0');
    ok($tanh->get(0) < -0.9, 'tanh(-2) ≈ -1');
    ok($tanh->get(4) > 0.9, 'tanh(2) ≈ 1');

    # tanh is antisymmetric: tanh(-x) = -tanh(x)
    within_tolerance($tanh->get(0), -$tanh->get(4), 'tanh antisymmetry', 1e-6);
};

subtest 'one-hot encoding check' => sub {
    # Check argmax finds correct class
    my $probs = Numeric::Vector::new([0.1, 0.7, 0.2]);
    is($probs->argmax(), 1, 'argmax finds highest probability class');

    # Check multiple vectors
    my $probs2 = Numeric::Vector::new([0.9, 0.05, 0.05]);
    is($probs2->argmax(), 0, 'argmax for first-class dominant');
};

subtest 'L1 and L2 regularization terms' => sub {
    my $weights = Numeric::Vector::new([0.5, -1.5, 2.0, -0.5]);

    # L2 regularization: sum(w^2)
    my $l2 = $weights->mul($weights)->sum();
    within_tolerance($l2, 0.25 + 2.25 + 4.0 + 0.25, 'L2 regularization term');

    # L1 regularization: sum(|w|)
    my $l1 = $weights->abs()->sum();
    within_tolerance($l1, 0.5 + 1.5 + 2.0 + 0.5, 'L1 regularization term');
};

done_testing();
