use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib', 't/lib';
use Peta::NN::Backend;
use Peta::NN::Chain qw(chain pooled chosen fixed);
use Peta::NN::Data;
use Peta::NN::Inference;
use Peta::NN::Model;
use Peta::NN::Pipeline;
use Synthetic qw(inflect ending_class split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Models put together into a model: parts by name, parameters by name, and
# what comes out is again something to put together. What a chain answers
# is held against the pipeline one would have wired by hand.

my %LAYERS = (layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
my %TRAIN  = (epochs => 6, batch => 16, lr => 0.01);
my ($train, $test) = split_pairs(\&inflect, 1200, 200, 51);
my @words = map { $_->[0] } @$train;
my @fresh = map { $_->[0] } @$test;
my @forms = (@words, map { inflect($_) } @words);
my %suffix = (near => '-ta', far => '-tam');

my $inflect = Peta::NN::Model->new(kind => 'edit', window => 4, %LAYERS)->fit($train, %TRAIN);
my $mark    = Peta::NN::Model->new(kind => 'edit', window => 2, given => ['mark'], %LAYERS)
    ->fit([ map { my $w = $_; map { [ $w, $w . $suffix{$_}, $_ ] } qw(near far) } @forms[ 0 .. 799 ] ], %TRAIN);
my $tone    = Peta::NN::Model->new(kind => 'edit', window => 2, given => [qw(mark tone)], %LAYERS)
    ->fit([ map { my $w = $_; map { my $m = $_; map { [ $w, $w . ($_ eq 'high' ? uc $suffix{$m} : $suffix{$m}), $m, $_ ] } qw(high low) } qw(near far) } @forms[ 0 .. 399 ] ], %TRAIN);
my $tag     = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)->fit([ map { [ $_, ending_class($_) eq 'open' ? 'near' : 'far' ] } @words ], %TRAIN);
my $class   = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)->fit([ map { [ $_, ending_class($_) ] } @words ], %TRAIN);
my $double  = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)->fit([ map { [ $_, $_ . substr($_, -1) ] } @words ], %TRAIN);
my $front   = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 2, %LAYERS)->fit([ map { [ $_, "x$_" ] } @words ], %TRAIN);
my $unnamed = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)->fit([ map { [ $_, "$_-a", 'near' ] } @words[ 0 .. 99 ] ], %TRAIN);

# --- in series, parameters by name ----------------------------------------------
my $series = chain(inflect => $inflect, mark => $mark);
isa_ok($series, 'Peta::NN::Chain', 'chain(...)');
is_deeply([ $series->parts ], [qw(inflect mark)], 'its parts, in order');
is_deeply([ $series->given ], ['mark'], 'what a part is given and no earlier part answers is an argument of the chain');
is(scalar $series->predict('stodek', mark => 'far'), 'stodku-tam', 'predict: the second part works on the first one\'s answer');
my $wired = Peta::NN::Pipeline->new(models => { inflect => $inflect, mark => $mark }, steps => [ { model => 'inflect' }, { model => 'mark', params => [ \0 ] } ]);
is_deeply([ $series->predict_all(\@fresh, mark => 'near') ], [ $wired->predict_all(\@fresh, 'near') ], 'predict_all: what the pipeline wired by hand answers');
my ($answer, $confidence) = $series->predict('stodek', mark => 'far');
cmp_ok($confidence, '==', ($wired->predict('stodek', 'far'))[1], 'in list context also the confidence');
is($series->n_params, $inflect->inference->n_params + $mark->inference->n_params, 'it has the weights of its models');
ok(!eval { $series->predict('stodek'); 1 }, 'an argument missing is refused');
like($@, qr/this chain takes mark => \.\.\./, '... saying what it takes');
ok(!eval { $series->predict('stodek', tone => 'far'); 1 }, 'an argument by another name is refused');
ok(!eval { $series->predict('stodek', 'far'); 1 }, 'an argument without its name is refused');

# Two parts given the same name are given the same value; names in the order they are first needed.
my $both = chain(mark => $mark, tone => $tone);
is_deeply([ $both->given ], [qw(mark tone)], 'two parts given `mark`: one argument for both');
is(scalar $both->predict('stoka', tone => 'high', mark => 'near'), scalar $tone->predict(scalar $mark->predict('stoka', mark => 'near'), mark => 'near', tone => 'high'),
   '... and both get its value, whatever order the caller names them in');

# What a part is given can be settled where the chain is made.
my $settled = chain(inflect => $inflect, mark => fixed($mark, mark => 'far'));
is_deeply([ $settled->given ], [], 'fixed: what is settled is no argument of the chain');
is(scalar $settled->predict('stodek'), 'stodku-tam', 'fixed: and the model is given it every time');
ok(!eval { chain(mark => fixed($mark, tone => 'high')); 1 }, 'fixed: something the model is not given is refused');

