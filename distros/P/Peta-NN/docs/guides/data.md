# Data

Models are trained on data and measured by it. Data is a list of *records*,
each a table of named *fields*: a noun with its gender and its plural, a
word with its language.

## Where data comes from

From a file of tab-separated lines:

```perl
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use Peta::NN::Data;

my $nouns = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)]);
printf "%d records with the fields %s\n", $nouns->count, join ', ', $nouns->fields;
```

```text
45218 records with the fields singular, gender, plural, listed
```

Or from records made in the program. This is how a *teacher* is used: any
sub that knows the answer, asked about every word.

```perl
sub shout ($word) { return uc($word) . '!' }               # the teacher

my @words = qw(haus hund katze maus vogel fisch baum blume);
my $made  = Peta::NN::Data->new(records => [ map { { word => $_, loud => shout($_) } } @words ]);
print join(' ', $made->values_of('loud')), "\n";
```

```text
HAUS! HUND! KATZE! MAUS! VOGEL! FISCH! BAUM! BLUME!
```

A teacher can be a rule set, a dictionary lookup, a call to another program.
A model learns what its teacher does, mistakes included, so a teacher that
is wrong is mended where it lives, not patched around in the script.

## New fields from old ones

```perl
$nouns->derive(letters => sub ($noun) { length $noun->{singular} });
my ($longest) = sort { $b->{letters} <=> $a->{letters} } $nouns->records;
print "$longest->{singular} ($longest->{letters})\n";
```

```text
schnittstellenanpassungseinrichtung (35)
```

## Holding out

A model is measured on records it was not shown. `hold_out` sets a share
aside:

```perl
$nouns->hold_out(0.1);
printf "%d shown, %d held out\n", $nouns->shown->count, $nouns->held->count;
```

```text
40586 shown, 4632 held out
```

Which records are held out is not left to chance. It follows from the value
of a field (the first one, unless `by` names another): the same record is on
the same side on every run and every machine, and records that share the
value stay together. That matters when one thing has several records: all
case forms of a noun have to be on one side, or the model has seen the noun.

```perl
my $by_gender = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)])
    ->hold_out(0.4, by => 'gender');
my %held = map { $_ => 1 } $by_gender->held->values_of('gender');
print 'held out, all of: ', join(', ', sort keys %held), "\n";
```

```text
held out, all of: masculine, neuter
```

## Marks: the records that have to be right

Some records matter more than others. The plural of *Haus* has to be right;
that of a compound nobody has written yet may be wrong now and then. `mark`
names a group of records, and a model's goal can then say what share of that
group it must answer:

```perl
$nouns->mark(core => sub ($noun) { length $noun->{listed} })       # the nouns a lexicon lists a plural for
      ->hold_out(0.1, never => 'core');
printf "%d nouns are the core, %d of those are held out\n", $nouns->marked('core')->count, $nouns->marked('core')->held->count;
```

```text
8691 nouns are the core, 0 of those are held out
```

`never => 'core'` keeps the marked records out of the held-out part: what
has to be right without exception is trained on. A model declared with
`goal => { unseen => 0.98, core => 1 }` is then trained until it answers 98%
of the held-out kind of record and every record of the core
([Models](models.md)).

## Views

`shown`, `held`, `marked`, `where` and `sample` give a narrower view of the
same records. Nothing is copied, and a view knows what the data knows.

```perl
my $neuter = $nouns->where(sub ($noun) { $noun->{gender} eq 'neuter' });
printf "%d neuter nouns, %d of them in the core; a sample of three: %s\n",
    $neuter->count, $neuter->marked('core')->count, join ', ', $neuter->sample(3)->values_of('singular');
```

```text
8927 neuter nouns, 1495 of them in the core; a sample of three: aas, getue, rankengewächs
```

## Look at it before you trust it

A file named for a language is not all in that language, and a column called
`plural` holds what somebody put there. Before training on a new source,
print some of it, and check it by something that does not depend on the
model. `examples/wordclass.pl` does this for its samples of running text:
the German sample turned out to quote English and French book titles by the
dozen, which had been trained and measured as German. A count of function
words per piece, from closed lists, found them.

The methods are listed in the [reference](../reference/Peta-NN-Data.md).
