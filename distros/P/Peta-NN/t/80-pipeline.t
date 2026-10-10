use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib', 't/lib';
use Peta::NN::Inference;
use Peta::NN::Model;
use Peta::NN::Pipeline;
use Synthetic qw(inflect ending_class split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Small models, each doing one limited thing, put together: in series, and
# routed by a classifier. The rules are the invented ones of Synthetic.pm.

my %LAYERS = (layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
my %TRAIN  = (epochs => 6, batch => 16, lr => 0.01);
my ($train, $test) = split_pairs(\&inflect, 1200, 200, 51);
my @words = map { $_->[0] } @$train;
my @fresh = map { $_->[0] } @$test;

# inflect: the invented inflection, no parameter.
my $inflect = Peta::NN::Model->new(kind => 'edit', window => 4, %LAYERS)->fit($train, %TRAIN);

# mark: a suffix chosen by the parameter. It works on whatever it is given,
# inflected forms included, so it is trained on those too.
my %suffix = (near => '-ta', far => '-tam');
my $mark_rule = sub ($word, $which) { $word . $suffix{$which} };
my @forms = (@words, map { inflect($_) } @words);
my $mark  = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)
    ->fit([ map { my $w = $_; map { [ $w, $mark_rule->($w, $_), $_ ] } qw(near far) } @forms[ 0 .. 799 ] ], %TRAIN);

# class: how a word ends. open words get one treatment, the others another.
my $class = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)->fit([ map { [ $_, ending_class($_) ] } @words ], %TRAIN);
my $double = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)
    ->fit([ map { [ $_, $_ . substr($_, -1) ] } @words ], %TRAIN);          # repeats the last letter
my $upper  = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 2, %LAYERS)
    ->fit([ map { [ $_, "x$_" ] } @words ], %TRAIN);                        # puts an x in front

