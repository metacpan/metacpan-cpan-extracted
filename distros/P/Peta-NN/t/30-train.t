use v5.36;
use Test::More;
use lib 'lib';
use Peta::NN;
use Peta::NN::Backend;
use Peta::NN::Optimizer;

# Training on functions we can compute ourselves: the function is both the
# source of the data and the judge of the result. Run on every backend.

my @xor = ([ [ 0, 0 ], 0 ], [ [ 0, 1 ], 1 ], [ [ 1, 0 ], 1 ], [ [ 1, 1 ], 0 ]);
my @xor3 = map { [ [ @{ $_->[0] }, 1 ], $_->[1] ] } @xor;    # the same with a third, constant input

for my $backend (Peta::NN::Backend::available()) {
    my $engine = Peta::NN::Backend::create($backend);

    # --- the optimizers alone, on a bowl with its minimum at (3, -2) ---------
    for my $kind (qw(sgd adam)) {
        my %holder = (p => $engine->tensor([ 0, 0 ], 2));
        my $opt = Peta::NN::Optimizer->new(kind => $kind, lr => 0.05, backend => $engine, params => [ [ \%holder, 'p' ] ]);
        for (1 .. 600) {
            my ($x, $y) = @{ $engine->flat($holder{p}) };
            $holder{gp} = $engine->tensor([ 2 * ($x - 3), 2 * ($y + 2) ], 2);
            $opt->step;
        }
        my ($x, $y) = @{ $engine->flat($holder{p}) };
        cmp_ok(abs($x - 3) + abs($y + 2), '<', 1e-3, "$backend: $kind finds the minimum of a quadratic");
    }

    # --- XOR: not linearly separable, so the hidden layer has to do real work
    my $net = Peta::NN->new(input => 2, layers => [ [dense => 8], 'tanh', [dense => 2] ], seed => 1, backend => $backend);
    is($net->backend, $backend, "$backend: the net reports its backend");
    my $before = $net->loss(\@xor) / @xor;
    my $after  = $net->train(data => \@xor, epochs => 400, batch => 4, lr => 0.02);
    cmp_ok($after, '<', $before / 10, "$backend, XOR: the loss falls by more than a factor of ten");
    is($net->accuracy(\@xor), 1, "$backend, XOR: all four cases right");
    my $p = $net->predict([ 1, 0 ]);
    cmp_ok(abs($p->[0] + $p->[1] - 1), '<', 1e-12, "$backend: predict returns probabilities");
    cmp_ok($p->[1], '>', 0.9, "$backend: and is confident about 1 xor 0");
    is($net->classify([ 1, 1 ]), 0, "$backend: classify gives the class of one sample");

    # --- 5-bit parity, a function no single layer can represent --------------
    my @parity = map {
        my @bits = split //, sprintf '%05b', $_;
        my $ones = grep { $_ } @bits;
        [ \@bits, $ones % 2 ]
    } 0 .. 31;
    $net = Peta::NN->new(input => 5, layers => [ [dense => 24], 'tanh', [dense => 2] ], seed => 3, backend => $backend);
    $net->train(data => \@parity, epochs => 800, batch => 8, lr => 0.01, target_loss => 0.01);
    is($net->accuracy(\@parity), 1, "$backend, parity of five bits: all 32 patterns right");

    # --- regression: sin(x) on [-3, 3], judged between the training points ---
    my @sine = map { my $x = -3 + 6 * $_ / 60; [ [$x], [ sin $x ] ] } 0 .. 60;
    $net = Peta::NN->new(input => 1, layers => [ [dense => 16], 'tanh', [dense => 1] ], loss => 'mse', seed => 2, backend => $backend);
    $net->train(data => \@sine, epochs => 800, batch => 8, lr => 0.02, lr_decay => 0.995);
    my ($worst, $square) = (0, 0);
    for my $k (0 .. 59) {
        my $x     = -3 + 6 * ($k + 0.5) / 60;
        my $error = abs($net->predict([$x])->[0] - sin $x);
        $worst = $error if $error > $worst;
        $square += $error**2 / 60;
    }
    cmp_ok(sqrt $square, '<', 0.03, "$backend, sin(x): rms error below 0.03 between the training points");
    cmp_ok($worst, '<', 0.08, "$backend, sin(x): and nowhere off by more than 0.08");
}

# --- the training loop's controls --------------------------------------------
my @seen;
my $net = Peta::NN->new(input => 2, layers => [ [dense => 4], 'relu', [dense => 2] ], seed => 1);
$net->train(data => \@xor, epochs => 50, batch => 2, on_epoch => sub ($epoch, $loss) { push @seen, $epoch; $epoch < 3 });
is_deeply(\@seen, [ 1, 2, 3 ], 'on_epoch sees every epoch and can stop the run');

my @runs = map {
    my $n = Peta::NN->new(input => 2, layers => [ [dense => 4], 'tanh', [dense => 2] ], seed => 9, backend => 'plain');
    $n->train(data => \@xor, epochs => 20, batch => 2);
    join ',', map { @$_ } @{ $n->weights };
} 1 .. 2;
is($runs[0], $runs[1], 'plain: the same seed gives bit-identical weights');

