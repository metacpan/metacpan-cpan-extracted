use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use Storable ();
use lib 'lib', 't/lib';
use Peta::NN;
use Peta::NN::Backend;
use Peta::NN::Inference;
use Peta::NN::Model;
use Synthetic qw(inflect accent split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# A trained model leaves the training leg in two forms: a state file that
# the training leg reads back, and a model file for the inference leg.

my $dir = tempdir(CLEANUP => 1);

# --- a network's state file reproduces it exactly ---------------------------
my @xor = ([ [ 0, 0 ], 0 ], [ [ 0, 1 ], 1 ], [ [ 1, 0 ], 1 ], [ [ 1, 1 ], 0 ]);
my $net = Peta::NN->new(input => 2, layers => [ [dense => 6], 'tanh', [dense => 2] ], seed => 1, backend => 'plain');
$net->train(data => \@xor, epochs => 60, batch => 4);
my $back = Peta::NN->load($net->save("$dir/xor.net") && "$dir/xor.net");
is_deeply([ map { $back->forward($_->[0]) } @xor ], [ map { $net->forward($_->[0]) } @xor ],
    'net: saved and loaded, the outputs are identical to the last bit');
is($back->n_params, $net->n_params, 'net: same number of parameters');

my $state = $net->state;
pop @{ $state->{weights}[0] };
ok(!eval { Peta::NN->from_state($state); 1 }, 'net: weights that do not fit the definition are refused');

# --- a model's state file ---------------------------------------------------
my ($train, $test) = split_pairs(\&inflect, 700, 200, 31);
my $edit = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4, backend => 'plain');
$edit->fit($train, epochs => 5, batch => 16, lr => 0.01);
my $edit_back = Peta::NN::Model->load($edit->save("$dir/edit.state") && "$dir/edit.state");
is_deeply([ map { [ $edit_back->predict($_->[0]) ] } @$test ], [ map { [ $edit->predict($_->[0]) ] } @$test ],
    'model: saved and loaded, answers and confidences are identical');

# A state file carries no backend.
for my $backend (grep { $_ ne 'plain' } Peta::NN::Backend::available()) {
    my $moved = Peta::NN::Model->load("$dir/edit.state", backend => $backend);
    is($moved->net->backend, $backend, "model: trained on plain, loaded on $backend");
    my $differ = grep { scalar($moved->predict($_->[0])) ne scalar($edit->predict($_->[0])) } @$test;
    is($differ, 0, 'model: and gives the same answers there');
}

# --- the model's answers follow its weights ---------------------------------
my $growing = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
my @per_epoch;
$growing->fit($train, epochs => 4, batch => 16, lr => 0.01, on_epoch => sub ($epoch, $loss) { push @per_epoch, $growing->accuracy($test); 1 });
cmp_ok($per_epoch[-1], '>', $per_epoch[0], 'asked during training, the model answers with the weights of that moment');
is($growing->accuracy($test), $per_epoch[-1], 'and afterwards with the final ones');

# --- model files ------------------------------------------------------------
my ($accent_train, $accent_test) = split_pairs(\&accent, 400, 100, 32);
my $rewrite = Peta::NN::Model->new(kind => 'rewrite', radius => 1, layers => [ [embed => 6], [dense => 16], 'tanh' ], seed => 4);
$rewrite->fit($accent_train, epochs => 4, batch => 16, lr => 0.01);

$edit->export(file => "$dir/inflect.model");
$rewrite->export(file => "$dir/accent.model");
my $inflect = Peta::NN::Inference->load("$dir/inflect.model");
my $accent  = Peta::NN::Inference->load("$dir/accent.model");

is($inflect->kind, 'edit', 'model file: the kind');
is($inflect->n_params, $edit->net->n_params, 'model file: every parameter is in it');
is_deeply([ $inflect->labels ], [ $edit->labels ], 'model file: the labels');
cmp_ok(-s "$dir/inflect.model", '<', 4.5 * $edit->net->n_params + 2000,
    'model file: about four bytes per parameter (' . (-s _) . ' bytes for ' . $edit->net->n_params . ' parameters)');
