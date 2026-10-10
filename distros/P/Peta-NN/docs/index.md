# Peta::NN

Small neural networks in Perl that each do one limited thing with a string,
and are put together.

| If you want to | read |
|---|---|
| train and use a first model | [Getting started](getting_started.md) |
| know what the project is for, and what it is not | [What Peta::NN is for](philosophy.md) |
| do a particular thing | the guides below |
| look up a method | [Reference](reference/index.md) |
| see worked examples | [The examples](examples.md) |
| see numbers | [Measurements](measurements/index.md) |
| know how this compares with PyTorch, Keras and others | [The landscape](landscape.md) |

## Guides

| Guide | What it covers |
|---|---|
| [Data](guides/data.md) | records and fields, teachers, holding out, marks |
| [Models](guides/models.md) | the three kinds of model, what a model reads and is given, training with and without a goal |
| [Composing](guides/composing.md) | chains: in series, classifying, a whole text, choosing among models |
| [Fusing](guides/fusing.md) | pipeline, fused, fused and consolidated; running on a graphics card |
| [Backends](guides/backends.md) | plain Perl, PDL, the graphics card, and how the choice is made |
| [Shipping](guides/shipping.md) | files, 8-bit and 32-bit weights, what a user of a model needs |

## Building blocks

The level under the guides, for when the high level does not fit.

| Page | What it covers |
|---|---|
| [Jobs](blocks/jobs.md) | training one model until thresholds are met: stages, widening, the second seed, reports |
| [Pipelines](blocks/pipelines.md) | models wired step by step, with parameters by position |
| [Fused models](blocks/fused.md) | how the models of a pipeline become one, and what that costs and buys, measured |
| [The network and the string models](blocks/network-and-models.md) | layers, losses, `fit` and `tune`, model files |

For authors: [tests, the distribution, design decisions](contributing.md).

## The three levels

Most programs only use the first.

| Level | Modules | For |
|---|---|---|
| High level | `Peta::NN::Data`, `Peta::NN::Model`, `Peta::NN::Chain` | declaring data, models and chains; training to a goal; saving and using |
| Building blocks | `Peta::NN::Job`, `Peta::NN::Inference`, `Peta::NN::Pipeline`, `Peta::NN::Fused` | when the high level does not fit |
| Engine | `Peta::NN`, the backends, layers, optimizer | the network itself |

[Glossary](glossary.md)