# --- a chain in a chain --------------------------------------------------------------
my $longer = chain(first => $series, double => $double);
is_deeply([ $longer->parts ], [qw(inflect mark double)], 'a chain as a part: its parts become parts');
is_deeply([ $longer->given ], ['mark'], '... and its arguments arguments');
is(scalar $longer->predict('stodek', mark => 'near'), scalar $double->predict(scalar $series->predict('stodek', mark => 'near')), '... and it answers as the two one after the other');
my $deeper = chain(all => $longer, again => chain(more => $double->inference));
is_deeply([ $deeper->parts ], [qw(inflect mark double more)], 'chains in chains in chains');
ok(!eval { chain(a => $series, b => $series); 1 }, 'the same part twice is refused');
like($@, qr/two parts called 'inflect'/, '... by name');

# --- parts that classify ----------------------------------------------------------------
my $told = chain(mark => $tag, suffix => $mark);
is_deeply([ $told->given ], [], 'a part named as a later parameter: its answer is the value, and the chain needs no argument');
is_deeply([ $told->answers ], ['mark'], 'the parts that classify');
is(scalar $told->predict('stoka'), 'stoka-ta', 'an open word is marked near, by the answer of the part before');
is($told->run(['stodek'])->[0]{answers}{mark}, 'far', 'run: the answers of the parts that classify, under their names');

my $routed = chain(ending => $class, change => chosen(ending => { open => $double, '*' => $inflect }));
is_deeply([ $routed->models ], [qw(ending change-other change-open)], 'chosen: one model per answer, called part-answer');
my $by_hand = Peta::NN::Pipeline->new(models => { class => $class, double => $double, inflect => $inflect },
    steps => [ { name => 'ending', model => 'class', classify => 1 }, { model => { ending => { open => 'double', '*' => 'inflect' } } } ]);
is_deeply([ $routed->predict_all(\@fresh) ], [ $by_hand->predict_all(\@fresh) ], 'chosen: each string by its own route, as wired by hand');

my $pooling = chain(ending => pooled($class), change => chosen(ending => { open => $double, '*' => $inflect }));
my @open    = grep { ending_class($_) eq 'open' } @fresh;
my @closed  = grep { ending_class($_) ne 'open' } @fresh;
my $texts   = $pooling->run_texts([ [ @open[ 0 .. 8 ], $closed[0] ], [ @closed[ 1 .. 9 ] ] ]);
is_deeply([ map { $_->{answers}{ending} } @{ $texts->[0] } ], [ ('open') x 10 ], 'pooled: a text has one answer, for all its strings');
is($texts->[0][9]{text}, $closed[0] . substr($closed[0], -1), '... and a string goes the way of its text');

# --- a file ---------------------------------------------------------------------------------
my $dir = tempdir(CLEANUP => 1);
is($pooling->save("$dir/pooling.chain", name => 'a text, and its words'), $pooling, 'save returns the chain');
my $loaded = Peta::NN::Chain->load("$dir/pooling.chain");
is_deeply([ $loaded->parts ], [ $pooling->parts ], 'from its file: the parts');
{
    my ($got, $want) = map { $_->run_texts([ \@fresh ])->[0] } $loaded, $pooling;
    is_deeply([ map { [ $_->{text}, $_->{answers} ] } @$got ], [ map { [ $_->{text}, $_->{answers} ] } @$want ], 'from its file: the same answers');
    my ($off) = sort { $b <=> $a } map { abs($got->[$_]{confidence} - $want->[$_]{confidence}) } 0 .. $#$got;
    cmp_ok($off, '<', 1e-6, 'from its file: the confidences, as far as 32-bit weights carry them');
    is_deeply($pooling->stored, { map { $_ => 32 } $pooling->models }, 'stored: models trained here go into the file with 32 bits');
}
is($loaded->info->{name}, 'a text, and its words', 'from its file: what it says of itself');
$both->save("$dir/both.chain");
$settled->save("$dir/settled.chain");
is(scalar Peta::NN::Chain->load("$dir/settled.chain")->predict('stodek'), 'stodku-tam', 'from its file: what was fixed is fixed');
is(scalar Peta::NN::Chain->load("$dir/both.chain")->predict('stoka', mark => 'far', tone => 'low'), scalar $both->predict('stoka', mark => 'far', tone => 'low'), 'from its file: arguments by name');

