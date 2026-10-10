# Peta::NN::Teacher::Lexicon

the PetaMem lexica as a source of words

## Synopsis

```perl
use Peta::NN::Teacher::Lexicon qw(lexicon wiktionary words path);

my $german  = lexicon('deu', 'petamem');
my @plurals = words($german, 'Nc-p');
print "neuter\n" if $german->{haus}{Ncns};

my $czech      = wiktionary('ces');
my @adjectives = words($czech, 'Af');

my $rules = Peta::NN::Teacher::Lex::rules(path('ces', 'grammar/ces_A.lex'));
```

## Description

The lexica are read where they are, every time; this project keeps no copy
of them. `$Peta::NN::Teacher::Lexicon::ROOT` is where they are
(`/opt/PetaMem/lexica`, or what `PETAMEM_LEXICA` names).

A word list that turns out too weak to train from is mended in the lexica
themselves, so that there is one place where the truth is kept.

## Functions

All are exported on request.

### path

`path($language, @more)`: the path of a language's directory, or of
something in it.

### entries

`entries(@files)`: `{ word => { tag => 1 } }` for every entry of the
files.

### lexicon

`lexicon($language, $name)`: the entries of one lexicon of a language.

### wiktionary

`wiktionary($language)`: the entries of a language's Wiktionary-derived
lexicon, read from the archive.

### words

`words($entries, @tags)`: the single lower-case words that carry at least
one of the tags, or all of them; sorted.

---

From the POD of `lib/Peta/NN/Teacher/Lexicon.pm`; change it there.
