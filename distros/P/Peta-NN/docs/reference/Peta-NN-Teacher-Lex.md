# Peta::NN::Teacher::Lex

the rules of a PetaMem .lex grammar as teachers

## Synopsis

```perl
use Peta::NN::Teacher::Lex;
use Peta::NN::Teacher::Lexicon qw(path);

my ($rules, $broken) = Peta::NN::Teacher::Lex::rules(path('ces', 'grammar/ces_A.lex'));
print $rules->{'cesA-pms→cesA-cms'}->('chytrý');          # chytřejší

my $pairs = Peta::NN::Teacher::Lex::pairs($rules->{'A-m-1→A-f-1'}, \@adjectives);
$model->fit($pairs);
```

## Description

A model trained on these pairs learns what the rules do, their mistakes
included.

## Functions

### rules

`rules($file)`: `{ "FROM→TO" => sub }` for every rule of a grammar
file. In list context the second value is `{ "FROM→TO" => why }` for
the rules that could not be used.

### pairs

`pairs($rule, \@words)`: `[input, output]` for every word the rule gives
an answer for.

---

From the POD of `lib/Peta/NN/Teacher/Lex.pm`; change it there.
