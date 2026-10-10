use v5.36;
use Test::More;
use lib 'lib';
use Peta::NN;
use Peta::NN::Backend;
use Peta::NN::RNG;

# The one test that proves backward() is the derivative of forward(): nudge a
# parameter, watch the loss, and compare the slope with the gradient the
# layers computed. Every layer type and both losses pass through here, on
# every backend this perl has, and with more than one sample in the batch.

my $STEP      = 1e-5;
my $TOLERANCE = 1e-6;

# A single-precision backend cannot resolve a loss change that small. Its
# gradients are held against the plain backend's instead, which the numeric
# check has vouched for, at the precision 32-bit floats allow.
my %SINGLE         = (gpu => 1);
my $SINGLE_TOLERANCE = 1e-5;

sub worst_difference ($net, $reference, $pairs) {
    $net->set_weights($reference->weights);
    $net->backprop($pairs);
    $reference->backprop($pairs);
    my @got  = map { @$_ } @{ $net->gradients };
    my @want = map { @$_ } @{ $reference->gradients };
    my $worst = 0;
    for my $i (0 .. $#want) {
        my $error = abs($got[$i] - $want[$i]) / (1 + abs($want[$i]));
        $worst = $error if $error > $worst;
    }
    return $worst;
}

sub worst_error ($net, $pairs) {
    $net->backprop($pairs);
    my $analytic = $net->gradients;
    my $weights  = $net->weights;
    my $worst    = 0;
    for my $p (0 .. $#$weights) {
        for my $i (0 .. $#{ $weights->[$p] }) {
            my $kept = $weights->[$p][$i];
            $weights->[$p][$i] = $kept + $STEP;
            my $up = $net->set_weights($weights)->loss($pairs);
            $weights->[$p][$i] = $kept - $STEP;
            my $down = $net->set_weights($weights)->loss($pairs);
            $weights->[$p][$i] = $kept;
            my $numeric = ($up - $down) / (2 * $STEP);
            my $error   = abs($numeric - $analytic->[$p][$i]) / (1 + abs($numeric) + abs($analytic->[$p][$i]));
            $worst = $error if $error > $worst;
        }
    }
    $net->set_weights($weights);
    return $worst;
}

my $rng = Peta::NN::RNG->new(11);
my @vec = map { [ map { $rng->normal } 1 .. 5 ] } 1 .. 3;

my @CASES = (
    [ 'dense, softmax',
      { input => 5, layers => [ [dense => 4] ], loss => 'softmax' },
      [ [ $vec[0], 2 ], [ $vec[1], 0 ], [ $vec[2], 3 ] ] ],
    [ 'dense, mse',
      { input => 5, layers => [ [dense => 3] ], loss => 'mse' },
      [ [ $vec[0], [ 0.3, -1, 2 ] ], [ $vec[1], [ 1, 1, 0 ] ] ] ],
    [ 'tanh between dense layers',
      { input => 5, layers => [ [dense => 6], 'tanh', [dense => 3] ], loss => 'softmax' },
      [ [ $vec[0], 0 ], [ $vec[1], 2 ] ] ],
    [ 'sigmoid output, mse',
      { input => 5, layers => [ [dense => 6], 'sigmoid', [dense => 2], 'sigmoid' ], loss => 'mse' },
      [ [ $vec[0], [ 1, 0 ] ], [ $vec[2], [ 0, 1 ] ] ] ],
    [ 'relu, three dense layers',
      { input => 5, layers => [ [dense => 7], 'relu', [dense => 6], 'relu', [dense => 4] ], loss => 'softmax' },
      [ [ $vec[0], 3 ], [ $vec[1], 1 ], [ $vec[2], 0 ] ] ],
    [ 'embedding into dense',
      { input => { tokens => 4, vocab => 9 }, layers => [ [embed => 3], [dense => 5], 'tanh', [dense => 4] ],
        loss => 'softmax' },
      [ [ [ 2, 0, 8, 2 ], 1 ], [ [ 5, 5, 1, 0 ], 3 ] ] ],
    [ 'embedding, one token used twice in a sample',
      { input => { tokens => 2, vocab => 3 }, layers => [ [embed => 2], [dense => 2] ], loss => 'softmax' },
      [ [ [ 1, 1 ], 0 ] ] ],
);

my @backends = Peta::NN::Backend::available();
ok(scalar(grep { $_ eq 'plain' } @backends), 'the plain backend is always available');
note "backends in this perl: @backends";

for my $backend (@backends) {
    for my $case (@CASES) {
        my ($name, $def, $pairs) = @$case;
        my $net = Peta::NN->new(%$def, seed => 5, backend => $backend);
        if ($SINGLE{$backend}) {
            my $reference = Peta::NN->new(%$def, seed => 5, backend => 'plain');
            cmp_ok(worst_difference($net, $reference, $pairs), '<', $SINGLE_TOLERANCE,
                "$backend, $name: gradient matches the plain backend's to single precision");
            next;
        }
        cmp_ok(worst_error($net, $pairs), '<', $TOLERANCE, "$backend, $name: analytic gradient matches the numeric one");
    }

    # A batch's gradient is the sum of its samples' gradients.
    my ($name, $def, $pairs) = @{ $CASES[4] };
    my $net = Peta::NN->new(%$def, seed => 5, backend => $backend);
    $net->backprop($pairs);
    my @batch = map { @$_ } @{ $net->gradients };
    my @sum   = (0) x @batch;
    for my $pair (@$pairs) {
        $net->backprop([$pair]);
        my @one = map { @$_ } @{ $net->gradients };
        $sum[$_] += $one[$_] for 0 .. $#one;
    }
    my $slack = $SINGLE{$backend} ? $SINGLE_TOLERANCE : 1e-12;
    ok(!(grep { abs($batch[$_] - $sum[$_]) > $slack } 0 .. $#batch), "$backend: a batch's gradient is the sum over its samples");
}

ok(!eval { Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'abacus'); 1 }, 'an unknown backend is refused');

done_testing;
