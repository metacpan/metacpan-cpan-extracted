use v5.36;
use utf8;
use Test::More;
use lib 'lib', 't/lib';
use Peta::NN::Backend;
use Peta::NN::Inference;
use Peta::NN::Model;
use Synthetic qw(inflect accent ending_class split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Each kind of model learns an invented rule set from pairs the rule set
# produced, and is then judged on words it has never seen.

# --- the rule sets themselves, so a wrong generator cannot pass for a model --
is(inflect('bravel'),  'bravle',  'inflect: consonant + el drops the e');
is(inflect('stodek'),  'stodku',  'inflect: -ek');
is(inflect('klomec'),  'klomče',  'inflect: -ec');
is(inflect('trika'),   'triko',   'inflect: -a');
is(inflect('prulo'),   'prulo',   'inflect: other vowels stay');
is(accent('patela'),   'patéla',  'accent: stop, vowel, liquid');
is(accent('badela'),   'badela',  'accent: no stop, no accent');
is(ending_class('bas'), 'sibilant', 'ending_class');

# --- edit: rewrite the end of the word ---------------------------------------
my ($train, $test) = split_pairs(\&inflect, 1500, 500, 21);
my $edit = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
$edit->fit($train, epochs => 6, batch => 16, lr => 0.01);
cmp_ok(scalar $edit->labels, '<=', 16, 'edit: 1500 pairs reduce to a handful of edits (' . $edit->labels . ')');
cmp_ok($edit->accuracy($test), '>=', 0.99, 'edit: at least 99% of 500 unseen words inflected exactly');
is(scalar $edit->predict('glomavel'), 'glomavle', 'edit: an unseen word, the rule with context');
my ($answer, $confidence) = $edit->predict('stoka');
is($answer, 'stoko', 'edit: list context returns the answer');
cmp_ok($confidence, '>', 0.9, 'edit: and a confidence');
is(scalar $edit->predict(''), inflect(''), 'edit: the empty string does not break it');

# --- rewrite: every character decided from its neighbours -------------------
($train, $test) = split_pairs(\&accent, 1000, 300, 22);
my $rewrite = Peta::NN::Model->new(kind => 'rewrite', radius => 1, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
$rewrite->fit($train, epochs => 10, batch => 16, lr => 0.01);
cmp_ok($rewrite->accuracy($test), '>=', 0.99, 'rewrite: at least 99% of 300 unseen words accented exactly');
is(scalar $rewrite->predict('kantalo'), accent('kantalo'), 'rewrite: an unseen word');
is(scalar $rewrite->predict(''), '', 'rewrite: the empty string');
ok(!eval { Peta::NN::Model->new(kind => 'rewrite')->fit([ [ 'abc', 'ab' ] ]); 1 }, 'rewrite: pairs of unequal length are refused');

# --- class: one label for the whole word ------------------------------------
($train, $test) = split_pairs(\&ending_class, 600, 300, 23);
my $class = Peta::NN::Model->new(kind => 'class', window => 2, layers => [ [embed => 4], [dense => 12], 'relu' ], seed => 4);
$class->fit($train, epochs => 6, batch => 16, lr => 0.01);
is_deeply([ sort $class->labels ], [qw(closed open sibilant)], 'class: the labels are the outputs seen');
cmp_ok($class->accuracy($test), '>=', 0.99, 'class: at least 99% of 300 unseen words classified');

# --- reading from the left --------------------------------------------------
my @initial = map { [ $_->[0], substr($_->[0], 0, 1) =~ /[bdg]/ ? 'voiced' : 'other' ] } @$train;
my $left = Peta::NN::Model->new(kind => 'class', window => 1, side => 'left', layers => [ [embed => 4] ], seed => 4);
$left->fit(\@initial, epochs => 6, batch => 16, lr => 0.02);
is($left->accuracy(\@initial), 1, 'class, side left: decided by the first character');

# --- an edit at the front of the word ---------------------------------------
# Invented rule: words beginning with a vowel take "n", the others "ne".
my $prefix = sub ($word) { ($word =~ /\A[aeiou]/ ? 'n' : 'ne') . $word };
my @front  = map { [ $_->[0], $prefix->($_->[0]) ] } @$train, map { [ "o$_->[0]", $prefix->("o$_->[0]") ] } @$train[ 0 .. 399 ];
my $front  = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 2, layers => [ [embed => 4], [dense => 8], 'relu' ], seed => 4);
$front->fit(\@front, epochs => 6, batch => 16, lr => 0.02);
is(scalar $front->predict('stokal'), 'nestokal', 'edit, side left: a prefix is added');
is(scalar $front->predict('odrak'),  'nodrak',   'edit, side left: and chosen by how the word begins');
my @undo = map { [ $_->[1], $_->[0] ] } @front;
my $back = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 3, layers => [ [embed => 4], [dense => 8], 'relu' ], seed => 4);
$back->fit(\@undo, epochs => 6, batch => 16, lr => 0.02);
is(scalar $back->predict('nestokal'), 'stokal', 'edit, side left: a prefix is cut');
ok(!eval { Peta::NN::Model->new(kind => 'class', side => 'auto'); 1 }, 'side auto is for edit models only');
my $chosen = Peta::NN::Model->new(kind => 'edit', side => 'auto', window => 2, layers => [ [embed => 4], [dense => 8], 'relu' ], seed => 4);
$chosen->fit(\@front, epochs => 6, batch => 16, lr => 0.02);
is($chosen->{side}, 'left', 'edit, side auto: a prefix task is taken from the left');
is(scalar $chosen->predict('stokal'), 'nestokal', 'edit, side auto: and learned');

