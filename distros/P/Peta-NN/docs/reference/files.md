# Files

Every file is written with Storable in its portable format and read back as
plain data: nothing in a file is blessed into a class or executed, and a
file is checked in full before anything is computed from it. Each says which
version of the library wrote it and in which layout; a layout this version
cannot read is refused by its number.

| File | Written by | Read by | Holds |
|---|---|---|---|
| a chain, `*.chain` | `Peta::NN::Chain->save` | `Peta::NN::Chain->load` | the parts in order (name, whether pooled, what is fixed, by which part it is chosen), every model's data under its name, and what was said about the chain |
| a model, `*.model` | `Peta::NN::Model->export` | `Peta::NN::Inference->load`, `Peta::NN::Chain->load` | one model's data |
| a fused model, `*.fused` | `Peta::NN::Fused->save` | `Peta::NN::Fused->load` | the models' data and the pipeline's steps |
| a training state, `*.state` | `Peta::NN::Model->save` | `Peta::NN::Model->load` | a model's definition and its weights at full precision, to go on training from |

## A model's data

What a model needs to answer, and nothing of how it was trained:

| Field | |
|---|---|
| `kind` | `class`, `edit` or `rewrite` |
| `side`, `window`, `radius` | what it reads of a string |
| `vocab` | character to token |
| `params`, `given` | per parameter the values it knows, each with its token; and the parameters' names |
| `labels` | its answers, in the order of the network's outputs |
| `layers` | the network: an embedding, dense layers and activations, with their weights |
| `bits` | how the weights are packed: 8 (signed bytes and a scale per array), 32 or 64 (floats) |
| `meta` | what the file says of itself: name, description, source, when it was made, what was measured |

A file is refused if a field is of the wrong type, a token index is used
twice or lies outside the embedding, an edit model's label is not an edit, a
layer does not fit the one before it, the last layer does not have one
output per label, or a weight is not a finite number.
