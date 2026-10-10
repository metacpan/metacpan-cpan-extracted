# Peta::NN::Backend

the engines Peta::NN can compute on

## Synopsis

```perl
my $net = Peta::NN->new(..., backend => 'pdl');     # or 'plain', 'gpu', 'auto'

print join ' ', Peta::NN::Backend::available();     # gpu pdl plain
```

The default is `plain`, or `$ENV{PETA_NN_BACKEND}` when set.

## Functions

### names

The names of all backends, whether this perl has them or not.

### available

The names of the backends that work in this perl, on this machine.

### try

```perl
my $backend = Peta::NN::Backend::try('gpu') or warn $@;
```

A backend object, or undef when its engine is not in this perl or finds
nothing to run on; `$@` then says why.

### create

A backend object for a name or for `auto`, which takes `pdl` if it loads
and `plain` otherwise: that is where a network that is left the choice
starts, and it settles on one of the available backends when it is trained
([Peta::NN, train](Peta-NN.md)). Dies if the backend is not available.

## The backend interface

A backend owns the tensors (a batch of rows: inputs, activations, weights,
gradients) and implements these operations on whole batches. Tensors are
opaque to the caller.

**new**

A backend object. Dies when the engine is missing.

**name**

The backend's name.

**tensor**

`tensor(\@flat, $cols)`: rows of `$cols` numbers, row after row.

**tokens**

`tokens(\@flat, $per_row)`: rows of token indices, for `embed`.

**flat**

A tensor as a flat Perl list.

**zeros_like**

A tensor of zeros in the shape of another.

**affine**

`affine($X, $W, $b)`: X W^T + b.

**affine_grad**

`affine_grad($X, $W, $dY, $need_dx)`: (dW, db, dX), summed over the batch.

**activate**

`activate($kind, $X)`: relu, tanh or sigmoid of every value.

**activate_grad**

`activate_grad($kind, $Y, $dY)`: the gradient, in terms of the output `$Y`.

**embed**

`embed($E, $tokens)`: table rows, concatenated per sample.

**embed_grad**

`embed_grad($E, $tokens, $dX)`: the gradient of the table.

**softmax_ce**

`softmax_ce($logits, \@classes, \@weights)`: (summed loss, dlogits). The
weights, one per row, are optional.

**mse**

`mse($out, \@flat_targets, \@weights)`: (summed loss, dout).

**decay**

`decay($p, $factor)`: every value times `$factor`, in place.

**sgd_update**

`sgd_update($p, $g, $velocity, $lr, $momentum, $scale)`, in place.

**adam_update**

`adam_update($p, $g, $m, $v, $rate, $b1, $b2, $eps, $scale)`, in place.

**argmax_rows**

`argmax_rows($tensor, $cols)`: the index of the largest value in each row.
Implemented here for every backend.

---

From the POD of `lib/Peta/NN/Backend.pm`; change it there.