like(Peta::NN::Inference::engine(), qr/\A(?:pdl|plain)\z/, 'the inference leg names its engine (' . Peta::NN::Inference::engine() . ')');

# Weights are stored as 32-bit floats, so answers must agree and confidences
# nearly so.
for my $case ([ 'edit', $edit, $inflect, $test ], [ 'rewrite', $rewrite, $accent, $accent_test ]) {
    my ($name, $model, $loaded, $pairs) = @$case;
    my ($differ, $drift) = (0, 0);
    for my $word (map { $_->[0] } @$pairs) {
        my ($want, $want_p) = $model->predict($word);
        my ($got,  $got_p)  = $loaded->predict($word);
        $differ++ if $got ne $want;
        $drift = abs($got_p - $want_p) if abs($got_p - $want_p) > $drift;
    }
    is($differ, 0, "model file, $name: gives the model's answer on all " . @$pairs . ' unseen words');
    cmp_ok($drift, '<', 1e-4, "model file, $name: confidences agree to four places");
}
is(scalar $inflect->predict(''), scalar $edit->predict(''), 'model file: the empty string');
is(scalar $accent->predict(''), '', 'model file, rewrite: the empty string');

# Many strings in one pass give what one string at a time gives.
my @some = (map({ $_->[0] } @$accent_test[ 0 .. 49 ]), '');
is_deeply([ $accent->predict_all(\@some) ], [ map { scalar $accent->predict($_) } @some ],
    'predict_all agrees with predict, the empty string included');
is_deeply([ $accent->predict_all([]) ], [], 'predict_all of nothing is nothing');


# --- files that are not what they claim to be --------------------------------
# Each kind of file carries its own marker; the loader of one refuses the others.
ok(!eval { Peta::NN::Inference->load("$dir/edit.state"); 1 }, 'a training state is not a model file');
like($@, qr/is not a Peta::NN model file/, '... and the refusal says so');
ok(!eval { Peta::NN::Inference->load("$dir/xor.net"); 1 }, 'a network state is not a model file');
ok(!eval { Peta::NN::Model->load("$dir/inflect.model"); 1 }, 'a model file is not a training state');
ok(!eval { Peta::NN->load("$dir/edit.state"); 1 }, 'a model\'s training state is not a network state');

open my $text, '>', "$dir/text.model" or die $!;
print {$text} "not a Storable file at all\n";
close $text;
ok(!eval { Peta::NN::Inference->load("$dir/text.model"); 1 }, 'a file Storable cannot read is refused');
like($@, qr/cannot be read as a Peta::NN model file/, '... with a message, not a crash');
ok(!eval { Peta::NN::Inference->load("$dir/missing.model"); 1 }, 'a missing file is refused');

