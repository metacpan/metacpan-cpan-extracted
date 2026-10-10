#!/usr/bin/env pperl
# German nouns: Apfel -> Äpfel -> Äpfeln, and back from Äpfel to Apfel.
#
#   pperl examples/nouns-deu.pl
#   PETA_NN_WORKERS=4 pperl examples/nouns-deu.pl      the four models side by side
#
# Shows:  small models that each do one limited thing, put together into
#         chains; models trained until a goal is met; a chain saved as one
#         file, loaded, and run fused.
# Needs:  examples/out/deu-noun/nouns.tsv, which ships (examples/nouns-deu-data.pl
#         writes it from the PetaMem lexica). Everything is lower case, as the
#         data is.
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use lib 'lib';

use Peta::NN::Chain qw(chain train_together);
use Peta::NN::Data;
use Peta::NN::Model;

# === Settings ====================================================================

my $OUT      = 'examples/out/deu-noun';
my $HELD_OUT = 0.1;         # the share of the nouns no model is shown
my $HEAD     = 3;           # a noun that this many longer nouns end in is a head (hammer, in vorschlaghammer)
my @CASES    = qw(nominative genitive dative accusative);
my %TRAINING = (train => { batch => 128 }, search => { scale => [ 16, 512 ], start => 64 }, budget => { seconds => 3600 });
my @ASK      = qw(apfel haus mann frau hund stadt buch auto vogel zeitung garten kind hammer kammer vorschlaghammer museum);

# === Data ========================================================================

