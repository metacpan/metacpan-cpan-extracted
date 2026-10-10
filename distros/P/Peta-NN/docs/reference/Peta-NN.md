# Peta::NN

a small neural network, defined, trained and saved in Perl

## Synopsis

```perl
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
```

## Description

`input` is the number of inputs, or C<{ tokens => $count, vocab =>
$size }> when the first layer is an embedding. `layers` lists
C<[dense => $n]>, C<[embed => $dim]> and the activations `'relu'`,
`'tanh'`, `'sigmoid'`. `loss` is `'softmax'` (the target is a class
index) or `'mse'` (the target is a vector).

`backend` chooses where the arithmetic runs, see [Peta::NN::Backend](Peta-NN-Backend.md).
On the plain backend training is deterministic to the bit: the same `seed`
gives the same weights on any perl. Other backends agree with it to
rounding.

A saved network carries no backend: C<< Peta::NN->load($file, backend =>
'pdl') >> loads on whichever is wanted.

For networks that read and write strings see [Peta::NN::Model](Peta-NN-Model.md).

## Methods

### new

```perl
my $net = Peta::NN->new(input => ..., layers => [...], loss => 'softmax', seed => 1, backend => 'plain');
```

`input` and `layers` are required. `loss` is `softmax` (default) or
`mse`, `seed` defaults to 1, `backend` to `$ENV{PETA_NN_BACKEND}` or
`plain`.

### train

```perl
my $loss = $net->train(data => \@pairs, epochs => 10, batch => 16, lr => 0.01);
```

Trains on `[input, target]` or `[input, target, weight]` pairs and returns
the mean loss of the last epoch. Further arguments: `optimizer` (`adam`,
the default, or `sgd`) with `lr`, `momentum`, `beta1`, `beta2`,
`epsilon`, `weight_decay`; `lr_decay`, by which the learning rate is
multiplied after every epoch; `validate`, pairs that are not trained on and
whose loss is measured every epoch; `patience`, the number of epochs without
improvement after which training stops and returns to the best epoch's
weights; `min_delta`, what counts as an improvement; `watch`, a sub given
(training loss, validation loss) that returns the number `patience` watches
instead; `target_loss`, at or below which training stops; `on_epoch`, a sub
called with (epoch, mean loss) whose false return stops training.

A network made with `backend => 'auto'` settles its backend here, where
the work is known: it times a few steps on the backend it is on, and if the
run would take `$Peta::NN::WORTH` seconds (2) or more, on every other
backend this perl and this machine have, and trains on the fastest. The
weights are afterwards what they were. A backend that is not there is not
considered, and none is assumed to be faster than another. Since the
graphics card computes in single precision, where such a run goes decides
its result beyond the sixth digit; name the backend to pin it.

### history

What every epoch of the last `train` measured: a list of
`{ epoch, loss, validation }`.

### forward

The raw output for one sample: logits under the softmax loss.

### predict

Class probabilities for one sample under the softmax loss, the output itself
otherwise.

### classify

The most probable class of one sample.

### classify_all

The most probable class of each of many samples, as an array reference.

### accuracy

The share of `[input, class index]` pairs classified correctly.

### loss

The summed loss of `[input, target]` pairs, without touching the gradients.

### backprop

Forward and backward for a batch of pairs: leaves the batch's summed gradient
with the layers and returns its summed loss.

### params

Every parameter as `[layer, name]`, in layer order. The tensor is
`$layer->{name}`, its gradient after `backprop` is
`$layer->{"g$name"}`.

### weights

The parameters as flat Perl lists, in `params` order.

### gradients

The gradients as flat Perl lists, in `params` order.

### set_weights

Replaces the parameters by the given lists, which must fit the network.

### n_params

The number of weights.

### n_out

The number of outputs.

### layers

The layer objects, in order.

### backend

The name of the backend the network computes on.

### settled

For a network that was left the choice of its backend, how the last `train`
settled it: `{ backend, steps, seconds_per_step => { name => seconds } }`,
the timings being those that were taken. Nothing for a network whose backend
was named, or for a run of too few steps to time.

### generation

A number that changes whenever the weights do, for whoever caches something
derived from them.

### state

What it takes to rebuild the network: its definition and its weights. The
backend is not part of it.

### from_state

```perl
my $net = Peta::NN->from_state($state, backend => 'pdl');
```

The network a state describes. Weights that do not fit the definition are
refused.

### freeze_state

A state with its weights packed as little-endian doubles, which Storable's
portable format keeps exact.

### thaw_state

The reverse of `freeze_state`.

### save

Writes the network's state to a file, by convention `*.net`.

### load

```perl
my $net = Peta::NN->load($file, backend => 'pdl');
```

Reads a state file as plain data and rebuilds the network.

---

From the POD of `lib/Peta/NN.pm`; change it there.
