# The network and the string models

The level under [the guides](../index.md#guides). A model that is declared
with `from`, `to` and a `goal` and trained with `train` ([Models](../guides/models.md))
is the same `Peta::NN::Model` as here; `fit`, `tune` and `export` are what
happens underneath, and can be called directly when the data is pairs of
strings in hand and nothing more is wanted.

**The network** (`Peta::NN`) knows numbers only:

```perl
my $net = Peta::NN->new(
    input   => 5,                                  # or { tokens => 6, vocab => 40 }
    layers  => [ [dense => 24], 'tanh', [dense => 2] ],
    loss    => 'softmax',                          # or 'mse'
    seed    => 3,
    backend => 'pdl',                              # or 'plain' (default), 'gpu'; 'auto' leaves it to the network
);
$net->train(data => \@pairs, epochs => 800, batch => 8, lr => 0.01);
```

**The model** (`Peta::NN::Model`) wraps a network for string tasks. One
decision of the network means one of three things:

| kind | one decision is | reads | fits |
|---|---|---|---|
| `class` | a label for the whole string | `window` characters from one end, or from both | language id, gender, part of speech |
| `edit` | "cut k characters, add this", at the end, the front, or both | the same; `side => 'auto'` picks the end | vocative, inflection, lemmatisation, prefixes |
| `rewrite` | the replacement of one character | `radius` characters either side | diacritics, casing |

```perl
my $model = Peta::NN::Model->new(kind => 'edit', window => 4, backend => 'pdl',
                                 layers => [ [embed => 6], [dense => 24], 'relu' ]);
$model->fit(\@pairs, epochs => 8);                 # [ ['Irena', 'Ireno'], ... ]
$model->export(file => 'ces-vocative.model');
```

The model file is a Storable blob: how the model reads a string, its labels,
its weights, and what it says of itself (name, description, source, the
fidelity measured for it). The weights are packed as 32-bit floats, about
four bytes per parameter, or with `export(bits => 8)` as signed bytes with
one scale per weight array, about one byte per parameter. The inference leg
loads either, on perl5 as well:

```perl
use Peta::NN::Inference;
my $vocative = Peta::NN::Inference->load('ces-vocative.model');
print scalar $vocative->predict('Irena');
my @all = $vocative->predict_all(\@names);

my ($answer, $confidence) = $vocative->predict('Irena');      # the best answer and its probability
my $considered = $vocative->distribution('Irena');           # every answer: [ [answer, probability], ... ]
```

`distribution` shows a model that is not sure. For a class model, `pooled`
combines the distributions of several strings into one verdict (the words of
a text, for its language). `peta-nn-info FILE` prints what a file is.

Loading reads the file as plain data and checks it in full before use: the
format marker, every field, that each layer fits its neighbours and the
labels, and that every weight is a finite number. A file that fails is
refused with the reason.

| file | written by | read by | holds |
|---|---|---|---|
| `*.model` | `Model->export` | `Peta::NN::Inference->load`, `Peta::NN::Chain->load` | one model for use: 32-bit or 8-bit weights |
| `*.state` | `Model->save` | `Model->load` | a string model's training state, full precision |
| `*.net` | `Peta::NN->save` | `Peta::NN->load` | a bare network's state, full precision |

Each kind carries its own marker, and each loader refuses the other kinds.
What is trained through the high level is saved as a chain's file instead,
even a single model; all the files are described in
[Files](../reference/files.md).

A model file is not a dead end. `Peta::NN::Model->from_model($file)` grows it
back into a trainable model (the architecture follows from the layers in the
file; the weights are 32-bit), and `$model->tune(\@pairs)` goes on training
what is there, on corrections or new data, without starting over. `tune`
keeps the vocabulary and the labels as they are; a pair that needs an answer
the model does not have is refused.

It computes on PDL when the perl running it has PDL and in plain Perl loops
otherwise. The training leg answers through the same code, so what is
measured while training is what a user of the file gets. See
[Sizing](../measurements/sizing.md) for what size is practical on which
engine.

A model may take **parameters**. Whatever follows input and output in a
training pair is one (`[$in, $out, 'dative']`, `[$in, $out, 'feminine',
'comparative']`). Made with `given => ['case']` the model has names for
them, and a call names them: `predict($string, case => 'dative')`; a model
without names takes as many values after the string, in their order. A parameter is an opaque value. The model
learns what to do for each value it is shown and knows nothing of what a
value means; `parameters` lists the values per position. The wrong number of
parameters, or a value the model was never trained with, is an error. A model
does not judge its input either: given nonsense, it answers something. The
Czech adjective converter is a single model with the target degree as its
parameter.

Not there yet: a model that writes its output character by character
(needs a recurrent or attention layer and a decoder). The three kinds above
all choose from a fixed set of labels.

