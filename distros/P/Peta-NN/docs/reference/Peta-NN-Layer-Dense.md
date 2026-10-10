# Peta::NN::Layer::Dense

fully connected layer

## Synopsis

```perl
my $net = Peta::NN->new(input => 4, layers => [ [dense => 2] ]);     # as one of:
layers => [ [dense => 8], 'relu', [dense => 2] ]
```

## Description

Written as C<[dense => $outputs]> in a network's layer list. The input
size comes from the layer before it.

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

From the POD of `lib/Peta/NN/Layer/Dense.pm`; change it there.
