use v5.36;
use utf8;
use Test::More;
use lib 'lib', 't/lib';
use Peta::NN::Job;
use Peta::NN::RNG;
use Synthetic qw(inflect words);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The job harness on the invented inflection: given thresholds, it has to
# train one model until it meets them, giving it room when it needs room.

my @regular = map { [ $_, inflect($_) ] } @{ words(900, 41) };
# Three words that follow no rule. Nothing generalises to them; they can only be retained.
my %irregular  = (brodek => 'brodci', stoka => 'stoky', klomec => 'klomcové');
my @exceptions = map { [ $_, $irregular{$_} ] } sort keys %irregular;
my @pairs      = ((grep { !$irregular{ $_->[0] } } @regular), @exceptions);

my %JOB = (
    model        => { kind => 'edit', window => 5 },
    pairs        => \@pairs,
    always_train => sub ($pair) { exists $irregular{ $pair->[0] } },
    subsets      => {
        exceptions => { of => 'train', where => sub ($pair) { exists $irregular{ $pair->[0] } } },
        'in -ek'   => { where => sub ($pair) { $pair->[0] =~ /ek\z/ } },
    },
    fidelity => { all => 0.97, exceptions => 1.00, 'in -ek' => 0.90 },
    search   => { scale => [ 2, 64 ], depth => [1] },
    train    => { epochs => 30, batch => 16, lr => 0.02, lr_decay => 0.95, patience => 10 },
);

# --- the split --------------------------------------------------------------
my $job = Peta::NN::Job->new(%JOB);
my %where;
for my $part (qw(train validation test)) {
    $where{ $_->[0] }{$part} = 1 for $job->part($part);
}
ok(!(grep { keys %$_ > 1 } values %where), 'split: no word is in two parts');
is(scalar(keys %where), scalar @pairs, 'split: every pair is in a part');
ok(!(grep { !$where{$_}{train} } keys %irregular), 'split: what must always be trained on is in the training part');
cmp_ok(scalar(() = $job->part('validation')), '>', 100, 'split: a validation part of useful size');

# --- a job that can be met --------------------------------------------------
my $model  = $job->run;
my $result = $job->result;
my @stages = $job->attempts;
my @first  = grep { !$_->{confirmation} } @stages;
note $job->report;

ok($result->{met}, 'the job trains a model until it meets every threshold');
ok($result->{confirmed}, 'and confirms its size on a second seed');
cmp_ok($result->{fidelity}{all}, '>=', 0.97, 'validation: the overall threshold holds');
is($result->{fidelity}{exceptions}, 1, 'validation: every exception is retained');
cmp_ok($result->{test}{all}, '>=', 0.94, 'the test part, measured once, is in line with validation');
is(scalar $model->predict('brodek'), 'brodci', 'the returned model has the exception');
is(scalar $model->predict('prostibus'), 'prostibusi', 'and the rule, on a word it never saw');
cmp_ok(scalar @stages, '<=', 40, 'the run limit is respected (' . @stages . ' stages)');
ok(!(grep { !defined $_->{ms} || $_->{ms} <= 0 } @stages), 'every stage has a measured time per item');