# A model file damaged in one place each time: every one must be refused
# with the reason, before anything is computed from it.
my $good = Storable::retrieve("$dir/inflect.model");
my @damage = (
    [ 'a kind that does not exist',        qr/unknown kind/,                 sub ($m) { $m->{kind} = 'translate' } ],
    [ 'a side that does not exist',        qr/unknown side/,                 sub ($m) { $m->{side} = 'middle' } ],
    [ 'a window of zero',                  qr/window is not a positive/,     sub ($m) { $m->{window} = 0 } ],
    [ 'no labels',                         qr/no labels/,                    sub ($m) { $m->{labels} = [] } ],
    [ 'a label too many',                  qr/one output per label/,         sub ($m) { push @{ $m->{labels} }, '0:x' } ],
    [ 'a label that is not an edit',       qr/not an edit/,                  sub ($m) { $m->{labels}[0] = 'plural' } ],
    [ 'a token index used twice',          qr/token index/,                  sub ($m) { my ($a, $b) = sort keys %{ $m->{vocab} }; $m->{vocab}{$a} = $m->{vocab}{$b} } ],
    [ 'a token index beyond the table',    qr/leave gaps/,                   sub ($m) { my ($a) = sort keys %{ $m->{vocab} }; $m->{vocab}{$a} = 9999 } ],
    [ 'an embedding table cut short',      qr/one row per token/,            sub ($m) { substr($m->{layers}[0]{weights}[0], -4) = '' } ],
    [ 'half a weight',                     qr/not stored as the file says/,  sub ($m) { substr($m->{layers}[1]{weights}[0], -2) = '' } ],
    [ 'a dense layer that does not fit',   qr/does not fit/,                 sub ($m) { substr($m->{layers}[1]{weights}[1], -4) = '' } ],
    [ 'a layer of unknown type',           qr/unknown type/,                 sub ($m) { $m->{layers}[2]{type} = 'softplus' } ],
    [ 'no layers',                         qr/no layers/,                    sub ($m) { $m->{layers} = [] } ],
    [ 'a layout this version does not read', qr/layout 1, and this version reads layout 2/, sub ($m) { delete $m->{layout} } ],
    [ 'an unknown weight size',            qr/unknown weight size/,          sub ($m) { $m->{bits} = 16 } ],
    [ 'weights not stored as the file says', qr/not stored as the file says/, sub ($m) { $m->{bits} = 8 } ],
    [ 'parameters that are not tables',    qr/not a list of tables/,         sub ($m) { $m->{params} = [ 'dative' ] } ],
    [ 'a weight that is not a number',     qr/not a finite number/,          sub ($m) { substr($m->{layers}[1]{weights}[0], 0, 4) = pack 'f<', 9**9**9 } ],
    [ 'a weight that is NaN',              qr/not a finite number/,          sub ($m) { substr($m->{layers}[1]{weights}[0], 0, 4) = pack 'f<', -sin(9**9**9) } ],
);
for my $case (@damage) {
    my ($what, $reason, $break) = @$case;
    my $broken = Storable::dclone($good);
    $break->($broken);
    Storable::nstore($broken, "$dir/broken.model");
    ok(!eval { Peta::NN::Inference->load("$dir/broken.model"); 1 }, "malformed: $what is refused");
    like($@, qr/broken\.model is a malformed model: .*$reason/, '... naming the file and the reason');
}

# Nothing in a model file becomes an object: reading it runs no code from it.
{
    package Bomb;
    our $WENT_OFF = 0;
    sub DESTROY { $WENT_OFF++ }
}
my $trap = Storable::dclone($good);
$trap->{vocab} = bless { %{ $trap->{vocab} } }, 'Bomb';
Storable::nstore($trap, "$dir/trap.model");
$Bomb::WENT_OFF = 0;                                   # the copies made above have been destroyed by now
undef $trap;
my $before = $Bomb::WENT_OFF;
my $loaded = eval { Peta::NN::Inference->load("$dir/trap.model") };
is($Bomb::WENT_OFF, $before, 'an object smuggled into a model file is read as plain data: its class is never involved');
ok($loaded && scalar($loaded->predict('stodek')) eq scalar($inflect->predict('stodek')), '... and the model works as the data it is');

# --- 8-bit weights, and what a file says of itself ---------------------------
$edit->export(file => "$dir/inflect8.model", bits => 8, name => 'Invented inflection',
              description => 'the rule set of t/lib/Synthetic.pm', source => 'Synthetic::inflect',
              fidelity => { all => $edit->accuracy($test) });
my $small = Peta::NN::Inference->load("$dir/inflect8.model");
cmp_ok(-s "$dir/inflect8.model", '<', 0.45 * -s "$dir/inflect.model",
    'bits 8: the file is well under half the 32-bit one (' . (-s "$dir/inflect8.model") . ' against ' . (-s "$dir/inflect.model") . ' bytes)');
