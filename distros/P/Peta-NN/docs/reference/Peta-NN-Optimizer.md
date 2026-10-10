# Peta::NN::Optimizer

SGD with momentum, and Adam

## Synopsis

```perl
my $opt = Peta::NN::Optimizer->new(kind => 'adam', lr => 0.005,
                                   backend => $backend, params => [ $net->params ]);
$opt->step(1 / $batch_size);
```

## Methods

### new

`kind` is `adam` (default) or `sgd`; `backend` and `params`, a list of
`[holder, name]`, are required. `lr`, `momentum`, `beta1`, `beta2`,
`epsilon` and `weight_decay` are optional.

### step

`step($scale)`: one update from the gradients the last backward pass left.
`$scale` multiplies every gradient; 1/batch size turns a batch's summed
gradient into its mean.

---

From the POD of `lib/Peta/NN/Optimizer.pm`; change it there.
