# Peta::NN::Backend::WebGPU

Peta::NN on the graphics card

## Synopsis

```perl
my $net = Peta::NN->new(input => 2, layers => [ [dense => 2] ], backend => 'gpu');
```

## Description

Selected with `backend => 'gpu'`. Needs a pperl built with the
`webgpu` feature and a usable adapter. For a small model on few samples
the per-operation dispatch costs more than the arithmetic saves, and a
network with `backend => 'auto'` comes here only when a few timed steps
say it is faster ([Peta::NN, train](Peta-NN.md)). It pays with wide layers, large batches
and many samples: [Peta::NN](Peta-NN.md) then keeps the samples of a training run on the
card (see `epoch_data` below), and a step carries nothing there or back.

Single precision: results agree with the plain backend to about six digits.
See [Peta::NN::Backend](Peta-NN-Backend.md) for the operations.

## Methods

This class implements the backend interface described in
[Peta::NN::Backend, THE BACKEND INTERFACE](Peta-NN-Backend.md) and adds these methods to it.

### adapter

What the graphics adapter the backend computes on says of itself, as a table.

### epoch_data, epoch_order, batch_at, softmax_ce_at, epoch_loss

An epoch that stays on the card. `epoch_data(\@token_rows, $per_row,
\@classes, \@weights)` puts all the samples of a training run on the card,
once; `epoch_order($data, \@order)` the order they are taken in, once per
epoch; `batch_at($data, $start, $count)` gives the token rows of a step as
`embed` takes them, picked on the card; `softmax_ce_at($logits, $data,
$start)` returns the gradient and leaves the losses on the card;
`epoch_loss($data)` reads their sum when the epoch is over. [Peta::NN](Peta-NN.md)
trains this way when its backend has these methods.

### define

`define($name, \@bindings, $dimensions, $body, $functions)`: adds a compute shader under
a name, for a module that brings its own ([Peta::NN::Fused](Peta-NN-Fused.md) does). A binding
is `"r:name"` (floats, read), `"w:name"` (floats, written), `"u:name"`
(unsigned integers, read) or `"x:name"` (unsigned integers, written); the
body is WGSL and sees the invocation as `id` and the parameter block as `p`;
`$functions`, optional, is WGSL functions the body calls.

### dispatch

`dispatch($name, \@buffers, \@integers, $nx, $ny)`: runs a shader over a
grid of invocations, with up to eight integers in its parameter block.

### buffer

`buffer($bytes)`: a storage buffer on the card holding the bytes, or, given
a number, one of that many bytes.

---

From the POD of `lib/Peta/NN/Backend/WebGPU.pm`; change it there.