# --- reading both ends ------------------------------------------------------
# The class depends on the first AND the last character; neither end alone decides it.
my $ends = sub ($word) { ($word =~ /\A[bdg]/ ? 'voiced' : 'other') . '-' . ($word =~ /[aeiou]\z/ ? 'open' : 'closed') };
my @ends = map { [ $_->[0], $ends->($_->[0]) ] } @$train;
my $both = Peta::NN::Model->new(kind => 'class', side => 'both', window => 1, layers => [ [embed => 4], [dense => 12], 'relu' ], seed => 4);
$both->fit(\@ends, epochs => 8, batch => 16, lr => 0.02);
is($both->accuracy([ map { [ $_->[0], $ends->($_->[0]) ] } @$test ]), 1, 'class, side both: decided by the first and the last character');

# Their model files, loaded by the inference leg, read and edit the same ends.
{
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    $front->export(file => "$dir/front.model");
    $both->export(file => "$dir/both.model");
    my $front_file = Peta::NN::Inference->load("$dir/front.model");
    my $both_file  = Peta::NN::Inference->load("$dir/both.model");
    my @words = map { $_->[0] } @$test[ 0 .. 99 ];
    is_deeply([ $front_file->predict_all(\@words) ], [ map { scalar $front->predict($_) } @words ], 'export: an edit at the front');
    is_deeply([ $both_file->predict_all(\@words) ],  [ map { scalar $both->predict($_) } @words ],  'export: a class read from both ends');
}

