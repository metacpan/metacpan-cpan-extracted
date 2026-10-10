# Glossary

The words this documentation uses, in the sense it uses them.

**answer**
: What a model gives for a string: the rewritten string, or a label.

**batch**
: How many records a model is shown between two corrections of its weights.

**chain**
: Models put together into a model: named parts in order. See
  [composing](guides/composing.md).

**class model**
: A model that answers with one of a fixed set of labels (a language, a set
  of word classes) and leaves the string as it is.

**core**
: By convention the name of the mark for the records a model has to get
  right without exception; see *mark*.

**data**
: Records with named fields, which models are trained on and measured by.

**edit model**
: A model that rewrites a string at its end (or its front, or both): its
  answer is "cut so many characters and add these".

**epoch**
: One pass of training over all the records a model is shown.

**field**
: A named value of a record: the singular, the gender, the plural.

**fused**
: The models of a chain as they are, in one model, with what happens
  between them inside it. Answers exactly what the pipeline answers.

**fused, consolidated**
: One model trained on what a chain does. Smaller, and not the same function.

**given**
: What a model is told beside the string it reads, by name: the gender of a
  noun. To the model it is a value that goes with different answers; it
  knows nothing of what a gender is.

**goal**
: What a model has to reach: the share of unseen records, and of the records
  of each named mark, that it must answer exactly.

**held out**
: Not trained on, so that there is something left to measure by.

**label**
: One of the answers a model can give. A model has a fixed list of them,
  learned from its training data.

**mark**
: A named group of records, such as the `core`.

**model**
: Something trained that answers for a string. A chain is one too.

**part**
: One of the named members of a chain.

**pipeline**
: Models in a row, each one's answer handed to the next by Perl.

**pooled**
: Said of a class model that judges a whole text at once: every word is
  evidence, and all words get the one answer.

**record**
: One thing a model is to learn something about: a noun with its gender and
  its plural.

**rewrite model**
: A model that decides for every character of a string what it becomes.

**teacher**
: Whatever produces the answers a model learns from: a rule set, a lexicon,
  a program.

**unseen**
: Said of records a model was not shown: the held-out ones.

**weight**
: One of the numbers a model consists of. Training is finding them.
