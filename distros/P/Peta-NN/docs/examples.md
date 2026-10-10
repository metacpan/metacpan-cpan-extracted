# The examples

Scripts in `examples/`, each a whole piece of work from data to a saved
model. They all read the same way, under the same headings: *Settings*,
*Data*, *Models*, *Training*, *Measuring*, *Using it*. Start one with
`pperl examples/NAME.pl` (or `perl`); with `PETA_NN_WORKERS=4` the models of
one script are trained side by side.

| Script | What it shows | Needs | Takes |
|---|---|---|---|
| `inflect.pl` | a rule as the teacher; one model; save and load | nothing | seconds |
| `nouns-deu.pl` | German nouns: four small models, three chains (singular to plural, on to a case, and back); goals; a core that has to be right | `nouns.tsv`, which ships | 2 to 3 minutes |
| `wordclass.pl` | one model names the language of a text and so chooses which of three models says what each word can be | data written by `wordclass-data.pl` | 4 minutes on a graphics card |
| `langid.pl` | which of twenty languages a word is; a text judged by pooling its words | the PetaMem lexica | 2 to 3 minutes |
| `vocative-ces.pl` | Czech names in the vocative, from a grammar's rules | the PetaMem lexica | seconds |
| `adjectives-ces.pl` | Czech adjectives: which degree, any degree into any other (an edit of both ends), the genus; exceptions; a chain with a fixed parameter | the PetaMem lexica | 2 minutes |
| `grammar-ces.pl` | a whole grammar distilled: one model per rule | the PetaMem lexica | minutes |

Two scripts only write data, with code that is not this project's:

| Script | Writes | With |
|---|---|---|
| `nouns-deu-data.pl` | `examples/out/deu-noun/nouns.tsv`: German nouns with gender and plural | the PetaMem lexica and their plural rules |
| `wordclass-data.pl` | `examples/out/wordclass/words.tsv` and `text.tsv`: words with their classes, running text cut into words | PMLS, the PetaMem Language Server |

## What they reached

Measured where the scripts were last run (a ThinkPad P53, pperl, an RTX
5000); the numbers are what the scripts print.

### German nouns (`nouns-deu.pl`)

45,218 nouns; 9,778 are the core (a lexicon lists their plural, or other
nouns end in them), 3,617 are held out.

| Chain | Models | Nouns not shown | The core |
|---|---|---:|---:|
| singular to plural | `umlaut` (18,761 weights), `ending` (10,002) | 98.3% | 100% |
| singular to a plural case | those and `case` (656) | 98.4% | 100% |
| plural to singular | `singular` (23,783) | 96.2% | 99.8% |

Back to the singular, 39 plurals belong to two nouns (*Ahnen*: *Ahn* and
*Ahne*); only one of them can come back, which is the 0.2%.

### The language of a text, and its words' classes (`wordclass.pl`)

Three languages. The teacher of the classes is a lexicon lookup, so a word's
answer is every class it can have (`book` is `N|V`); what the models add is
an answer for words no lexicon has.

| Model | Weights | Words not shown | Its core |
|---|---:|---:|---|
| `language` | 16,727 | | |
| `class-ces` | 130,460 | 93.1% | all 4,306 |
| `class-deu` | 133,971 | 90.1% | all 2,970 |
| `class-eng` | 173,423 | 80.8% | all 3,070 |

On held-out running text, in texts of twenty words: the language is right
for 160 of 160 Czech, 122 of 123 German and 200 of 200 English texts; of the
words the lexica have, 96.7%, 93.9% and 93.4% get exactly their classes.
Fused on the card the chain answers every one of 9,660 words as the pipeline
does, ten times faster.

A sample of a language is not all in that language: the script judges its
running text in pieces by function words, from closed lists, and leaves out
what is not (a tenth of the German sample, which quotes English and French
titles).

### Twenty languages (`langid.pl`)

From dictionary headwords only: 59% for one word, 78% for two, 94% for
five, 99% for ten. Russian and Bulgarian, Portuguese and Spanish, Danish and
Swedish are what single words are taken for each other.

### Czech adjectives (`adjectives-ces.pl`)

4,078 adjectives. Which degree a form is: 883 weights. Any degree into any
other: 8,142 weights, 96% from the positive to the comparative on adjectives
not shown, and the 27 exceptions right (*dobrý, lepší*). Back to the positive
is 86 to 89%: *-nější* comes from both *-ný* and *-ní*, and nothing in the
form says which.

### The Czech grammar (`grammar-ces.pl`)

One model per rule, 108 of them, trained in a minute and a half four at a
time. On words not shown 91 agree with their rule every time, the weakest
on 98.5%. The report is `examples/out/ces/REPORT.txt`.