# --- one model, a parameter, edits at both ends -----------------------------
# Whatever follows input and output in a pair is a parameter: an opaque value
# the model learns to react to. Here: "wrap" puts the word in brackets chosen
# by its last letter, "strip" takes them off again, "keep" changes nothing.
# One network does all three.
my $wrap  = sub ($word) { $word =~ /[aeiou]\z/ ? "<$word>" : "[$word]" };
my @multi = map { my $w = $_->[0]; ([ $w, $wrap->($w), 'wrap' ], [ $wrap->($w), $w, 'strip' ], [ $w, $w, 'keep' ]) } @$train[ 0 .. 599 ];
my $multi = Peta::NN::Model->new(kind => 'edit', side => 'both', window => 2, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
$multi->fit(\@multi, epochs => 8, batch => 16, lr => 0.01);
is_deeply([ $multi->parameters ], [ [qw(keep strip wrap)] ], 'parameters: the model knows the values of its one parameter');
my @unseen = map { my $w = $_->[0]; ([ $w, $wrap->($w), 'wrap' ], [ $wrap->($w), $w, 'strip' ], [ $w, $w, 'keep' ]) } @$test[ 0 .. 199 ];
is($multi->accuracy(\@unseen), 1, 'parameters: one model wraps, strips and keeps 200 unseen words, each as asked');
is(scalar $multi->predict('stoka', 'wrap'), '<stoka>', 'parameters, edit at both ends: brackets go on both sides');
ok(!eval { $multi->predict('stoka'); 1 }, 'parameters: a call with too few is refused');
like($@, qr/takes 1 parameter, not 0/, '... saying how many the model takes');
ok(!eval { $multi->predict('stoka', 'wrap', 'twice'); 1 }, 'parameters: a call with too many is refused');
ok(!eval { $multi->predict('stoka', 'fold'); 1 }, 'parameters: a value the model was never trained with is refused');
like($@, qr/no value 'fold' .*keep strip wrap/, '... naming the values it has');
ok(!eval { Peta::NN::Model->new(kind => 'edit')->fit([ [ 'a', 'b', 't' ], [ 'c', 'd' ] ]); 1 }, 'parameters: every pair has the same number');
ok(!eval { Peta::NN::Model->new(kind => 'edit')->fit([]); 1 }, 'fit: no pairs, no model');

# The model does not judge its input: asked to strip a word that has no
# brackets, it answers something, and that is the caller's affair.
ok(defined scalar $multi->predict('stoka', 'strip'), 'parameters: nonsense that is well-formed gets an answer');

# Two parameters, each opaque and each with its own values. The first says
# which bracket, the second whether to double it.
my %open  = (round => '(', square => '[');
my %close = (round => ')', square => ']');
my $bracket = sub ($word, $shape, $count) { my $n = $count eq 'double' ? 2 : 1; ($open{$shape} x $n) . $word . ($close{$shape} x $n) };
my @two = map { my $w = $_->[0]; map { my $s = $_; map { [ $w, $bracket->($w, $s, $_), $s, $_ ] } qw(single double) } qw(round square) } @$train[ 0 .. 299 ];
my $two = Peta::NN::Model->new(kind => 'edit', side => 'both', window => 1, layers => [ [embed => 4], [dense => 12], 'relu' ], seed => 4);
$two->fit(\@two, epochs => 6, batch => 16, lr => 0.02);
is_deeply([ $two->parameters ], [ [qw(round square)], [qw(double single)] ], 'two parameters: each position has its own values');
is(scalar $two->predict('stoka', 'square', 'double'), '[[stoka]]', 'two parameters: both take effect');
is(scalar $two->predict('stoka', 'round', 'single'), '(stoka)', 'two parameters: another combination');
ok(!eval { $two->predict('stoka', 'double', 'square'); 1 }, 'two parameters: a value is known in its own position only');

# --- the full distribution --------------------------------------------------
my $spread = $class->distribution('stoka');
is_deeply([ sort map { $_->[0] } @$spread ], [qw(closed open sibilant)], 'distribution: every label of a class model');
my $total = 0;
$total += $_->[1] for @$spread;
cmp_ok(abs($total - 1), '<', 1e-9, 'distribution: the probabilities add up to 1');
is_deeply([ map { $_->[1] } @$spread ], [ sort { $b <=> $a } map { $_->[1] } @$spread ], 'distribution: most probable first');
my ($top, $sure) = $class->predict('stoka');
is_deeply($spread->[0], [ $top, $sure ], 'distribution: its first entry is what predict returns');
my $edits = $edit->distribution('stodek');
is($edits->[0][0], scalar $edit->predict('stodek'), 'distribution, edit: the answers are the resulting strings');
is(scalar(@$edits), scalar(keys %{ { map { $_->[0] => 1 } @$edits } }), 'distribution, edit: no string twice (edits with the same result are one answer)');
my $letters = $rewrite->distribution('kantalo');
is(scalar @$letters, 7, 'distribution, rewrite: one list per character');
is(join('', map { $_->[0][0] } @$letters), scalar $rewrite->predict('kantalo'), 'distribution, rewrite: the best of each is the prediction');

# Several strings pooled into one verdict: each is independent evidence.
my $one  = $class->distribution('stoka')->[0][1];
my $many = $class->pooled([qw(stoka trika stopa)]);
is($many->[0][0], 'open', 'pooled: three open words are open together');
cmp_ok($many->[0][1], '>=', $one, 'pooled: and more surely than one of them alone');
ok(!eval { $edit->inference->pooled(['stodek']); 1 }, 'pooled: only for class models');
{
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    $multi->save("$dir/multi.state");
    my $loaded = Peta::NN::Model->load("$dir/multi.state");
    is(scalar $loaded->predict('brodek', 'wrap'), scalar $multi->predict('brodek', 'wrap'), 'parameters: saved and loaded');
    $multi->export(file => "$dir/multi.model");
    my $shipped = Peta::NN::Inference->load("$dir/multi.model");
    is_deeply([ $shipped->parameters ], [ [qw(keep strip wrap)] ], 'export: the model file carries its parameter values');
    my @words = map { $_->[0] } @$test[ 0 .. 99 ];
    is_deeply([ $shipped->predict_all(\@words, 'wrap') ], [ map { scalar $multi->predict($_, 'wrap') } @words ], 'export: a parameter and two-ended edits');
    is(scalar $shipped->predict('[brodek]', 'strip'), 'brodek', 'export: another value of the parameter, same file');
    ok(!eval { $shipped->predict('brodek'); 1 }, 'export: a call without the parameter is refused');
}

# --- every backend learns the same task ------------------------------------
for my $backend (grep { $_ ne 'plain' } Peta::NN::Backend::available()) {
    my ($tr, $te) = split_pairs(\&inflect, 1500, 500, 21);
    my $other = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4, backend => $backend);
    $other->fit($tr, epochs => 6, batch => 16, lr => 0.01);
    is($other->net->backend, $backend, "$backend: the model trains on the backend asked for");
    cmp_ok($other->accuracy($te), '>=', 0.99, "$backend, edit: at least 99% of 500 unseen words inflected exactly");
    my $differ = grep { scalar($other->predict($_->[0])) ne scalar($edit->predict($_->[0])) } @$te;
    is($differ, 0, "$backend, edit: the same answers as the plain backend on all 500");
}

