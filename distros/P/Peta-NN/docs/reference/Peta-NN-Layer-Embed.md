# Peta::NN::Layer::Embed

learned vectors for token indices

## Synopsis

```perl
my $net = Peta::NN->new(input => 4, layers => [ [dense => 2] ]);     # as one of:
input  => { tokens => 6, vocab => 40 },
layers => [ [embed => 8], [dense => 16], 'relu', [dense => 3] ]
```

## Description

Written as C<[embed => $dim]>, first in the layer list of a network
whose input is C<{ tokens => $count, vocab => $size }>.

## Methods

A layer is made and driven by [Peta::NN](Peta-NN.md); these are what the network calls.

### new

The layer, from what its entry in the layer list says.

### type

The layer's kind, as a model file names it.

### init

`init($n_in, $rng, $backend)`: sets the layer up for its input size and
returns its output size.

### param_names

The names of the layer's parameter tensors.

### forward

The layer's output for a batch.

### backward

Takes the gradient of the output, leaves the gradients of the parameters
with the layer, and returns the gradient of the input.

### spec

The layer as it is written in a layer list.

### param_cols

`param_cols($name)`: numbers per row of a parameter tensor.

---

From the POD of `lib/Peta/NN/Layer/Embed.pm`; change it there.
