package Peta::NN;
# ABSTRACT: a small neural network, defined, trained and saved in Perl

# A small feed-forward neural network: a list of layers, a loss, and a
# training loop. A mini-batch goes through as one tensor; what a tensor is,
# and how the arithmetic on it is done, is the backend's business.

use v5.36;

use Storable ();
use Time::HiRes qw(time);

use Peta::NN::RNG;
use Peta::NN::Backend;
use Peta::NN::Inference;
use Peta::NN::Optimizer;
use Peta::NN::Layer::Dense;
use Peta::NN::Layer::Embed;
use Peta::NN::Layer::Activation;

our $VERSION = '0.2610090';

my %IS_ACTIVATION = map { $_ => 1 } Peta::NN::Layer::Activation::kinds();
my %IS_LOSS       = map { $_ => 1 } qw(softmax mse);

my $EVAL_BATCH = 256;    # samples per forward pass when only predicting

# Whether train() leaves the samples with a backend that can keep them. On
# unless a test wants the two ways compared.
our $EPOCH_ON_BACKEND = 1;

# A network that was left the choice of its backend ('auto') settles it when
# it is trained: only then is it known how much work there is. If the run
# would take the backend it stands on $WORTH seconds or more, a few steps
# are timed on every backend this perl and this machine have, and the run
# goes to the fastest. Nothing is assumed about which that is: plain Perl
# under a JIT, PDL and a graphics card each win somewhere, and each may be
# missing. $TRIAL_WARM steps are run before the $TRIAL_STEPS that are timed.
our $WORTH       = 2;
our $TRIAL_STEPS = 6;       # steps in a timed round
our $TRIAL_WARM  = 2;
my  @TRIAL_TIME  = (0.3, 1); # seconds of timed rounds, at least and at most; the fastest round counts. The
                           # first steps of anything are slow, and a card that sat idle takes a few tenths
                           # of a second to come up to speed
my  $SETTLED     = 0.05;    # two rounds in a row that do not beat the best by this share: it is found
my  $PROBE       = 16;      # samples in the one small step that is tried first
my  $HOPELESS    = 3;       # a backend this many times slower than the best so far is not timed to the end

my $STATE_FORMAT = 'Peta::NN network state';

# A layer is written [dense => N], [embed => DIM], or an activation's name.
sub _build_layer ($spec) {
    if (!ref $spec) {
        die "unknown layer '$spec'\n" if !$IS_ACTIVATION{$spec};
        return Peta::NN::Layer::Activation->new(kind => $spec);
    }
    my ($kind, $size) = @$spec;
    return Peta::NN::Layer::Dense->new(out => $size) if $kind eq 'dense';
    return Peta::NN::Layer::Embed->new(dim => $size) if $kind eq 'embed';
    die "unknown layer '$kind'\n";
}

