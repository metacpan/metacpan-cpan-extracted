#!/usr/bin/env pperl
# From a rule to a model, end to end, in one file.
#
#   pperl examples/inflect.pl
#
# Shows:  a teacher (any sub from string to string), data made with it, a
#         model trained on the data, measured on words it never saw, saved,
#         and loaded again by a program that only uses it.
# Needs:  nothing beside Peta::NN.
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use lib 'lib';

use Peta::NN::Chain qw(chain);
use Peta::NN::Data;
use Peta::NN::Model;
use Peta::NN::RNG;

# === Settings ====================================================================

my $WORDS    = 3000;                               # words the teacher is asked about
my $HELD_OUT = 0.3;                                # the share of them the model is not shown
my $FILE     = 'examples/out/inflect.chain';
my @ASK      = qw(glomavel stodek klomec trika brus prulo);

# === Data ========================================================================

# The teacher: the inflection of an invented language. The first rule that
# matches rewrites the end of the word. Any sub will do in its place: the
# rules of a real language, a dictionary lookup, a program that knows.
sub inflect ($word) {
    for ($word) {
        return $_ if s/([^aeiou])el\z/$1le/;       # consonant + el: the e drops
        return $_ if s/ek\z/ku/;
        return $_ if s/ec\z/če/;
        return $_ if s/a\z/o/;
        return $_ if s/([khg])\z/$1u/;
        return $_ if s/([cs])\z/$1i/;
        return $_ if s/([lmnrt])\z/$1e/;
    }
    return $word;                                  # other vowels: unchanged
}

# Words to ask it about: pronounceable pseudo-words of two to four syllables.
sub pseudo_words ($count) {
    my @onsets = qw(b c d f g h j k l m n p r s t v z br dr kl pr st tr);
    my @vowels = qw(a e i o u);
    my @codas  = ('', '', '', qw(k c l n r s t h m ek ec el));
    my $rng    = Peta::NN::RNG->new(7);
    my %word;
    while (keys %word < $count) {
        my $syllables = join '', map { $onsets[ $rng->below(scalar @onsets) ] . $vowels[ $rng->below(scalar @vowels) ] } 1 .. 2 + $rng->below(3);
        $word{ $syllables . $codas[ $rng->below(scalar @codas) ] } = 1;
    }
    return sort keys %word;
}

my $words = Peta::NN::Data->new(records => [ map { { word => $_, inflected => inflect($_) } } pseudo_words($WORDS) ])
    ->hold_out($HELD_OUT);

# === Model =======================================================================

# It rewrites the end of a word, and reads its last four characters to decide.
my $model = Peta::NN::Model->new(
    kind  => 'edit',
    from  => 'word',
    to    => 'inflected',
    reads => { end => 4 },
    train => { epochs => 8, batch => 16, lr => 0.01, on_epoch => sub ($epoch, $loss) { printf "epoch %2d  loss %.4f\n", $epoch, $loss; 1 } },
);

# === Training ====================================================================

$model->train($words);
printf "\ntrained on %d words: %d weights, %d edits learned\n", $words->shown->count, $model->net->n_params, scalar $model->labels;

# === Measuring ===================================================================

printf "words it was not shown, inflected as the teacher would: %.1f%% of %d\n\n", 100 * $model->score($words)->{unseen}, $words->held->count;
for my $word (@ASK) {
    my ($answer, $confidence) = $model->predict($word);
    printf "  %-9s -> %-9s  (teacher: %-9s confidence %.2f)\n", $word, $answer, inflect($word), $confidence;
}

# === Using it ====================================================================

# Saved as one file; with 8-bit weights if it then still answers the same.
mkdir 'examples/out';
chain(inflect => $model)->save($FILE, small => $words, name => 'Invented inflection', description => 'the rule set of examples/inflect.pl');
printf "\nsaved %s, %d bytes\n", $FILE, -s $FILE;

# What a program that uses the model does; it needs nothing of the above.
my $inflect = Peta::NN::Chain->load($FILE);
printf "from the file: %s -> %s\n", $_, scalar $inflect->predict($_) for @ASK[ 0, 1 ];