$mark->export(file => "$dir/mark.model", bits => 8);
# Small where the answers hold: judged by data, model by model.
{
    my $data = Peta::NN::Data->new(records => [ map { my $w = $_; map { { word => $w, which => $_, marked => $w . $suffix{$_} } } qw(near far) } @fresh ]);
    my $suffixer = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'marked', given => ['which'], reads => { end => 2 }, %LAYERS)->train($data, train => \%TRAIN);
    my $small = chain(inflect => $inflect, suffix => $suffixer);
    $small->save("$dir/small.chain", small => $data);
    is($small->stored->{inflect}, 32, 'small: a model that does not say what it reads of the data stays at 32 bits');
    is($small->stored->{suffix}, 8, 'small: one that answers the data the same with 8-bit weights is stored with 8');
    my $back = Peta::NN::Chain->load("$dir/small.chain");
    is($back->model('suffix')->info->{bits}, 8, 'small: and that is what is in the file');
    is_deeply([ $back->predict_all(\@fresh, which => 'far') ], [ $small->predict_all(\@fresh, which => 'far') ], 'small: with the same answers');
    $back->save("$dir/again.chain", small => $data);
    is_deeply($back->stored, { inflect => undef, suffix => undef }, 'stored: models that came from a file go in as they are');
}
my $single = Peta::NN::Chain->load("$dir/mark.model");
is_deeply([ $single->parts ], ['mark'], 'a model\'s file loads as a chain of that one part, called as the file');
is(scalar $single->predict('stoka', mark => 'far'), scalar Peta::NN::Inference->load("$dir/mark.model")->predict('stoka', mark => 'far'), '... which answers as the model');
is(scalar chain(inflect => $inflect, mark => "$dir/mark.model")->predict('stodek', mark => 'far'), 'stodku-tam', 'a part given as a model file\'s path');
ok(!eval { Peta::NN::Chain->load("$dir/nowhere.chain"); 1 }, 'a file that is not there is refused');
open my $junk, '>', "$dir/junk.chain" or die $!; print $junk "not a chain\n"; close $junk;
ok(!eval { Peta::NN::Chain->load("$dir/junk.chain"); 1 }, 'a file that is no chain is refused');

# --- fused: the same function --------------------------------------------------------------
is($series->on('cpu'), $series, 'on returns the chain');
is_deeply([ $series->predict_all(\@fresh, mark => 'near') ], [ $wired->predict_all(\@fresh, 'near') ], 'fused on the cpu: the same answers');
is_deeply($pooling->on('cpu')->run_texts([ \@fresh ]), $pooling->on('pipeline')->run_texts([ \@fresh ]), 'fused on the cpu, pooled and chosen: the same records');
SKIP: {
    skip 'no graphics card to compute on in this perl', 1 if !Peta::NN::Backend::try('gpu');
    is_deeply([ $loaded->on('gpu')->predict_all(\@fresh) ], [ $pooling->on('pipeline')->predict_all(\@fresh) ], 'fused on the card, from its file: the same answers');
}
my $unfusable = chain(front => $front, inflect => $inflect);
is(scalar $unfusable->predict('stodek'), scalar $inflect->predict('xstodek'), 'a model that does not fuse is a part like any other');
ok(!eval { $unfusable->on('cpu'); 1 }, '... but such a chain is not run fused');
like($@, qr/does not fuse/, '... and says why');
$unfusable->save("$dir/unfusable.chain");
is(scalar Peta::NN::Chain->load("$dir/unfusable.chain")->predict('stodek'), scalar $unfusable->predict('stodek'), '... and is saved and loaded all the same');

# --- chains that cannot be ------------------------------------------------------------------
my @BAD = (
    [ 'nothing',                                  [] ],
    [ 'a part without a name',                    [$inflect] ],
    [ 'a part that is no model',                  [ inflect => [ 1, 2 ] ] ],
    [ 'a model whose parameters have no names',   [ mark => $unnamed ] ],
    [ 'pooling a model that rewrites',            [ inflect => pooled($inflect) ] ],
    [ 'choosing by a part that is not there',     [ change => chosen(ending => { open => $double }) ] ],
    [ 'choosing by a part that rewrites',         [ ending => $inflect, change => chosen(ending => { open => $double }) ] ],
    [ 'choosing between a classifier and a rewriter', [ ending => $class, change => chosen(ending => { open => $double, '*' => $tag }) ] ],
    [ 'choosing between models given different things', [ ending => $class, change => chosen(ending => { open => $double, '*' => $mark }) ] ],
);
for my $case (@BAD) {
    my ($what, $parts) = @$case;
    ok(!eval { chain(@$parts); 1 }, "refused: $what");
}
ok(!eval { $series->on('abacus'); 1 }, 'refused: answering from somewhere that is not');
ok(!eval { $series->model('nowhere'); 1 }, 'refused: a model the chain does not have');

done_testing;
