# The landscape

*A draft for discussion, not a verdict.* What other frameworks offer, what
Peta::NN already has under another name, what would be worth learning from
them, and what we decide not to do. The last section lists the questions
that are open.

Three things set Peta::NN apart, and every row below is read against them:
it is Perl and scripting; it is small and new, and means to stay simple; and
it is about composable micro models, not about one large one.

## PyTorch

A tensor library with automatic differentiation, and everything built on
it. The network is ordinary code that runs; the training loop is written by
the user.

| It offers | We have | To learn | Not for us |
|---|---|---|---|
| tensors and autograd | three layer kinds with hand-written gradients, checked against numeric differentiation | | a tensor library; autograd. It is the reason PyTorch can do anything, and the reason it is large |
| `nn.Module`: a model is an object with parts | a model is declared; a chain has named parts | parts that can be inspected, replaced, saved alone: we do this, and it is worth keeping strict | subclassing as the way to define a model |
| `DataLoader`, datasets | `Peta::NN::Data` | streaming data that does not fit in memory, when that day comes | workers, samplers, collate functions |
| the training loop is yours | `train`, to a goal | | writing the loop by hand as the normal case |
| `state_dict`, checkpoints | training states, chain files | resuming an interrupted long run | |
| devices: `.to('cuda')` everywhere | the backend is chosen by timing | that explicit device handling is the most common source of errors there | device management in user code |
| TorchScript, ONNX export | a chain file read by one module | a way out of Perl for a trained model, see the open questions | a second runtime of our own |
| a hub of models | a bundle of model files | saying of every model what it was trained on and measured by | a hub |

The lesson of PyTorch is its *"Learn the basics"* path: one small task
carried from data to a saved model, each page adding one idea. Our getting
started is built that way.

## Keras

The high-level API: layers, models, `compile`, `fit`. Its design principles
are stated outright and are close to ours: reduce the load on the reader,
one obvious way, *progressive disclosure of complexity*.

| It offers | We have | To learn | Not for us |
|---|---|---|---|
| `Sequential`, the functional API | a model declared by what it does; a default network | that the simple case takes three lines, and the next step does not require starting over | a graph API for arbitrary architectures |
| `compile(optimizer, loss, metrics)` | none needed: the kind of model settles the loss | | a compile step |
| `fit` with callbacks, early stopping | `train`; a goal instead of a callback | goals are our callbacks, and say more: keep it that way | a callback zoo |
| `model.summary()` | `peta-nn-info`, `info` | a summary of a model in memory as readable as that | |
| the code examples gallery | `examples/`, each in one house style | every example runs and shows its output; ours do, the docs' code is run by a test | a gallery page per example |
| Keras Tuner | a job widens the model until the goal is met | | searching many hyperparameters |
| preprocessing layers inside the model | what a model reads is part of the model and its file | this is right and we have it: a shipped model cannot be fed wrongly | |
| saving a whole model in one file | a chain file | | |

Keras is the closest model for how our pages should read.

## scikit-learn

Classical machine learning behind one small interface: `fit`, `predict`,
`score`, pipelines, cross-validation.

| It offers | We have | To learn | Not for us |
|---|---|---|---|
| estimators with `fit`, `predict`, `score` | `train`, `predict`, `score` | the discipline: every object answers to the same few verbs | |
| `Pipeline` | `chain` | | |
| `train_test_split`, cross-validation | `hold_out`, by value and repeatable | cross-validation for small data, where one held-out part is noisy | stratified, grouped, time-series splitters as a family |
| metrics, confusion matrices | the share answered exactly, per mark | a look at *what* is confused with what, as `langid.pl` prints by hand | a metrics module |
| character n-gram models (`HashingVectorizer` and a linear model) | | this is the honest baseline for our tasks: a model of ours should be compared with it at least once | |

## fastText

Word vectors and text classification from character n-grams, trained in
seconds on a CPU; its language identifier covers 176 languages in under a
megabyte.

| It offers | We have | To learn | Not for us |
|---|---|---|---|
| subword n-grams, hashed | a window of characters at the ends of a word | n-grams see the middle of a word, which our windows do not; for language identification that may matter | |
| language identification of text | `langid.pl`, `wordclass.pl`: words, pooled | theirs is the yardstick for ours; and a classifier that knows many languages gives more sensible doubt for a text in none of ours | competing with it on coverage |
| quantised models | 8-bit weights where the answers hold | product quantisation, if files ever have to be smaller | |

## ONNX and its runtimes

A file format for networks and engines that run it anywhere.

| It offers | We have | To learn | Not for us |
|---|---|---|---|
| one format, many runtimes | our own file, our own reader | | being a runtime for other people's models |
| export from every framework | | exporting a chain, so that a model trained here runs where there is no Perl | importing |

The seams of a fused chain (select the best label, carry its edit out) are
not standard operators; an export would have to express them or stop at
single models.

## Neural networks in Perl

`AI::MXNet` binds MXNet, which is retired. `AI::TensorFlow::Libtensorflow`
binds the TensorFlow C library and runs models trained elsewhere. `PDL` is
the numeric base and has no network layer of its own. `AI::NeuralNet::*`,
`AI::Perceptron`, `AI::FANN` are old and small. None trains a model to a
goal from Perl data, or composes models. We are not replacing any of them;
PDL is one of our engines.

## What we decide not to do

- A general framework: arbitrary layers and architectures, autograd.
- Large models, images, sound.
- Device handling, compile steps and training loops in the user's code.
- A hub, a tuner, a metrics library, an ecosystem.
- More than one way to do the same thing.

## Open questions

To be decided together; each names what speaks for and against.

1. **More kinds of layer.** Convolution over characters, recurrence or
   attention would let one model see a whole word instead of its ends. For:
   the German way back needs eleven characters to tell *Frühschichten* from
   *Geschichten*, and still cannot see further. Against: each kind is code in
   three backends and in the fused engine, and "split the task into two
   small models" has so far been the better answer.
2. **Context.** A word's class in its sentence needs its neighbours. Is that
   a model that reads several words, or a chain in which each word's model
   is given its neighbours' answers? The second is in our style; neither is
   built, and there is no tagged text to learn it from yet.
3. **More than the first answer.** Models answer with one label. A set of
   classes is now one label per set (`N|V`); a model with one output per
   class would be smaller and could say "N, and perhaps V".
4. **Doubt about what it was never shown.** A three-language model shown
   French answers one of its three, sure of itself. A classifier that knows
   many languages would doubt more sensibly; so might a way for a model to
   say "none of mine".
5. **Fused, consolidated.** One model trained on what a chain does was tried
   once (21,865 weights for 28,828, 98.1% for 98.4%). Should a chain offer
   it, starting from the fused chain's weights instead of from nothing?
6. **Export.** ONNX, or plain C, for a trained chain to run without Perl.
7. **Resuming.** A long job that is interrupted starts again from nothing.
8. **Cross-validation** for small data, and a look at what is confused with
   what, as part of `score`.
9. **A baseline.** Character n-grams with a linear model, run once per task,
   so that every number here stands next to the simple alternative.
10. **Where the documentation is built.** These pages are Markdown that
    GitLab renders and Sphinx with MyST accepts. When Peta::NN is part of
    pperl, they join its documentation; until then, is a rendered site
    wanted?
