# Peta::NN::Model

train a micro model from string pairs, export it as a model file

## Synopsis

```perl
use Peta::NN::Model;

my $model = Peta::NN::Model->new(
    kind   => 'edit',                                  # rewrite the end of a word
    window => 5,                                       # reading its last 5 characters
    layers => [ [embed => 8], [dense => 32], 'relu' ], # the output layer is added
);
$model->fit(\@pairs, epochs => 12, batch => 16);       # [ ['Apfel', 'Äpfel', 'plural'], ... ]

print scalar $model->predict('Vogel', 'plural');       # Vögel
printf "%.1f%%\n", 100 * $model->accuracy(\@held_out);

$model->export(file => 'deu-noun.model', bits => 8, name => 'German noun forms');
```

and wherever that file goes, with only the inference leg installed:

```perl
use Peta::NN::Inference;
my $noun = Peta::NN::Inference->load('deu-noun.model');
print scalar $noun->predict('Vogel', 'plural');
```

## Kinds

**class**

The output of a pair is a label for the whole input. The network reads
`window` characters from the `side`: 'right' (the default), 'left', or
'both' for the first and the last `window` characters together.

**edit**

The output is the input with one end, or both, rewritten. Each pair is
reduced to an edit, "cut this many characters, add this text", and the
network learns to choose the edit. With `side` 'right' (the default) it
reads and rewrites the end of the string, with 'left' its beginning, with
'both' both at once; 'auto' picks 'left' or 'right', whichever end the
training pairs differ at in fewer ways.

**rewrite**

Input and output have the same length and each character is decided on its
own, from the `radius` characters on either side of it.

## Parameters

Whatever follows input and output in a pair is a parameter: `[$in, $out,
'dative']`, `[$in, $out, 'feminine', 'comparative']`. The model treats each
as an opaque value and learns what to do for it; it has no notion of what
the value means. All pairs of a model have the same number of parameters,
and a call (`predict`, `predict_all`, `distribution`) passes the same
number after the string.

## Training further

`fit` starts from nothing. `tune` goes on training the network a model
already has, with the same arguments: on corrections, or on more data.
It keeps what the model can read and answer; a pair whose answer is not one
of the model's labels is refused, since that needs a new output and a fit
from scratch.

`widen` gives a trained model wider hidden layers and leaves its answers as
they are; training goes on from there with `tune`. A model that has learned
all its size allows is given room this way, and not replaced by a larger one
that starts from nothing.

A model to tune comes from `load` (a training state) or from
`from_model` (a model file, as shipped: the architecture is read back from
its layers, the weights are as coarse as the file stored them).

## Two files

`save` writes the training state, by convention `*.state`: everything
needed to load the model into this class again, weights at full precision.
`export` writes the model file for the inference leg, by convention
`*.model`: smaller, with 32-bit or 8-bit weights, and all a user of the
model needs.

Each kind carries its own marker and is refused by the loader of the other.

## Methods

### new

```perl
my $model = Peta::NN::Model->new(kind => 'edit', window => 6, side => 'right', layers => [...], seed => 1, backend => 'auto');
```

`kind` is required. `window` defaults to 6, `side` to `right`, `radius`
(for `rewrite`) to 2, `layers` to an embedding of 8 and one hidden layer of
32. What a model reads can be said in one table instead: C<< reads => { end
=> 8 } >>, `{ front => 2 }`, `{ both => 5 }`, or for a rewrite model
`{ around => 2 }`.

For a model that is trained on a [Peta::NN::Data](Peta-NN-Data.md): `from` and `to`, the
fields it reads and answers; `given`, the fields it is given beside, which
are then the names of its parameters; and `goal`, what it has to reach
((see `train`); and `train`, `search` and `budget`, the options its
`train` then has without being told again.

### train

`train($data, %options)`: trains the model on a [Peta::NN::Data](Peta-NN-Data.md): on the
records that are not held out, reading the field `from`, answering the field
`to`, given the fields `given` (all said when the model was made). With a
`goal`, `{ unseen => 0.98, core => 1 }`, it is trained by a
[Peta::NN::Job](Peta-NN-Job.md) until it answers that share of the records it was not shown
and of the records of each named mark of the data; without, it is fitted
once and the held-out records say when to stop. Options: `train` (what goes
to the training: `batch`, `lr`, ...), `search` and `budget` (the job's),
`backend`.

### score

`score($data)`: the share of records the model answers exactly, of those
held out (`unseen`), and of each mark of the data, of its records that are
not held out; as a table.

### report

What the job that trained the model to its goal has to say.

### reached

What that job measured.

### fit

`fit(\@pairs, %train)`: learns from `[input, output, parameters...]` pairs,
starting from nothing. `validate` (pairs that are not trained on) and
`weight` (a sub giving how much a pair counts) are the model's own
arguments; everything else goes to [Peta::NN, train](Peta-NN.md). Returns the model.

### tune

`tune(\@pairs, %train)`: goes on training the network the model has. What
the model can read and answer stays as it is.

### widen

`widen($width)`: makes the hidden layers `$width` units wide without
changing an answer; `tune` then trains the wider model on. A new unit reads
with random weights and is read with zeros.

### predict

`predict($string, @parameters)`: the answer; in list context also its
confidence.

### predict_all

`predict_all(\@strings, @parameters)`: the answers, in order.

### distribution

Every answer the model considers, with its probability; see
[Peta::NN::Inference, distribution](Peta-NN-Inference.md).

### pooled

One distribution for several strings together; class models only.

### accuracy

`accuracy(\@pairs)`: the share of pairs reproduced exactly, by the inference
leg. With `where_trained => 1` a model that is trained on the graphics
card is measured there, in single precision and many times faster; any
other model as always.

### indistinct

`indistinct(\@pairs)`: the pairs the model reads exactly as it reads another
pair with a different answer, each as `[pair, the other answer, a pair that
has it]`. It cannot get such pairs right together, whatever the training; a
wider window tells them apart.

### labels

The answers the model can give.

### parameters

The values known for each parameter: one sorted list per position.

### given

The names of the parameters, in their order, if the model was given any
(`given => ['gender']` when it was made). A model whose parameters have
names is asked by name: `predict($noun, gender => 'neuter')`.

### net

The [Peta::NN](Peta-NN.md) network inside.

### inference

The [Peta::NN::Inference](Peta-NN-Inference.md) object for the weights as they are now.

### data

The model as the inference leg's data: how it reads a string, its labels, and
its layers with their weights as lists.

### export

`export(file => $path, bits => 32, name => ..., description => ..., source => ..., fidelity => {...})`:
writes the model file that ships. `bits` is 32 or 8.

### from_model

`Peta::NN::Model->from_model($file)`: a trainable model from a model
file.

### state

The training state as plain data: the model's definition and its weights at
full precision.

### from_state

`Peta::NN::Model->from_state($state, backend => ...)`: the model a
training state describes.

### save

Writes the training state to a file, by convention `*.state`.

### load

`Peta::NN::Model->load($file, backend => ...)`: the model of a state
file.

---

From the POD of `lib/Peta/NN/Model.pm`; change it there.