is($small->n_params, $inflect->n_params, 'bits 8: every weight is there');
my $agree = grep { scalar($small->predict($_->[0])) eq scalar($inflect->predict($_->[0])) } @$test;
cmp_ok($agree / @$test, '>=', 0.98, "bits 8: it answers as the 32-bit file on $agree of " . @$test . ' unseen words');
ok(!eval { $edit->export(file => "$dir/x.model", bits => 16); 1 }, 'bits: only 8 and 32 are offered');

my $info = $small->info;
is($info->{name}, 'Invented inflection', 'info: the name given at export');
is($info->{source}, 'Synthetic::inflect', 'info: the source');
is($info->{bits}, 8, 'info: the weight size');
is($info->{kind}, 'edit', 'info: the kind');
is($info->{weights}, $edit->net->n_params, 'info: the number of weights');
like($info->{layers}, qr/\Aembed 6, dense 24, relu, dense \d+\z/, "info: the layers ($info->{layers})");
like($info->{reads}, qr/the last 4 characters/, 'info: what it reads');
cmp_ok(abs($info->{created} - time), '<', 3600, 'info: when it was made');
cmp_ok(abs($info->{fidelity}{all} - $edit->accuracy($test)), '<', 1e-12, 'info: the fidelity recorded');
is($inflect->info->{name}, undef, 'info: a file exported without a name has none');
is($inflect->info->{bits}, 32, 'info: and 32-bit weights by default');

# A coarse file grows back into a trainable model too.
my $from8 = Peta::NN::Model->from_model("$dir/inflect8.model");
is(scalar(grep { scalar($from8->predict($_->[0])) ne scalar($small->predict($_->[0])) } @$test), 0,
    'bits 8: from_model gives a trainable model with the same answers');

# The script that prints all this.
# The library is given to the script as it is to this test: an installed script
# finds it by itself, one in a distribution being tested does not.
my $printed = qx{$^X -Ilib bin/peta-nn-info $dir/inflect8.model $dir/text.model 2>&1};
like($printed, qr/name\s+Invented inflection/, 'peta-nn-info: prints the name');
like($printed, qr/8-bit weights/, 'peta-nn-info: and the weight size');
like($printed, qr/created\s+\d{4}-\d\d-\d\d \d\d:\d\d UTC/, 'peta-nn-info: and the date');
like($printed, qr/fidelity\s+all \d+\.\d%/, 'peta-nn-info: and the fidelity');
like($printed, qr/text\.model\n\s+NOT A USABLE MODEL/, 'peta-nn-info: a file that is no model is reported, not crashed on');
isnt($? >> 8, 0, 'peta-nn-info: and makes the exit status non-zero');

# --- a model file grows back into a trainable model --------------------------
my $revived = Peta::NN::Model->from_model("$dir/inflect.model");
is($revived->net->n_params, $edit->net->n_params, 'from_model: the same network, parameter for parameter');
is_deeply([ $revived->labels ], [ $edit->labels ], 'from_model: the same labels');
is_deeply($revived->{layers}, $edit->{layers}, 'from_model: the hidden layers are read back from the file');
is(scalar(grep { scalar($revived->predict($_->[0])) ne scalar($inflect->predict($_->[0])) } @$test), 0,
    'from_model: it answers as the model file does, on all ' . @$test . ' unseen words');

# Training goes on from where the file left off. The rule is changed for one
# group of words: those in -s now take -u, where they took -i.
my $changed  = sub ($word) { $word =~ /s\z/ ? $word . 'u' : inflect($word) };
my @new_rule = map { [ $_->[0], $changed->($_->[0]) ] } @$train;
my @in_s     = grep { $_->[0] =~ /s\z/ } @$test;
my @others   = grep { $_->[0] !~ /s\z/ } @$test;
cmp_ok(scalar @in_s, '>=', 8, 'tune: there are unseen words in -s to judge by (' . @in_s . ')');
is(scalar(grep { scalar($revived->predict($_->[0])) eq $changed->($_->[0]) } @in_s), 0, 'tune: before, none of them takes -u');
$revived->tune(\@new_rule, epochs => 4, batch => 16, lr => 0.01);
cmp_ok(scalar(grep { scalar($revived->predict($_->[0])) eq $changed->($_->[0]) } @in_s) / @in_s, '>=', 0.9,
    'tune: after four epochs on the changed rule, unseen words in -s take -u');