# The plural in two steps. The first changes vowels and nothing else (mann ->
# männ), the second rewrites the end (männ -> männer). This is the form in
# between: the singular with the vowels its plural has.
my %UMLAUT = (a => 'ä', o => 'ö', u => 'ü');
sub with_plural_vowels ($noun) {
    my ($singular, $plural) = @$noun{qw(singular plural)};
    my $between = $singular;
    for my $at (0 .. length($singular) - 1) {
        last if $at >= length $plural;
        my ($from, $to) = (substr($singular, $at, 1), substr($plural, $at, 1));
        next if $from eq $to;
        last if ($UMLAUT{$from} // '') ne $to;
        substr($between, $at, 1) = $to;
    }
    return $between;
}

# The case forms of a plural: only the dative differs, by an -n that is added
# unless the plural already ends in -n or -s.
sub case_form ($plural, $case) { return $case eq 'dative' && $plural !~ /[ns]\z/ ? $plural . 'n' : $plural }

my $nouns = Peta::NN::Data->read("$OUT/nouns.tsv", fields => [qw(singular gender plural listed)])
    ->derive(between => \&with_plural_vowels);

# The core: the nouns the lexica list a plural for, and the heads, which other
# nouns end in. What is particular about a plural belongs to the head and
# nothing generalises to it, so the core is always trained on, and every noun
# of it has to come out right.
my %is_noun = map { $_ => 1 } $nouns->values_of('singular');
my %ends_in;
for my $word (keys %is_noun) {
    $is_noun{$_} and $ends_in{$_}++ for map { substr $word, $_ } 1 .. length($word) - 3;
}
$nouns->mark(core => sub ($noun) { length $noun->{listed} || ($ends_in{ $noun->{singular} } // 0) >= $HEAD })
      ->hold_out($HELD_OUT, never => 'core');

# Every plural in every case, of the same nouns, on the same sides and with the same core.
my %held = map { $_ => 1 } $nouns->held->values_of('singular');
my %core = map { $_ => 1 } $nouns->marked('core')->values_of('singular');
my $forms = Peta::NN::Data->new(
    fields  => [qw(singular gender plural case form)],
    records => [ map { my $noun = $_; map { { %$noun{qw(singular gender plural)}, case => $_, form => case_form($noun->{plural}, $_) } } @CASES } $nouns->records ],
)->hold_out_if(sub ($form) { $held{ $form->{singular} } })->mark(core => sub ($form) { $core{ $form->{singular} } });

printf "%d nouns: %d the core, %d held out, %d with an umlaut in the plural\n\n", $nouns->count, $nouns->marked('core')->count,
    $nouns->held->count, $nouns->where(sub ($noun) { $noun->{between} ne $noun->{singular} })->count;

# === Models ======================================================================

# Each is told the gender (or the case) by name, and knows nothing of what a
# gender is: to a model it is a value that goes with different answers.
my %model = (
    # Which vowel changes. The vowel is in the head, the head is the end of the
    # word: read from the end, and hammer and vorschlaghammer look alike.
    umlaut => Peta::NN::Model->new(kind => 'edit', from => 'singular', to => 'between', given => ['gender'], reads => { end => 8 },
                                   goal => { unseen => 0.99, core => 1 }, %TRAINING),
    # What the end of the word becomes, once its vowels have changed.
    ending => Peta::NN::Model->new(kind => 'edit', from => 'between', to => 'plural', given => ['gender'], reads => { end => 7 },
                                   goal => { unseen => 0.98, core => 1 }, %TRAINING),
    # The way back in one step. It reads eleven characters, the least that
    # tell frühschichten (schicht) from geschichten (geschichte).
    singular => Peta::NN::Model->new(kind => 'edit', from => 'plural', to => 'singular', given => ['gender'], reads => { end => 11 },
                                     goal => { unseen => 0.965, core => 1 }, %TRAINING),
    # The case form of a plural: a small matter, fitted once.
    case => Peta::NN::Model->new(kind => 'edit', from => 'plural', to => 'form', given => ['case'], reads => { end => 3 },
                                 layers => [ [ embed => 6 ], [ dense => 16 ], 'relu' ], train => { epochs => 20, batch => 32, lr => 0.01 }),
);

my $plural  = chain(umlaut => $model{umlaut}, ending => $model{ending});      # apfel -> äpfel
my $decline = chain(plural => $plural, case => $model{case});                 # apfel -> äpfeln
my $back    = chain(singular => $model{singular});                            # äpfel -> apfel

# === Training ====================================================================

# The four have nothing to do with each other and are trained side by side.
train_together(\%model, { case => $forms, '*' => $nouns });
print $plural->report, $back->report;

# === Measuring ===================================================================

my %score = (
    plural  => $plural->score($nouns, from => 'singular', to => 'plural'),
    decline => $decline->score($forms, from => 'singular', to => 'form'),
    back    => $back->score($nouns, from => 'plural', to => 'singular'),
);
printf "%-28s %10s %10s\n", '', 'not shown', 'the core';
for my $row ([ 'singular to plural', 'plural' ], [ 'singular to a plural case', 'decline' ], [ 'plural to singular', 'back' ]) {
    printf "%-28s %9.1f%% %9.1f%%\n", $row->[0], map { 100 * $score{ $row->[1] }{$_} } qw(unseen core);
}

print "\nstep by step to the dative plural (* a noun no model was shown):\n";
for my $word (@ASK) {
    my ($noun) = $nouns->where(sub ($n) { $n->{singular} eq $word })->records or next;
    my @named  = (gender => $noun->{gender});
    printf "  %-16s %-9s -> %-16s -> %-17s -> %-18s%s\n", $word, $noun->{gender}, scalar $model{umlaut}->predict($word, @named),
        scalar $plural->predict($word, @named), scalar $decline->predict($word, @named, case => 'dative'), $nouns->is_held($noun) ? ' *' : '';
}
print "\nand back (where two nouns share a plural, only one of them can come back):\n";
printf "  %-16s %-9s -> %s\n", @$_, scalar $back->predict($_->[0], gender => $_->[1])
    for [ äpfel => 'masculine' ], [ häuser => 'neuter' ], [ frühschichten => 'feminine' ], [ geschichten => 'feminine' ], [ museen => 'neuter' ], [ autos => 'neuter' ];

# === Using it ====================================================================

# One file per chain, each model with 8-bit weights if it then still answers
# every noun as before.
my %judge = (case => $forms, '*' => $nouns);
$plural->save("$OUT/plural.chain", small => \%judge, name => 'German nouns: singular to plural');
$decline->save("$OUT/decline.chain", small => \%judge, name => 'German nouns: singular to a plural case');
$back->save("$OUT/singular.chain", small => \%judge, name => 'German nouns: plural to singular');
print "\n";
for my $saved ([ 'plural.chain', $plural ], [ 'decline.chain', $decline ], [ 'singular.chain', $back ]) {
    my ($file, $chain) = @$saved;
    printf "saved %-15s %7d bytes, weights of %s\n", $file, -s "$OUT/$file", join ', ', map { "$_ in " . $chain->stored->{$_} . ' bits' } $chain->models;
}

# What a program that uses a chain does; it needs the file and nothing of the above.
my $loaded = Peta::NN::Chain->load("$OUT/decline.chain");
printf "\nfrom the file: %s\n", join ', ', map { scalar $loaded->predict($_, gender => 'neuter', case => 'dative') } qw(haus buch kind);
if (eval { $loaded->on('gpu') }) {
    my @all = map { $_->{singular} } $nouns->where(sub ($noun) { $noun->{gender} eq 'neuter' })->records;
    printf "fused on the graphics card: %d neuter nouns in one go, the first: %s\n", scalar @all,
        join ', ', ($loaded->predict_all(\@all, gender => 'neuter', case => 'dative'))[ 0 .. 2 ];
}
