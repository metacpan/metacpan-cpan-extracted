# Peta::NN::Data

records with named fields, to train models on and measure them by

## Synopsis

```perl
use Peta::NN::Data;

my $nouns = Peta::NN::Data->read('nouns.tsv', fields => [qw(singular gender plural listed)])
    ->derive(length => sub ($noun) { length $noun->{singular} })
    ->hold_out(0.1)
    ->mark(core => sub ($noun) { length $noun->{listed} });

printf "%d nouns, %d of them held out, %d the core\n",
    $nouns->count, $nouns->held->count, $nouns->marked('core')->count;

my $pairs = $nouns->shown->pairs(from => 'singular', to => 'plural', given => ['gender']);
```

## Description

A record is one thing a model is to learn something about, as a table of
named fields. A model is told which field it reads, which it answers and
which it is given beside, and takes its training pairs from the data.

Whether a record is *held out* of training follows from a field's value,
not from chance: the same record is on the same side on every run and every
machine, and records that share the value stay together. A record can also
be *marked* as belonging to a named group, such as a `core` a model has to
get right without exception.

`where`, `shown`, `held`, `marked` and `sample` give views of the same
records; nothing is copied.

## Methods

### new

`Peta::NN::Data->new(records => [ { ... }, ... ], fields => [ names ])`.

### read

`Peta::NN::Data->read($file, fields => [ names ])`: one record per
tab-separated line; lines that start with `#` are comments.

### records

The records, as a list of tables.

### count

How many records there are.

### fields

The names of the fields.

### values_of

`values_of($field)`: that field's value of every record.

### derive

`derive(name => sub ($record) { ... })`: a new field, worked out from
each record. Returns the data.

### where

`where(sub ($record) { ... })`: a view of the records the sub accepts.

### hold_out

`hold_out($share, by => $field, never => $mark)`: holds that share of
the records out of training, decided by the value of a field (the first one
unless named, or what a sub gives for a record). The records of the mark
`never` names are not held out. Returns the data. Data made with
`new` without `fields` has its fields in alphabetical order, so name the
field there.

### hold_out_if

`hold_out_if(sub ($record) { ... })`: holds out the records the sub
accepts, and no others. Returns the data.

### shown

A view of the records that are trained on.

### held

A view of the records that are held out.

### mark

`mark(name => sub ($record) { ... })`: names the group of records the
sub accepts. Returns the data.

### marks

The names of the groups.

### marked

`marked($name)`: a view of that group.

### is_marked

`is_marked($name, $record)`: whether the record is in that group.

### is_held

`is_held($record)`: whether the record is held out.

### sample

`sample($count)`: a view of at most that many records, the same ones every
time, spread evenly over the whole.

### pairs

`pairs(from => $field, to => $field, given => [ fields ])`: for each
record `[input, answer, parameters ...]`, as a model is trained on.

---

From the POD of `lib/Peta/NN/Data.pm`; change it there.
