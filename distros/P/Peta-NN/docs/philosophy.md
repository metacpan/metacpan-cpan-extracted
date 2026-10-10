# What Peta::NN is for

Peta::NN trains small neural networks that each do one limited thing with a
string, and puts them together. It is written in Perl, for people who write
Perl.

## Small models, each for one thing

A model here answers one narrow question about a string: which ending makes
this German noun plural, which language this word looks like, what the
vocative of this name is. It has a few thousand to a few hundred thousand
weights, trains in seconds or minutes, and ships as a file of a few
kilobytes.

Such a model is trained to a stated quality. One says what it has to reach
(for example: 98% of the nouns it was not shown, and every noun of the core
vocabulary), and training goes on, and widens the model if it must, until
that is met or it is clear that it will not be. What a model reaches is
measured on data it was not shown, and the limits of its teacher are named
with it.

The data usually exists already, as rules or as a lexicon: 10 to 15 years
ago these tasks were solved with rule sets. A rule set, a dictionary lookup
or any program that knows the answer is a teacher; a model learns from the
pairs it produces, and then also answers for the words the teacher never
listed.

## Putting models together is the main way of working

A task that is too much for one small model is usually several small tasks.
The German dative plural is three: change the vowel (Apfel, Äpfel), rewrite
the ending (Äpfel stays, Mann becomes Männer), add the case (Äpfeln). Three
small models in a row are easier to get right, and to check one by one,
than one larger model that has to learn all of it at once.

There are three ways to have models work together, and they are different
things:

| | what it is | weights | answers |
|---|---|---|---|
| in a pipeline | each model's answer is handed to the next by Perl | those of the parts | |
| fused | the same models as they are, in one model, the hand-over inside | those of the parts | exactly the pipeline's |
| fused, consolidated | one model trained on what the chain does | fewer | nearly the pipeline's |

A chain of models is itself a model. It is asked, measured, saved as one
file, and put into further chains like any other. Its parts stay parts: one
of them can be trained further, measured and replaced alone, and the rest is
untouched. Fused, a whole batch passes all the parts on a graphics card
without coming back to Perl in between.

This is the project's bet: that many small models, each trained quickly and
checked on its own, then composed, are a practical alternative to training
one large model, and keep what a large model gives up, which is knowing what
each part does.

## Perl, and scripts

A model is defined, trained, measured and saved from a script of a few dozen
lines. A saved model is plain data read by one module. Nothing is compiled,
nothing has to be installed beside Perl; PDL makes the arithmetic faster and
a graphics card (under pperl) faster still, and the library chooses among
what is there.

## Kept simple

Peta::NN is small and new, and means to stay small.

- Few concepts: data, a model, a chain.
- One way to do a thing.
- What a model reads and what it is told are said by name, not by position.
- No dependency is required.
- What is not needed yet is not built.

## What it is not

It is not a general deep-learning framework, and not a tensor library: there
are three kinds of layer and no automatic differentiation. It is not for
large models, images or sound. Someone who needs those has PyTorch and
Keras, which do them well; what those do, and what is and is not worth
taking from them, is the subject of [the landscape page](landscape.md).