# One model, trained on: it starts at the smallest width and only ever grows.
is($first[0]{scale}, 2, 'training starts at the smallest width allowed');
ok(!(grep { $first[$_]{scale} < $first[ $_ - 1 ]{scale} } 1 .. $#first), 'the model is never made smaller, or swapped for another');
ok(scalar(grep { $_->{stage} =~ /\Awidened to/ } @first), 'a model that got no closer was widened');
is($first[-1]{scale}, $result->{scale}, 'the model returned is the one that was trained, at the width it reached');
ok($first[-1]{passed} && !(grep { $_->{passed} } @first[ 0 .. $#first - 1 ]), 'training stopped at the first stage that met the thresholds');
ok(!(grep { $_->{ended} eq 'met' && !$_->{passed} && !$_->{over} } @stages), 'a stage that ended as met did meet them');

# Getting closer is what counts: a later stage of the same model is never
# further from the thresholds than the one before it.
my $distance = sub ($stage) { my $d = 0; for (keys %{ $JOB{fidelity} }) { my $gap = $JOB{fidelity}{$_} - $stage->{fidelity}{$_}; $d += $gap if $gap > 0 } $d };
ok(!(grep { $first[$_]{scale} == $first[ $_ - 1 ]{scale} && $distance->($first[$_]) > $distance->($first[ $_ - 1 ]) + 1e-12 } 1 .. $#first),
   'training a model on never leaves it further from the thresholds than it was');

like($job->report, qr/the model meets the thresholds/, 'the report states the outcome');
like($job->report, qr/on the test part, measured once/, 'and the test measurement');

# --- the same job gives the same training --------------------------------------
my $again = Peta::NN::Job->new(%JOB);
$again->run;
is_deeply([ map { [ @$_{qw(stage scale epochs passed)} ] } $again->attempts ], [ map { [ @$_{qw(stage scale epochs passed)} ] } @stages ],
    'the same job runs the same stages with the same outcomes');

# --- a job that cannot be met ------------------------------------------------
# With one character of context, -ek (the e drops: -ku) cannot be told from
# -ak (which only adds u): words in -k cannot all be right.
my $blind = Peta::NN::Job->new(%JOB, model => { kind => 'edit', window => 1 },
                               subsets => { 'in -k' => { where => sub ($pair) { $pair->[0] =~ /k\z/ } } },
                               fidelity => { all => 0.50, 'in -k' => 0.999 },
                               search => { scale => [ 2, 16 ], depth => [1] });
my $closest = $blind->run;
ok(!$blind->result->{met}, 'an impossible job is reported as not met');
ok(defined $closest && defined $closest->predict('stodek'), 'and still returns the model, as close as it got');
is($blind->result->{scale}, 16, 'after the model was widened as far as allowed');
ok(!(grep { $_->{confirmation} } $blind->attempts), 'what did not get there is not confirmed');
like($blind->report, qr/does NOT meet the thresholds/, 'the report says so');

# --- what must be retained gets more weight ------------------------------------
# One hidden unit cannot hold the rule and three exceptions; before the model
# is widened, the exceptions are given more weight.
my $narrow = Peta::NN::Job->new(%JOB, search => { scale => [ 1, 32 ], depth => [1] });
$narrow->run;
my @names = map { $_->{stage} } grep { !$_->{confirmation} } $narrow->attempts;
my ($weighed) = grep { $names[$_] =~ /\Amore weight on: exceptions/ } 0 .. $#names;
my ($widened) = grep { $names[$_] =~ /\Awidened to/ } 0 .. $#names;
ok(defined $weighed, 'a model stuck short of what it must retain is trained with more weight on that');
ok(defined $widened && $weighed < $widened, 'and only then widened');
ok($narrow->result->{met}, 'and gets there');

# --- a cost budget ------------------------------------------------------------
my $roomy = Peta::NN::Job->new(%JOB, budget => { params => 400 });
$roomy->run;
ok($roomy->result->{met} && $roomy->result->{params} <= 400, 'a model that gets there inside the budget is returned (' . $roomy->result->{params} . ' parameters)');

my $tight = Peta::NN::Job->new(%JOB, budget => { params => 60 });
$tight->run;
my @tight = $tight->attempts;
ok(!$tight->result->{met}, 'a budget too small for the job is not met');
like($tight[-1]{over}, qr/parameters/, 'the stage that went over the parameter budget is marked');
ok(!(grep { $_->{over} } @tight[ 0 .. $#tight - 1 ]), 'and the model is widened no further');

my $hurried = Peta::NN::Job->new(%JOB, budget => { runs => 2 });
$hurried->run;
is(scalar(() = $hurried->attempts), 2, 'the run limit ends a job');
is($hurried->result->{stopped}, 'run limit reached', 'and the result says why it stopped');

# --- what the model cannot tell apart is not asked of it -------------------------
# Two words that must be retained and that end alike but go different ways:
# with three characters read, "zabrodek" is "dek" as "brodek" is, and no
# model gets both right. The job says so, and does not chase them.
my %twin = (zabrodek => 'zabrodkové');
my $twins = Peta::NN::Job->new(%JOB, model => { kind => 'edit', window => 3 },
    pairs        => [ @pairs, map { [ $_, $twin{$_} ] } sort keys %twin ],
    always_train => sub ($pair) { exists $irregular{ $pair->[0] } || exists $twin{ $pair->[0] } },
    subsets      => { exceptions => { of => 'train', where => sub ($pair) { exists $irregular{ $pair->[0] } || exists $twin{ $pair->[0] } } } },
    fidelity     => { all => 0.90, exceptions => 1.00 });
$twins->run;
my %alike = map { $_->[0][0] => $_->[2][0] } $twins->indistinct;
ok($alike{zabrodek} && $alike{brodek}, 'the job finds the pairs its model reads alike and that have different answers');
ok($twins->result->{met}, 'and meets its thresholds without them: every exception it can tell apart is retained');
like($twins->report, qr/cannot tell from a pair with a different answer; a wider window would/, 'the report names them');
is(scalar($job->indistinct), 0, 'a job whose model can tell everything apart has none');

# --- contradictory pairs ------------------------------------------------------
my $clash = Peta::NN::Job->new(%JOB, pairs => [ @pairs, [ 'brodek', 'brodkové' ], [ 'stoka', 'stoky' ] ]);
is_deeply([ $clash->contradictions ], [ [ [ 'brodek', 'brodkové' ], 'brodci' ] ], 'a second answer for an input is set aside and reported; a repeated one is not');
is(scalar(grep { $_->[0] eq 'brodek' } map { $clash->part($_) } qw(train validation test)), 1, 'the first answer is the one kept');

# --- definitions that cannot work --------------------------------------------
ok(!eval { Peta::NN::Job->new(%JOB, fidelity => { vowels => 0.9 }); 1 }, 'a threshold on an undefined subset is refused');
ok(!eval { Peta::NN::Job->new(%JOB, search => { scale => [ 2, 64 ], start => 128 }); 1 }, 'a starting width outside the scale is refused');
ok(!eval { Peta::NN::Job->new(%JOB, search => { scale => [ 2, 64 ], grow => 1 }); 1 }, 'a growth factor that does not grow is refused');

done_testing;
