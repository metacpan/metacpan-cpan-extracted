package Synthetic;

# Training data made by algorithm. Each task is a rule set we wrote down, so
# the rule set is at once the source of unlimited pairs and the judge of what
# a model learned. The rules are INVENTED: they have the shape of inflection
# and of diacritics restoration, they are not any real language's.

use v5.36;
use utf8;

use Exporter 'import';
use Peta::NN::RNG;

our @EXPORT_OK = qw(words inflect accent ending_class split_pairs);

my @ONSETS  = qw(b c d f g h j k l m n p r s t v z br dr kl pr st tr);
my @VOWELS  = qw(a e i o u);
my @CODAS   = ('', '', '', qw(k c l n r s t h m ek ec el));

# $count distinct pronounceable pseudo-words of two to four syllables.
sub words ($count, $seed) {
    my $rng = Peta::NN::RNG->new($seed);
    my %seen;
    while (keys %seen < $count) {
        my $word = join '', map { $ONSETS[ $rng->below(scalar @ONSETS) ] . $VOWELS[ $rng->below(scalar @VOWELS) ] }
            1 .. 2 + $rng->below(3);
        $word .= $CODAS[ $rng->below(scalar @CODAS) ];
        $seen{$word} = 1;
    }
    return [ sort keys %seen ];
}

# An inflection-shaped rule set: the first rule that matches rewrites the end
# of the word. Rules look one, two or three characters back, and one of them
# depends on what precedes the ending.
sub inflect ($word) {
    for ($word) {
        return $_ if s/([^aeiou])el\z/$1le/;    # consonant + el: the e drops
        return $_ if s/ek\z/ku/;
        return $_ if s/ec\z/če/;
        return $_ if s/a\z/o/;
        return $_ if s/([khg])\z/$1u/;
        return $_ if s/([cs])\z/$1i/;
        return $_ if s/([lmnrt])\z/$1e/;
    }
    return $word;                               # other vowels: unchanged
}

# A diacritics-shaped rule: a vowel is written long when a stop precedes it
# and a liquid or nasal follows. Same length in and out.
my %LONG = (a => 'á', e => 'é', i => 'í', o => 'ó', u => 'ú');

sub accent ($word) {
    $word =~ s/(?<=[ptk])([aeiou])(?=[lrn])/$LONG{$1}/g;
    return $word;
}

# A classification rule on the whole word's ending.
sub ending_class ($word) {
    return $word =~ /[aeiou]\z/ ? 'open'
         : $word =~ /[csz]\z/   ? 'sibilant'
         :                        'closed';
}

# [input, rule(input)] pairs, split into a training and a held-out part that
# share no word.
sub split_pairs ($rule, $train, $test, $seed) {
    my $all   = words($train + $test, $seed);
    my @pairs = map { [ $_, $rule->($_) ] } @{ Peta::NN::RNG->new($seed)->shuffle($all) };
    return ([ @pairs[ 0 .. $train - 1 ] ], [ @pairs[ $train .. $#pairs ] ]);
}

1;