sub new ($class, %arg) {
    my $self = bless {
        input => $arg{input} // die("input => size, or { tokens =>, vocab => }, is required\n"),
        loss  => $arg{loss}  // 'softmax',
        seed  => $arg{seed}  // 1,
    }, $class;
    die "unknown loss '$self->{loss}' (have: @{[ sort keys %IS_LOSS ]})\n" if !$IS_LOSS{ $self->{loss} };
    my $backend = $arg{backend} // $ENV{PETA_NN_BACKEND} // 'plain';
    $self->{auto}    = $backend eq 'auto';
    $self->{backend} = Peta::NN::Backend::create($backend);
    $self->{rng}     = Peta::NN::RNG->new($self->{seed});
    $self->{generation} = 0;
    $self->{layers}  = [ map { _build_layer($_) } @{ $arg{layers} // die "layers => [...] is required\n" } ];

    my $size = $self->{input};
    $size = $_->init($size, $self->{rng}, $self->{backend}) for @{ $self->{layers} };
    die "the network needs at least one layer\n" if ref $size;
    $self->{n_out} = $size;

    # Nothing consumes the first layer's input gradient.
    my $first = $self->{layers}[0];
    $first->{need_dx} = 0 if $first->type eq 'dense';
    return $self;
}

sub n_out   ($self) { return $self->{n_out} }

# A number that changes whenever the weights do, for whoever caches something
# derived from them.
sub generation ($self) { return $self->{generation} }
sub layers  ($self) { return @{ $self->{layers} } }
sub backend ($self) { return $self->{backend}->name }

# How the backend was settled by the last train(), for a network that was
# left the choice: { backend, steps, seconds_per_step => { backend => seconds } },
# the timings being those that were taken. Nothing for any other network, or
# for a run of too few steps to time.
sub settled ($self) { return $self->{settled} }

# Every parameter as [layer, name], in layer order: the tensor is
# $layer->{name}, its gradient after backprop() is $layer->{"g$name"}.
sub params ($self) {
    return map { my $layer = $_; map { [ $layer, $_ ] } $layer->param_names } @{ $self->{layers} };
}

# The parameters, and their gradients, as flat Perl lists in params() order.
sub weights ($self) {
    return [ map { $self->{backend}->flat($_->[0]{ $_->[1] }) } $self->params ];
}

sub gradients ($self) {
    return [ map { $self->{backend}->flat($_->[0]{"g$_->[1]"}) } $self->params ];
}

sub set_weights ($self, $lists) {
    my @params = $self->params;
    die "these weights do not fit this network\n" if @params != @$lists;
    for my $p (0 .. $#params) {
        my ($layer, $name) = @{ $params[$p] };
        die "these weights do not fit this network\n"
            if @{ $lists->[$p] } != @{ $self->{backend}->flat($layer->{$name}) };
        $layer->{$name} = $self->{backend}->tensor($lists->[$p], $layer->param_cols($name));
    }
    $self->{generation}++;
    return $self;
}

sub n_params ($self) {
    my $n = 0;
    $n += @$_ for @{ $self->weights };
    return $n;
}

# A list of samples as the backend's batch: rows of numbers, or of tokens.
sub _batch ($self, $inputs) {
    my $input = $self->{input};
    return ref $input
        ? $self->{backend}->tokens([ map { @$_ } @$inputs ], $input->{tokens})
        : $self->{backend}->tensor([ map { @$_ } @$inputs ], $input);
}

sub _forward ($self, $inputs) {
    my $x = $self->_batch($inputs);
    $x = $_->forward($x) for @{ $self->{layers} };
    return $x;
}

# The loss of a batch of [input, target] or [input, target, weight] pairs,
# given the network's output for them. A weight multiplies that sample's loss
# and gradient; if no pair has one, none is passed on.
sub _loss ($self, $out, $pairs) {
    my @targets = map { $_->[1] } @$pairs;
    my $weights = (grep { defined $_->[2] } @$pairs) ? [ map { $_->[2] // 1 } @$pairs ] : undef;
    return $self->{loss} eq 'softmax'
        ? $self->{backend}->softmax_ce($out, \@targets, $weights)
        : $self->{backend}->mse($out, [ map { @$_ } @targets ], $weights);
}

# The raw output for one sample: logits under the softmax loss.
sub forward ($self, $x) {
    return $self->{backend}->flat($self->_forward([$x]));
}

# What a caller wants to see: class probabilities under the softmax loss,
# the output itself otherwise.
sub predict ($self, $x) {
    my $out = $self->forward($x);
    return $out if $self->{loss} ne 'softmax';
    my $max = $out->[0];
    for my $v (@$out) { $max = $v if $v > $max }
    my @p   = map { exp($_ - $max) } @$out;
    my $sum = 0;
    $sum += $_ for @p;
    return [ map { $_ / $sum } @p ];
}

# The most probable class of each of many samples.
sub classify_all ($self, $inputs) {
    my @classes;
    for (my $start = 0; $start < @$inputs; $start += $EVAL_BATCH) {
        my $end = $start + $EVAL_BATCH - 1;
        $end = $#$inputs if $end > $#$inputs;
        my $out = $self->_forward([ @$inputs[ $start .. $end ] ]);
        push @classes, @{ $self->{backend}->argmax_rows($out, $self->{n_out}) };
    }
    return \@classes;
}

sub classify ($self, $x) { return $self->classify_all([$x])->[0] }

# The summed loss of [input, target] pairs, without touching the gradients.
sub loss ($self, $pairs) {
    my $total = 0;
    for (my $start = 0; $start < @$pairs; $start += $EVAL_BATCH) {
        my $end = $start + $EVAL_BATCH - 1;
        $end = $#$pairs if $end > $#$pairs;
        my @chunk = @$pairs[ $start .. $end ];
        my ($loss) = $self->_loss($self->_forward([ map { $_->[0] } @chunk ]), \@chunk);
        $total += $loss;
    }
    return $total;
}

# Forward and backward for a batch of [input, target] pairs: leaves the
# batch's summed gradient with the layers and returns its summed loss.
sub backprop ($self, $pairs) {
    my $out = $self->_forward([ map { $_->[0] } @$pairs ]);
    my ($loss, $grad) = $self->_loss($out, $pairs);
    for my $layer (reverse @{ $self->{layers} }) {
        $grad = $layer->backward($grad);
    }
    return $loss;
}

# The samples of a training run, left with a backend that can keep them: then
# a step picks its batch where the arithmetic is, and nothing is carried
# there and back for it (on a graphics card that carrying is what costs).
# Nothing if the backend does not keep samples, or not such as these.
sub _kept ($self, $data) {
    my $backend = $self->{backend};
    return if !$EPOCH_ON_BACKEND || !ref $self->{input} || $self->{loss} ne 'softmax' || !$backend->can('epoch_data');
    return $backend->epoch_data([ map { @{ $_->[0] } } @$data ], $self->{input}{tokens}, [ map { $_->[1] } @$data ],
                                (grep { defined $_->[2] } @$data) ? [ map { $_->[2] // 1 } @$data ] : undef);
}

# One training step on the samples $order->[$start .. $end]: forward,
# backward, update. Returns the batch's loss, or nothing where the samples
# are kept by the backend and their losses with them.
sub _step ($self, $optimizer, $kept, $data, $order, $start, $end) {
    my $loss = 0;
    if ($kept) {
        my $backend = $self->{backend};
        my $x = $backend->batch_at($kept, $start, $end - $start + 1);
        $x = $_->forward($x) for @{ $self->{layers} };
        my $grad = $backend->softmax_ce_at($x, $kept, $start);
        $grad = $_->backward($grad) for reverse @{ $self->{layers} };
    }
    else { $loss = $self->backprop([ @$data[ @$order[ $start .. $end ] ] ]) }
    $optimizer->step(1 / ($end - $start + 1));
    $self->{generation}++;
    return $loss;
}

# The network on another backend, with these weights.
sub _move_to ($self, $backend, $weights) {
    $self->{backend} = $backend;
    $_->{backend} = $backend for @{ $self->{layers} };
    my @params = $self->params;
    for my $p (0 .. $#params) {
        my ($layer, $name) = @{ $params[$p] };
        $layer->{$name} = $backend->tensor($weights->[$p], $layer->param_cols($name));
    }
    $self->{generation}++;
    return;
}

# Seconds a training step takes on the backend the network is on now, timed
# on the first samples: the fastest of a few rounds of steps. The weights are
# afterwards what they were. With $beat, a time per step to beat, it gives
# up once it is hopeless, and tries one step on a handful of samples before
# anything else: a step on the whole batch cannot be faster than that.
sub _seconds_per_step ($self, $data, $batch, $weights, $beat = undef) {
    my $backend = $self->{backend};
    my $last    = $batch * ($TRIAL_WARM + $TRIAL_STEPS) - 1;
    $last = $#$data if $last > $#$data;
    my @sample    = @$data[ 0 .. $last ];
    my @order     = 0 .. $last;
    my $optimizer = Peta::NN::Optimizer->new(kind => 'adam', backend => $backend, params => [ $self->params ]);
    # Reading a bias back waits for whatever a card has been sent.
    my $wait = sub { $backend->flat(($self->params)[-1][0]{ ($self->params)[-1][1] }) };
    my $best;
    if (defined $beat && $batch > $PROBE) {
        $self->backprop([ @sample[ 0 .. $PROBE - 1 ] ]);         # the first step of all sets things up
        my $began = time;
        $self->backprop([ @sample[ 0 .. $PROBE - 1 ] ]);
        $wait->();
        $best = 9**9**9 if time - $began > $HOPELESS * $beat;
    }
    if (!defined $best) {
        my $kept = $self->_kept(\@sample);
        $backend->epoch_order($kept, \@order) if $kept;
        my $steps = sub ($from, $count) {
            $self->_step($optimizer, $kept, \@sample, \@order, $_ * $batch, ($_ + 1) * $batch - 1) for $from .. $from + $count - 1;
        };
        $steps->(0, $TRIAL_WARM);
        my ($stale, $since) = (0, time);
        while (1) {                 # the same samples round after round: it is the time that is wanted
            $wait->();
            my $began = time;
            $steps->($TRIAL_WARM, $TRIAL_STEPS);
            $wait->();
            my $round = (time - $began) / $TRIAL_STEPS;
            $stale = defined $best && $round > $best * (1 - $SETTLED) ? $stale + 1 : 0;
            $best  = $round if !defined $best || $round < $best;
            my $spent = time - $since;
            last if $spent >= $TRIAL_TIME[1] || $stale >= 2 && $spent >= $TRIAL_TIME[0] || defined $beat && $best > $HOPELESS * $beat;
        }
    }
    $self->_move_to($backend, $weights);
    return $best;
}

# Settle the backend of a network that was left the choice, for a run of
# this many samples, at this batch, for this many epochs.
sub _settle ($self, $data, $batch, $epochs) {
    # The same work as the last time it was settled: the same answer.
    my $steps = $epochs * (int($#$data / $batch) + 1);
    my $work  = join ' ', scalar @$data, $batch, $steps;
    return if $self->{settled} && $self->{settled}{work} eq $work;
    delete $self->{settled};
    return if @$data < $batch * ($TRIAL_WARM + $TRIAL_STEPS);       # too few steps to time a round
    my $weights = $self->weights;
    my $count   = $self->{generation};
    my $here    = $self->{backend};
    my %seconds = ($here->name => $self->_seconds_per_step($data, $batch, $weights));
    my ($best, $on) = ($seconds{ $here->name }, $here);
    if ($best * $steps >= $WORTH) {
        for my $name (grep { $_ ne $here->name } Peta::NN::Backend::names()) {
            my $other = Peta::NN::Backend::try($name) or next;
            $self->_move_to($other, $weights);
            $seconds{$name} = $self->_seconds_per_step($data, $batch, $weights, $best);
            ($best, $on) = ($seconds{$name}, $other) if $seconds{$name} < $best;
        }
        # A close second is timed once more: the first time anything runs it is
        # not at its best (a JIT has not compiled it yet, a card is not up to
        # speed), and by how much differs from backend to backend.
        my %backend = ($here->name => $here);
        for my $name (grep { $seconds{$_} <= $HOPELESS * $best } sort keys %seconds) {
            $backend{$name} //= Peta::NN::Backend::try($name);
            $self->_move_to($backend{$name}, $weights);
            my $again = $self->_seconds_per_step($data, $batch, $weights);
            $seconds{$name} = $again if $again < $seconds{$name};
        }
        my ($fastest) = sort { $seconds{$a} <=> $seconds{$b} } keys %seconds;
        ($best, $on) = ($seconds{$fastest}, $backend{$fastest} // Peta::NN::Backend::try($fastest));
    }
    $self->_move_to($on, $weights);
    $self->{generation} = $count;      # nothing has changed: the weights are what they were
    delete @seconds{ grep { $seconds{$_} == 9**9**9 } keys %seconds };      # those that were not worth timing
    $self->{settled}    = { backend => $on->name, steps => $steps, seconds_per_step => \%seconds, work => $work };
    return;
}

# Train on [input, target] or [input, target, weight] pairs. Returns the mean
# loss of the last epoch.
#   epochs, batch         how long, and how many samples per update
#   optimizer, lr, ...    passed to Peta::NN::Optimizer, weight_decay included
#   lr_decay              the learning rate is multiplied by this after every epoch
#   validate              pairs that are not trained on; their loss is measured every epoch
#   patience              stop after this many epochs without improvement of the
#                         validation loss (the training loss if there is no
#                         validation set), and return to the best epoch's weights
#   min_delta             what counts as an improvement; default any
#   watch                 sub (training loss, validation loss) returning the number
#                         patience watches instead; lower is better
#   target_loss           stop once an epoch's mean loss is at or below this
#   on_epoch              called with (epoch, mean loss); a false return stops.
#                         history() has the validation loss as well
sub train ($self, %arg) {
    my $data   = $arg{data} // die "data => [[input, target], ...] is required\n";
    my $epochs = $arg{epochs} // 10;
    my $batch  = $arg{batch}  // 16;
    $self->_settle($data, $batch, $epochs) if $self->{auto};
    my $optimizer = Peta::NN::Optimizer->new(
        kind    => $arg{optimizer} // 'adam',
        backend => $self->{backend},
        params  => [ $self->params ],
        map { $_ => $arg{$_} } grep { defined $arg{$_} } qw(lr momentum beta1 beta2 epsilon weight_decay),
    );

    my $validate  = $arg{validate};
    my $patience  = $arg{patience};
    my $min_delta = $arg{min_delta} // 0;
    my ($best, $best_weights, $stale) = (undef, undef, 0);

    my $backend = $self->{backend};
    my $kept    = $self->_kept($data);

    my @order = 0 .. $#$data;
    my $mean  = 0;
    $self->{history} = [];
    for my $epoch (1 .. $epochs) {
        $self->{rng}->shuffle(\@order);
        my $total = 0;
        $backend->epoch_order($kept, \@order) if $kept;
        for (my $start = 0; $start < @order; $start += $batch) {
            my $end = $start + $batch - 1;
            $end = $#order if $end > $#order;
            $total += $self->_step($optimizer, $kept, $data, \@order, $start, $end);
        }
        $total = $backend->epoch_loss($kept) if $kept;
        $mean = $total / @order;
        my $held = $validate && @$validate ? $self->loss($validate) / @$validate : undef;
        push @{ $self->{history} }, { epoch => $epoch, loss => $mean, validation => $held };

        # The loss that is watched: the validation set's if there is one. The
        # weights of its best epoch are kept and put back at the end.
        if (defined $patience) {
            my $watched = $arg{watch} ? $arg{watch}->($mean, $held) : $held // $mean;
            if (!defined $best || $watched < $best - $min_delta) {
                ($best, $best_weights, $stale) = ($watched, $self->weights, 0);
            }
            elsif (++$stale >= $patience) { last }
        }
        last if $arg{on_epoch} && !$arg{on_epoch}->($epoch, $mean);
        last if defined $arg{target_loss} && $mean <= $arg{target_loss};
        $optimizer->{lr} *= $arg{lr_decay} if defined $arg{lr_decay};
    }
    $self->set_weights($best_weights) if $best_weights;
    return $mean;
}

# What every epoch of the last train() measured: { epoch, loss, validation }.
sub history ($self) { return @{ $self->{history} // [] } }

# Share of [input, class index] pairs classified correctly.
sub accuracy ($self, $pairs) {
    my $classes = $self->classify_all([ map { $_->[0] } @$pairs ]);
    my $right   = grep { $classes->[$_] == $pairs->[$_][1] } 0 .. $#$pairs;
    return $right / @$pairs;
}

# What it takes to rebuild this net: its definition and its weights. The
# backend is not part of it; a net trained on one loads on any other.
sub state ($self) {
    return {
        version => $VERSION,
        input   => $self->{input},
        loss    => $self->{loss},
        seed    => $self->{seed},
        layers  => [ map { $_->spec } @{ $self->{layers} } ],
        weights => $self->weights,
    };
}

sub from_state ($class, $state, %arg) {
    return $class->new(%$state{qw(input loss seed layers)}, %arg)->set_weights($state->{weights});
}

# Storable's portable format writes a double as decimal text and loses its
# last bits. Packed little-endian it stays exact, and portable all the same.
sub freeze_state ($state) {
    return { %$state, weights => [ map { pack 'd<*', @$_ } @{ $state->{weights} } ] };
}

sub thaw_state ($frozen) {
    return { %$frozen, weights => [ map { [ unpack 'd<*', $_ ] } @{ $frozen->{weights} } ] };
}

# A network's state file, by convention *.net.
sub save ($self, $file) {
    Storable::nstore({ %{ freeze_state($self->state) }, format => $STATE_FORMAT }, $file);
    return $self;
}

# The file is read as plain data, and weights that do not fit the definition
# in it are refused.
sub load ($class, $file, %arg) {
    my $frozen = Peta::NN::Inference::read_file($file, $STATE_FORMAT);
    die "$file is a malformed network state\n"
        if ref $frozen->{layers} ne 'ARRAY' || ref $frozen->{weights} ne 'ARRAY' || grep { ref } @{ $frozen->{weights} };
    return $class->from_state(thaw_state($frozen), %arg);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN - a small neural network, defined, trained and saved in Perl

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN;

    my $net = Peta::NN->new(
        input   => 2,
        layers  => [ [dense => 8], 'tanh', [dense => 2] ],
        loss    => 'softmax',
        seed    => 1,
        backend => 'plain',                  # or 'pdl', 'gpu'; 'auto' leaves it to the network
    );
    $net->train(data => [ [[0, 0], 0], [[0, 1], 1], [[1, 0], 1], [[1, 1], 0] ],
                epochs => 300, batch => 4);
    print $net->classify([1, 0]);            # 1
    $net->save('xor.nn');

=head1 DESCRIPTION

C<input> is the number of inputs, or C<{ tokens =E<gt> $count, vocab =E<gt>
$size }> when the first layer is an embedding. C<layers> lists
C<[dense =E<gt> $n]>, C<[embed =E<gt> $dim]> and the activations C<'relu'>,
C<'tanh'>, C<'sigmoid'>. C<loss> is C<'softmax'> (the target is a class
index) or C<'mse'> (the target is a vector).

C<backend> chooses where the arithmetic runs, see L<Peta::NN::Backend>.
On the plain backend training is deterministic to the bit: the same C<seed>
gives the same weights on any perl. Other backends agree with it to
rounding.

A saved network carries no backend: C<< Peta::NN->load($file, backend =>
'pdl') >> loads on whichever is wanted.

For networks that read and write strings see L<Peta::NN::Model>.

=head1 METHODS

=head2 new

    my $net = Peta::NN->new(input => ..., layers => [...], loss => 'softmax', seed => 1, backend => 'plain');

C<input> and C<layers> are required. C<loss> is C<softmax> (default) or
C<mse>, C<seed> defaults to 1, C<backend> to C<$ENV{PETA_NN_BACKEND}> or
C<plain>.

=head2 train

    my $loss = $net->train(data => \@pairs, epochs => 10, batch => 16, lr => 0.01);

Trains on C<[input, target]> or C<[input, target, weight]> pairs and returns
the mean loss of the last epoch. Further arguments: C<optimizer> (C<adam>,
the default, or C<sgd>) with C<lr>, C<momentum>, C<beta1>, C<beta2>,
C<epsilon>, C<weight_decay>; C<lr_decay>, by which the learning rate is
multiplied after every epoch; C<validate>, pairs that are not trained on and
whose loss is measured every epoch; C<patience>, the number of epochs without
improvement after which training stops and returns to the best epoch's
weights; C<min_delta>, what counts as an improvement; C<watch>, a sub given
(training loss, validation loss) that returns the number C<patience> watches
instead; C<target_loss>, at or below which training stops; C<on_epoch>, a sub
called with (epoch, mean loss) whose false return stops training.

A network made with C<< backend => 'auto' >> settles its backend here, where
the work is known: it times a few steps on the backend it is on, and if the
run would take C<$Peta::NN::WORTH> seconds (2) or more, on every other
backend this perl and this machine have, and trains on the fastest. The
weights are afterwards what they were. A backend that is not there is not
considered, and none is assumed to be faster than another. Since the
graphics card computes in single precision, where such a run goes decides
its result beyond the sixth digit; name the backend to pin it.

=head2 history

What every epoch of the last C<train> measured: a list of
C<< { epoch, loss, validation } >>.

=head2 forward

The raw output for one sample: logits under the softmax loss.

=head2 predict

Class probabilities for one sample under the softmax loss, the output itself
otherwise.

=head2 classify

The most probable class of one sample.

=head2 classify_all

The most probable class of each of many samples, as an array reference.

=head2 accuracy

The share of C<[input, class index]> pairs classified correctly.

=head2 loss

The summed loss of C<[input, target]> pairs, without touching the gradients.

=head2 backprop

Forward and backward for a batch of pairs: leaves the batch's summed gradient
with the layers and returns its summed loss.

=head2 params

Every parameter as C<[layer, name]>, in layer order. The tensor is
C<< $layer->{name} >>, its gradient after C<backprop> is
C<< $layer->{"g$name"} >>.

=head2 weights

The parameters as flat Perl lists, in C<params> order.

=head2 gradients

The gradients as flat Perl lists, in C<params> order.

=head2 set_weights

Replaces the parameters by the given lists, which must fit the network.

=head2 n_params

The number of weights.

=head2 n_out

The number of outputs.

=head2 layers

The layer objects, in order.

=head2 backend

The name of the backend the network computes on.

=head2 settled

For a network that was left the choice of its backend, how the last C<train>
settled it: C<< { backend, steps, seconds_per_step => { name => seconds } } >>,
the timings being those that were taken. Nothing for a network whose backend
was named, or for a run of too few steps to time.

=head2 generation

A number that changes whenever the weights do, for whoever caches something
derived from them.

=head2 state

What it takes to rebuild the network: its definition and its weights. The
backend is not part of it.

=head2 from_state

    my $net = Peta::NN->from_state($state, backend => 'pdl');

The network a state describes. Weights that do not fit the definition are
refused.

=head2 freeze_state

A state with its weights packed as little-endian doubles, which Storable's
portable format keeps exact.

=head2 thaw_state

The reverse of C<freeze_state>.

=head2 save

Writes the network's state to a file, by convention C<*.net>.

=head2 load

    my $net = Peta::NN->load($file, backend => 'pdl');

Reads a state file as plain data and rebuilds the network.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