# --- in series --------------------------------------------------------------
my $series = Peta::NN::Pipeline->new(
    models => { inflect => $inflect, mark => $mark },
    steps  => [ { model => 'inflect' }, { model => 'mark', params => [ \0 ] } ],
);
is($series->arguments, 1, 'series: the pipeline takes the one argument its steps refer to');
is(scalar $series->predict('stodek', 'far'), 'stodku-tam', 'series: the second model works on the first one\'s answer');
my @got  = $series->predict_all(\@fresh, 'near');
my @want = map { $mark_rule->(inflect($_), 'near') } @fresh;
cmp_ok(scalar(grep { $got[$_] eq $want[$_] } 0 .. $#fresh) / @fresh, '>=', 0.97, 'series: at least 97% of 200 unseen words come out as the two rules in a row would give');
is_deeply([ $series->predict_all(\@fresh, 'near') ], [ map { scalar $series->predict($_, 'near') } @fresh ], 'series: many strings at once give what one at a time gives');

my ($answer, $confidence) = $series->predict('stodek', 'far');
my @trace = $series->trace('stodek', 'far');
is(scalar @trace, 2, 'trace: one entry per step');
is_deeply([ map { $_->[0] } @trace ], [qw(inflect mark)], 'trace: the models in order');
is_deeply($trace[1][1], ['far'], 'trace: the parameters a step was given');
is($trace[1][2], $trace[0][3], 'trace: a step\'s input is the step before\'s output');
cmp_ok(abs($confidence - $trace[0][4] * $trace[1][4]), '<', 1e-12, 'the confidence of a chain is the product of its steps\'');

# --- routed -----------------------------------------------------------------
my $routed = Peta::NN::Pipeline->new(
    models => { class => $class, double => $double, upper => $upper },
    steps  => [
        { name => 'ending', model => 'class', classify => 1 },
        { model => { ending => { open => 'double', '*' => 'upper' } } },
    ],
);
is($routed->arguments, 0, 'routed: no arguments');
is(scalar $routed->predict('stoka'), 'stokaa', 'routed: an open word goes to the model for open words');
is(scalar $routed->predict('stodek'), 'xstodek', 'routed: any other class goes to the model listed for "*"');
my @routes = $routed->trace('stoka');
is($routes[0][3], 'open', 'routed: the classifying step answers the class');
is($routes[1][2], 'stoka', 'routed: and passes the string on unchanged');
my @mixed = $routed->predict_all(\@fresh);
my @ideal = map { ending_class($_) eq 'open' ? $_ . substr($_, -1) : "x$_" } @fresh;
cmp_ok(scalar(grep { $mixed[$_] eq $ideal[$_] } 0 .. $#fresh) / @fresh, '>=', 0.97, 'routed: at least 97% of 200 unseen words, each by its own route');

# An earlier step's answer as a later step's parameter.
my $tagger = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)
    ->fit([ map { [ $_, ending_class($_) eq 'open' ? 'near' : 'far' ] } @words ], %TRAIN);
my $fed = Peta::NN::Pipeline->new(
    models => { tag => $tagger, mark => $mark },
    steps  => [ { name => 'which', model => 'tag', classify => 1 }, { model => 'mark', params => [ { answer => 'which' } ] } ],
);
is(scalar $fed->predict('stoka'), 'stoka-ta', 'an answer as a parameter: open words are marked near');
is(scalar $fed->predict('stodek'), 'stodek-tam', 'an answer as a parameter: the others far');

# --- a text judged as one ---------------------------------------------------
my $pooling = Peta::NN::Pipeline->new(
    models => { class => $class, double => $double, upper => $upper },
    steps  => [
        { name => 'ending', model => 'class', classify => 1, pool => 1 },
        { model => { ending => { open => 'double', '*' => 'upper' } } },
    ],
);
my @open   = grep { ending_class($_) eq 'open' } @fresh;
my @closed = grep { ending_class($_) ne 'open' } @fresh;
my $texts  = $pooling->run_texts([ [ @open[ 0 .. 8 ], $closed[0] ], [ @closed[ 1 .. 9 ], $open[9] ], [] ]);
is_deeply([ map { scalar @$_ } @$texts ], [ 10, 10, 0 ], 'pooled: the records of each text');
is_deeply([ map { $_->{answers}{ending} } @{ $texts->[0] } ], [ ('open') x 10 ], 'pooled: nine open words and one other are an open text, the other word included');
is($texts->[0][9]{text}, $closed[0] . substr($closed[0], -1), 'pooled: and so that word goes the way of its text');
isnt($texts->[1][9]{answers}{ending}, 'open', 'pooled: an open word in a text of others is not open');
is($pooling->run([ $closed[0] ])->[0]{answers}{ending}, scalar $class->predict($closed[0]), 'pooled: a string run alone is a text of one');
cmp_ok($texts->[0][0]{confidence}, '==', $class->pooled([ @open[ 0 .. 8 ], $closed[0] ])->[0][1] * ($double->predict($open[0]))[1], 'pooled: the confidence is the text\'s share times the later steps\'');
ok(!eval { Peta::NN::Pipeline->new(models => { double => $double }, steps => [ { name => 'd', model => 'double', pool => 1 } ]); 1 }, 'refused when built: pooling in a step that does not classify');

# --- from model files -------------------------------------------------------
my $dir = tempdir(CLEANUP => 1);
$inflect->export(file => "$dir/inflect.model");
$mark->export(file => "$dir/mark.model", bits => 8);
my $shipped = Peta::NN::Pipeline->new(
    models => { inflect => "$dir/inflect.model", mark => "$dir/mark.model" },
    steps  => [ { model => 'inflect' }, { model => 'mark', params => ['far'] } ],
);
is(scalar $shipped->predict('stodek'), 'stodku-tam', 'model files: a pipeline built from paths loads them');
is($shipped->arguments, 0, 'model files: a fixed parameter is not an argument');

# --- pipelines that cannot work ---------------------------------------------
my %models = (inflect => $inflect, mark => $mark, class => $class);
my @BAD = (
    [ 'no steps',                              [] ],
    [ 'a step without a model',                [ {} ] ],
    [ 'a model the pipeline does not have',    [ { model => 'decline' } ] ],
    [ 'routing by a step that is not there',   [ { model => { ending => { open => 'mark' } } } ] ],
    [ 'routing to a model that is not there',  [ { name => 'c', model => 'class', classify => 1 }, { model => { c => { open => 'nowhere' } } } ] ],
    [ 'a parameter from a step that is not there', [ { model => 'mark', params => [ { answer => 'which' } ] } ] ],
    [ 'a classifying step without a name',     [ { model => 'class', classify => 1 } ] ],
    [ 'a parameter of an unknown form',        [ { model => 'mark', params => [ ['far'] ] } ] ],
);
for my $case (@BAD) {
    my ($what, $steps) = @$case;
    ok(!eval { Peta::NN::Pipeline->new(models => \%models, steps => $steps); 1 }, "refused when built: $what");
}
ok(!eval { $series->predict('stodek'); 1 }, 'refused when called: an argument missing');
like($@, qr/takes 1 argument after the string, not 0/, '... saying how many it takes');
ok(!eval { $series->predict('stodek', 'nowhere'); 1 }, 'refused when called: a parameter value the model does not have');
my $narrow = Peta::NN::Pipeline->new(
    models => { class => $class, double => $double },
    steps  => [ { name => 'ending', model => 'class', classify => 1 }, { model => { ending => { open => 'double' } } } ],
);
ok(!eval { $narrow->predict('stodek'); 1 }, 'refused when called: an answer the routing table has no model for');

done_testing;
