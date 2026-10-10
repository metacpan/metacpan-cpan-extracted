# Reference

Every module, from its own documentation. `perldoc Peta::NN::Chain` shows the same.

## High level

What most programs use.

| Module | |
|---|---|
| [Peta::NN::Data](Peta-NN-Data.md) | records with named fields, to train models on and measure them by |
| [Peta::NN::Model](Peta-NN-Model.md) | train a micro model from string pairs, export it as a model file |
| [Peta::NN::Chain](Peta-NN-Chain.md) | models put together into a model |

## Building blocks

When the high level does not fit.

| Module | |
|---|---|
| [Peta::NN::Job](Peta-NN-Job.md) | train a model until it meets given fidelity thresholds, at the smallest size that can |
| [Peta::NN::Inference](Peta-NN-Inference.md) | load a trained model and get answers from it |
| [Peta::NN::Pipeline](Peta-NN-Pipeline.md) | models in series, and routed by a classifier |
| [Peta::NN::Fused](Peta-NN-Fused.md) | micro models fused into one, as they are, the seams inside |
| [Peta::NN::Parallel](Peta-NN-Parallel.md) | independent pieces of work on several cores |
| [Peta::NN::Codec](Peta-NN-Codec.md) | characters to token indices, string pairs to edit labels |

## Engine

The network itself.

| Module | |
|---|---|
| [Peta::NN](Peta-NN.md) | a small neural network, defined, trained and saved in Perl |
| [Peta::NN::Backend](Peta-NN-Backend.md) | the engines Peta::NN can compute on |
| [Peta::NN::Backend::Plain](Peta-NN-Backend-Plain.md) | Peta::NN on plain Perl arrays |
| [Peta::NN::Backend::PDL](Peta-NN-Backend-PDL.md) | Peta::NN on PDL ndarrays |
| [Peta::NN::Backend::WebGPU](Peta-NN-Backend-WebGPU.md) | Peta::NN on the graphics card |
| [Peta::NN::Layer::Dense](Peta-NN-Layer-Dense.md) | fully connected layer |
| [Peta::NN::Layer::Embed](Peta-NN-Layer-Embed.md) | learned vectors for token indices |
| [Peta::NN::Layer::Activation](Peta-NN-Layer-Activation.md) | relu, tanh and sigmoid |
| [Peta::NN::Optimizer](Peta-NN-Optimizer.md) | SGD with momentum, and Adam |
| [Peta::NN::RNG](Peta-NN-RNG.md) | seeded random numbers that are the same on every perl |

## Teachers

Readers of the PetaMem lexica; not part of the distribution.

| Module | |
|---|---|
| [Peta::NN::Teacher::Lex](Peta-NN-Teacher-Lex.md) | the rules of a PetaMem .lex grammar as teachers |
| [Peta::NN::Teacher::Lexicon](Peta-NN-Teacher-Lexicon.md) | the PetaMem lexica as a source of words |

## Also

| | |
|---|---|
| [Files](files.md) | what is in a chain's, a model's and a fused model's file, and in a training state |
| `peta-nn-info FILE ...` | prints what a file is |
| `PETA_NN_BACKEND` | names the backend models are trained on (`plain`, `pdl`, `gpu`, `auto`) |
| `PETA_NN_ENGINE` | `plain` makes single models answer without PDL |
| `PETA_NN_WORKERS` | how many models are trained side by side |
| `PETAMEM_LEXICA` | where the teachers find the PetaMem lexica |