# --- the backends agree -------------------------------------------------------
# Same seed, same data, same updates: the weights may differ by rounding only.
my %trained;
for my $backend (Peta::NN::Backend::available()) {
    my $n = Peta::NN->new(input => { tokens => 3, vocab => 6 }, layers => [ [embed => 4], [dense => 8], 'relu', [dense => 3] ],
                          seed => 7, backend => $backend);
    my @data = map { [ [ $_ % 6, ($_ * 5) % 6, ($_ * 7 + 1) % 6 ], $_ % 3 ] } 0 .. 39;
    $n->train(data => \@data, epochs => 5, batch => 8, lr => 0.01);
    $trained{$backend} = [ map { @$_ } @{ $n->weights } ];
}
for my $backend (grep { $_ ne 'plain' } sort keys %trained) {
    my $drift = 0;
    for my $i (0 .. $#{ $trained{plain} }) {
        my $d = abs($trained{$backend}[$i] - $trained{plain}[$i]);
        $drift = $d if $d > $drift;
    }
    # Double precision drifts by rounding only; single by about its last digits.
    my $allowed = $backend eq 'gpu' ? 1e-4 : 1e-9;
    cmp_ok($drift, '<', $allowed, "$backend: after 25 updates its weights are the plain backend's, within $allowed");
}

# --- sample weights, weight decay, validation --------------------------------
for my $backend (Peta::NN::Backend::available()) {
    my $slack = $backend eq 'gpu' ? 1e-5 : 1e-12;
    my %def = (input => 3, layers => [ [dense => 4], 'tanh', [dense => 2] ], seed => 6, backend => $backend);
    my @pairs = ([ [ 0.2, -0.4, 0.9 ], 1 ], [ [ -0.7, 0.1, 0.3 ], 0 ]);

    # A weight multiplies a sample's loss and its gradient.
    my $plain = Peta::NN->new(%def);
    $plain->backprop(\@pairs);
    my @once = map { @$_ } @{ $plain->gradients };
    my $heavy = Peta::NN->new(%def);
    my $loss  = $heavy->backprop([ map { [ @$_, 3 ] } @pairs ]);
    my @thrice = map { @$_ } @{ $heavy->gradients };
    ok(!(grep { abs($thrice[$_] - 3 * $once[$_]) > $slack } 0 .. $#once), "$backend: weight 3 triples the gradient");
    cmp_ok(abs($loss - 3 * $plain->loss(\@pairs)), '<', 1e-5, "$backend: and the loss");
    $heavy->backprop([ [ @{ $pairs[0] }, 0 ], $pairs[1] ]);
    $plain->backprop([ $pairs[1] ]);
    my @masked = map { @$_ } @{ $heavy->gradients };
    my @alone  = map { @$_ } @{ $plain->gradients };
    ok(!(grep { abs($masked[$_] - $alone[$_]) > $slack } 0 .. $#alone), "$backend: weight 0 removes a sample from the batch");

    # Weight decay pulls the weights towards zero; the biases are left alone.
    my @size = map {
        my $n = Peta::NN->new(%def);
        $n->train(data => \@xor3, epochs => 30, batch => 4, lr => 0.02, weight_decay => $_);
        my ($W) = @{ $n->weights };
        my $sum = 0;
        $sum += $_ * $_ for @$W;
        $sum
    } 0, 2;
    cmp_ok($size[1], '<', $size[0] / 2, "$backend: weight decay shrinks the weights");

    # With patience, training stops when the validation loss stops improving
    # and returns to its best epoch, not to the last.
    my @noisy = map { [ [ $_ / 20, ($_ * 7 % 20) / 20, ($_ * 3 % 20) / 20 ], ($_ * 11) % 2 ] } 0 .. 19;   # labels without a pattern
    my @held  = map { [ [ $_ / 23, ($_ * 5 % 23) / 23, ($_ * 2 % 23) / 23 ], ($_ * 13) % 2 ] } 0 .. 22;
    my $net   = Peta::NN->new(%def, layers => [ [dense => 32], 'tanh', [dense => 2] ]);
    $net->train(data => \@noisy, validate => \@held, epochs => 300, batch => 4, lr => 0.02, patience => 5);
    my @history = $net->history;
    cmp_ok(scalar @history, '<', 300, "$backend: patience stops a run that only memorises (" . @history . ' epochs)');
    my ($best) = sort { $a <=> $b } map { $_->{validation} } @history;
    cmp_ok(abs($net->loss(\@held) / @held - $best), '<', 1e-4, "$backend: the weights are those of the best validation epoch");
    cmp_ok($history[-1]{validation}, '>', $best, "$backend: which was not the last one");
}

# --- definitions that cannot work are refused -------------------------------
ok(!eval { Peta::NN->new(input => 2, layers => [ 'swish' ]); 1 }, 'unknown activation');
ok(!eval { Peta::NN->new(input => 2, layers => [ [conv => 3] ]); 1 }, 'unknown layer');
ok(!eval { Peta::NN->new(input => 2, layers => [ [embed => 3], [dense => 2] ]); 1 }, 'embedding without a token input');
ok(!eval { Peta::NN->new(input => { tokens => 2, vocab => 4 }, layers => [ [dense => 2] ]); 1 }, 'tokens without an embedding');
ok(!eval { Peta::NN->new(input => 2, layers => [ [dense => 2] ], loss => 'hinge'); 1 }, 'unknown loss');
ok(!eval { Peta::NN::Optimizer->new(kind => 'nope', backend => Peta::NN::Backend::create('plain'), params => []); 1 },
    'unknown optimizer');

done_testing;
