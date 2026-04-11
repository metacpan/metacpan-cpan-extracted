#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use lib 't/lib';

use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

my $PI = 3.14159265358979323846;

# ============================================
# Signal Processing Integration Tests
# ============================================

subtest 'sine wave generation' => sub {
    my $n = 100;
    my $freq = 2;  # 2 cycles

    # Generate time points: 0 to 2*pi
    my $t = Numeric::Vector::linspace(0, 2 * $PI, $n);

    # Generate sine wave: sin(freq * t)
    my $sine = $t->scale($freq)->sin();

    is($sine->len(), $n, 'sine wave has correct length');

    # First and last should be near 0 (sin(0) = sin(4*pi) ≈ 0)
    within_tolerance($sine->get(0), 0, 'sin(0) = 0', 1e-6);

    # Quarter period should be near 1 (sin(pi/2) = 1)
    my $quarter_idx = int($n / 4 / $freq);
    within_tolerance($sine->get($quarter_idx), 1, 'sin(pi/2) ≈ 1', 0.1);
};

subtest 'cosine wave generation' => sub {
    my $n = 100;
    my $t = Numeric::Vector::linspace(0, 2 * $PI, $n);
    my $cosine = $t->cos();

    # cos(0) = 1
    within_tolerance($cosine->get(0), 1, 'cos(0) = 1', 1e-6);

    # cos(pi) = -1
    my $half_idx = int($n / 2);
    within_tolerance($cosine->get($half_idx), -1, 'cos(pi) ≈ -1', 0.1);
};

subtest 'signal mixing (addition)' => sub {
    my $n = 100;
    my $t = Numeric::Vector::linspace(0, 2 * $PI, $n);

    my $signal1 = $t->sin();
    my $signal2 = $t->scale(2)->sin();  # double frequency

    # Mix signals
    my $mixed = $signal1->add($signal2);

    is($mixed->len(), $n, 'mixed signal has correct length');

    # Verify superposition: mixed[i] = sin(t[i]) + sin(2*t[i])
    my $i = 25;
    my $ti = $t->get($i);
    my $expected = sin($ti) + sin(2 * $ti);
    within_tolerance($mixed->get($i), $expected, 'superposition works', 1e-6);
};

subtest 'amplitude modulation' => sub {
    my $n = 100;
    my $t = Numeric::Vector::linspace(0, 4 * $PI, $n);

    my $carrier = $t->scale(10)->sin();      # High frequency carrier
    my $modulator = $t->sin()->scale(0.5)->add_scalar(1);  # 1 + 0.5*sin(t)

    # AM signal = carrier * modulator
    my $am = $carrier->mul($modulator);

    is($am->len(), $n, 'AM signal has correct length');

    # Verify AM at specific point
    my $i = 30;
    my $ti = $t->get($i);
    my $expected = sin(10 * $ti) * (1 + 0.5 * sin($ti));
    within_tolerance($am->get($i), $expected, 'AM modulation correct', 1e-6);
};

subtest 'simple moving average' => sub {
    # Create noisy signal
    my $signal = Numeric::Vector::new([1, 3, 2, 4, 3, 5, 4, 6, 5, 7]);

    # Manual 3-point moving average for middle points
    # ma[i] = (signal[i-1] + signal[i] + signal[i+1]) / 3
    my $arr = $signal->to_array();
    my @ma;
    for my $i (1 .. $#$arr - 1) {
        push @ma, ($arr->[$i-1] + $arr->[$i] + $arr->[$i+1]) / 3;
    }

    # Verify using slice and mean
    for my $i (0 .. $#ma) {
        my $window = $signal->slice($i, 3);
        within_tolerance($window->mean(), $ma[$i], "moving average at pos $i");
    }
};

subtest 'signal energy' => sub {
    my $n = 1000;
    my $t = Numeric::Vector::linspace(0, 2 * $PI, $n);
    my $signal = $t->sin();

    # Energy = sum(x^2)
    my $squared = $signal->mul($signal);
    my $energy = $squared->sum();

    # Energy of sin^2 over one period: integral = pi
    # Discrete approximation: sum ≈ n/2
    ok($energy > $n * 0.4 && $energy < $n * 0.6, 'signal energy in expected range');
};

subtest 'signal power (RMS)' => sub {
    # RMS of sine wave = 1/sqrt(2) ≈ 0.7071
    my $n = 10000;
    my $t = Numeric::Vector::linspace(0, 10 * $PI, $n);  # Multiple periods
    my $signal = $t->sin();

    # RMS = sqrt(mean(x^2))
    my $squared = $signal->mul($signal);
    my $rms = sqrt($squared->mean());

    within_tolerance($rms, 1/sqrt(2), 'RMS of sine ≈ 0.7071', 0.01);
};

subtest 'clipping distortion' => sub {
    my $signal = Numeric::Vector::new([-2, -1, -0.5, 0, 0.5, 1, 2]);

    # Clip to [-1, 1]
    my $clipped = $signal->clip(-1, 1);

    my $expected = Numeric::Vector::new([-1, -1, -0.5, 0, 0.5, 1, 1]);
    ok(vec_approx_eq($clipped, $expected), 'clipping works correctly');
};

subtest 'DC offset removal' => sub {
    # Signal with DC offset
    my $signal = Numeric::Vector::new([5, 6, 4, 7, 5, 6, 4]);

    my $dc = $signal->mean();
    my $ac = $signal->add_scalar(-$dc);

    within_tolerance($ac->mean(), 0, 'AC component has zero mean', 1e-10);
};

subtest 'exponential decay' => sub {
    my $n = 100;
    my $t = Numeric::Vector::linspace(0, 5, $n);

    # Exponential decay: e^(-t)
    my $decay = $t->neg()->exp();

    within_tolerance($decay->get(0), 1, 'exp(0) = 1');
    ok($decay->get($n-1) < 0.01, 'exp(-5) is small');

    # Verify monotonic decrease
    my $diff = $decay->diff();
    my $all_negative = $diff->lt(Numeric::Vector::zeros($diff->len()));
    is($all_negative->sum(), $diff->len(), 'decay is monotonically decreasing');
};

subtest 'signal concatenation' => sub {
    my $part1 = Numeric::Vector::new([1, 2, 3]);
    my $part2 = Numeric::Vector::new([4, 5, 6]);

    my $full = $part1->concat($part2);

    is($full->len(), 6, 'concatenated length is sum');

    my $expected = Numeric::Vector::new([1, 2, 3, 4, 5, 6]);
    ok(vec_approx_eq($full, $expected), 'concatenation preserves values');
};

subtest 'signal reversal' => sub {
    my $signal = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $reversed = $signal->reverse();

    my $expected = Numeric::Vector::new([5, 4, 3, 2, 1]);
    ok(vec_approx_eq($reversed, $expected), 'reversal works');

    # Double reversal = original
    my $double_rev = $reversed->reverse();
    ok(vec_approx_eq($double_rev, $signal), 'double reversal = original');
};

done_testing();