cmp_ok(scalar(grep { scalar($revived->predict($_->[0])) eq $_->[1] } @others) / @others, '>=', 0.97,
    'tune: and what did not change is still known');
is_deeply([ $revived->labels ], [ $edit->labels ], 'tune: the labels are the same ones');
is(scalar $inflect->predict($in_s[0][0]), inflect($in_s[0][0]), 'tune: the model file it came from is untouched');

# A tuned model exports again, and the new file holds what was learned.
$revived->export(file => "$dir/inflect2.model");
is(scalar Peta::NN::Inference->load("$dir/inflect2.model")->predict($in_s[0][0]), $changed->($in_s[0][0]), 'tune: exported again');

# A training state can be tuned as well.
my $resumed = Peta::NN::Model->load("$dir/edit.state");
$resumed->tune(\@new_rule, epochs => 4, batch => 16, lr => 0.01);
cmp_ok(scalar(grep { scalar($resumed->predict($_->[0])) eq $changed->($_->[0]) } @in_s) / @in_s, '>=', 0.9,
    'tune: a loaded training state goes on training too');

# What tune cannot do.
ok(!eval { $revived->tune([ [ 'stodek', 'stodkovitý' ] ]); 1 }, 'tune: a pair that needs an answer the model does not have is refused');
like($@, qr/needs? an answer this model does not have .*fit from scratch/s, '... and says what it takes');
ok(!eval { Peta::NN::Model->new(kind => 'edit')->tune($train); 1 }, 'tune: an untrained model is refused');
ok(!eval { Peta::NN::Model->from_model("$dir/edit.state"); 1 }, 'from_model: a training state is not a model file');
ok(!eval { Peta::NN::Model->from_model("$dir/broken.model"); 1 }, 'from_model: a malformed model file is refused');

# --- the inference leg alone, in a fresh interpreter ------------------------
# Code points are printed, not characters, so no output encoding is involved.
# Each interpreter runs on whatever engine it finds, and again with the
# plain loops forced. Nothing of the training leg may be loaded.
my @words  = map { $_->[0] } @$accent_test[ 0 .. 19 ];
my $script = 'my $m = Peta::NN::Inference->load(shift);'
           . 'print join "|", map { join ".", map { ord } split //, scalar $m->predict($_) } @ARGV;'
           . 'print "\n", join ",", Peta::NN::Inference::engine(), grep { m{^Peta/} } sort keys %INC';
my $expect = join '|', map { join '.', map { ord } split //, scalar $rewrite->predict($_) } @words;

my @interpreters = ($^X);
for my $other (grep { defined } 'perl', $ENV{OTHER_PERL}) {
    push @interpreters, $other if !grep { $_ eq $other } @interpreters;
}
for my $perl (@interpreters) {
    for my $force ('', 'PETA_NN_ENGINE=plain ') {
        my $output = qx{$force$perl -Ilib -MPeta::NN::Inference -e '$script' $dir/accent.model @words 2>&1};
        my ($answers, $loaded) = split /\n/, $output, 2;
        my ($engine, @peta) = split /,/, $loaded // '';
        is($answers, $expect, "alone under $perl, engine $engine: same answers");
        is("@peta", 'Peta/NN/Codec.pm Peta/NN/Inference.pm', "alone under $perl, engine $engine: only the inference leg was loaded");
        is($engine, 'plain', "alone under $perl: PETA_NN_ENGINE=plain is honoured") if $force;
    }
}

done_testing;