# --- definitions that cannot work -------------------------------------------
# --- a wider model, the same answers -------------------------------------------
for my $layers ([ [embed => 4], [dense => 6], 'relu' ], [ [embed => 4], [dense => 5], 'tanh', [dense => 7], 'relu' ]) {
    my $hidden = grep { ref && $_->[0] eq 'dense' } @$layers;
    my $narrow = Peta::NN::Model->new(kind => 'edit', window => 4, layers => $layers, seed => 2)->fit($train, epochs => 2, batch => 16);
    my @before = map { [ $narrow->predict($_->[0]) ] } @$test;
    my $weights = $narrow->net->n_params;
    is($narrow->widen(24), $narrow, "widen, $hidden hidden: returns the model");
    cmp_ok($narrow->net->n_params, '>', $weights, "widen, $hidden hidden: the model has more weights");
    my @after = map { [ $narrow->predict($_->[0]) ] } @$test;
    ok(!(grep { $before[$_][0] ne $after[$_][0] || abs($before[$_][1] - $after[$_][1]) > 1e-12 } 0 .. $#$test),
       "widen, $hidden hidden: every answer and every confidence is what it was");
    my $was = $narrow->accuracy($test);
    $narrow->tune($train, epochs => 6, batch => 16);
    cmp_ok($narrow->accuracy($test), '>', $was, "widen, $hidden hidden: the wider model learns on from where it was");
    is_deeply([ map { $_->[1] } grep { ref && $_->[0] eq 'dense' } @{ $narrow->{layers} } ], [ (24) x $hidden ], "widen, $hidden hidden: every hidden layer is that wide");
    my $still = $narrow->net->n_params;
    $narrow->widen(8);
    is($narrow->net->n_params, $still, "widen, $hidden hidden: a model that is wider already stays as it is");
}
ok(!eval { Peta::NN::Model->new(kind => 'edit')->widen(8); 1 }, 'widen: a model that has not been trained is refused');

# --- what a model cannot tell apart ---------------------------------------------
# With two characters read from the end, kabel and nebel are both "el": if
# they have different answers, no training gets both right.
my $blind = Peta::NN::Model->new(kind => 'edit', window => 2, layers => [ [embed => 4], [dense => 8], 'relu' ]);
my @look_alike = ([ 'kabel', 'kabel' ], [ 'nebel', 'nebeln' ], [ 'gabel', 'gabeln' ], [ 'tisch', 'tische' ], [ 'fisch', 'fische' ]);
$blind->fit(\@look_alike, epochs => 2);
my @same = $blind->indistinct(\@look_alike);
is_deeply([ sort map { $_->[0][0] } @same ], [qw(gabel kabel nebel)], 'indistinct: the pairs that are read as a pair with a different answer is read');
my ($kabel) = grep { $_->[0][0] eq 'kabel' } @same;
is($kabel->[2][1], $kabel->[2][0] . 'n', 'indistinct: each comes with a pair that has the other answer');
is(scalar(Peta::NN::Model->new(kind => 'edit', window => 5, layers => [ [embed => 4], [dense => 8], 'relu' ])->fit(\@look_alike, epochs => 2)->indistinct(\@look_alike)),
   0, 'indistinct: a window that takes in the difference tells them apart');

ok(!eval { Peta::NN::Model->new(kind => 'translate'); 1 }, 'unknown kind');
ok(!eval { Peta::NN::Model->new(kind => 'class', side => 'middle'); 1 }, 'unknown side');
ok(!eval { Peta::NN::Model->new(kind => 'class')->predict('x'); 1 }, 'predict before fit');

done_testing;
