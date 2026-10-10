use v5.36;
use utf8;
use Test::More;
use lib 'lib', 't/lib';
use Peta::NN::Chain qw(chain);
use Peta::NN::Data;
use Peta::NN::Model;
use Synthetic qw(inflect words);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The high level: data with named fields, models that say which fields they
# read and answer and what they have to reach, and a chain that trains its
# models and is measured by the data.

my %suffix = (near => '-ta', far => '-tam');
my @records = map { my $word = $_; map { { word => $word, form => inflect($word), which => $_, marked => inflect($word) . $suffix{$_} } } qw(near far) } @{ words(700, 51) };
my $data = Peta::NN::Data->new(records => \@records, fields => [qw(word form which marked)])
    ->hold_out(0.2)
    ->mark(short => sub ($record) { length $record->{word} < 6 });
cmp_ok($data->held->count, '>', 150, 'some records are held out');

# --- one model, fitted once ----------------------------------------------------
my $plain = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'form', reads => { end => 4 }, layers => [ [embed => 6], [dense => 24], 'relu' ]);
is($plain->train($data, train => { epochs => 8, batch => 16, lr => 0.01 }), $plain, 'train returns the model');
is(scalar $plain->predict('stodek'), 'stodku', 'a model without a goal is fitted, and answers');
my $score = $plain->score($data);
is_deeply([ sort keys %$score ], [qw(short unseen)], 'score: for the records held out, and for each mark');
cmp_ok($score->{unseen}, '>=', 0.95, sprintf 'score: of the records it was not shown (%.1f%%)', 100 * $score->{unseen});
is($plain->report, undef, 'a model that had no goal has no report');
ok(!eval { Peta::NN::Model->new(kind => 'edit')->train($data); 1 }, 'a model that does not say what it reads and answers cannot be trained on data');
like($@, qr/from => \.\.\., to => \.\.\./, '... and is told so');
ok(!eval { Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'forms')->train($data); 1 }, 'a field the data does not have is refused');
ok(!eval { Peta::NN::Model->new(kind => 'edit', reads => { middle => 3 }); 1 }, 'reads => something that is not an end is refused');
is_deeply([ @{ Peta::NN::Model->new(kind => 'class', reads => { both => 5 }) }{qw(side window)} ], [ 'both', 5 ], 'reads => { both => 5 } is five characters of each end');

# --- one model, to a goal ---------------------------------------------------------
my $aimed = Peta::NN::Model->new(kind => 'edit', from => 'form', to => 'marked', given => ['which'], reads => { end => 2 }, goal => { unseen => 0.97, short => 1 })
    ->train($data, search => { scale => [ 8, 64 ], start => 16 }, train => { batch => 16 });
like($aimed->report, qr/the model meets the thresholds/, 'a model with a goal is trained by a job until it meets it');
is($aimed->score($data)->{short}, 1, '... every record of the mark it had to get right, right');
cmp_ok($aimed->score($data)->{unseen}, '>=', 0.97, '... and the share of unseen records it had to');
is(scalar $aimed->predict('stodku', which => 'far'), 'stodku-tam', '... and it is asked by the names of the fields it is given');
ok($aimed->reached->{met}, 'reached: what the job measured');

# --- a chain that trains its models -------------------------------------------------
my $first  = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'form', reads => { end => 4 }, goal => { unseen => 0.95 });
my $second = Peta::NN::Model->new(kind => 'edit', from => 'form', to => 'marked', given => ['which'], reads => { end => 2 }, goal => { unseen => 0.97 });
my $both   = chain(inflect => $first, mark => $second);
is_deeply([ $both->parts ], [qw(inflect mark)], 'a chain of models that are not trained yet has its parts');
is_deeply([ $both->given ], ['which'], '... and its arguments');
ok(!eval { $both->predict('stodek', which => 'far'); 1 }, '... but cannot answer');
like($@, qr/'inflect' is, 'mark' is not trained/, '... and says what is missing');
ok(!eval { $both->save('nowhere.chain'); 1 }, '... nor be saved');
is($both->train($data, search => { scale => [ 8, 64 ], start => 16 }, train => { batch => 16 }), $both, 'train returns the chain');
is(scalar $both->predict('stodek', which => 'far'), 'stodku-tam', 'trained, it answers');
ok($first->net && $second->net, 'the models the caller holds are the trained ones');
is(scalar $first->predict('stodek'), 'stodku', '... and answer on their own');
like($both->report, qr/== inflect ==.*== mark ==/s, 'report: what each model\'s job has to say');
my $reached = $both->score($data, from => 'word', to => 'marked');
is_deeply([ sort keys %$reached ], [qw(short unseen)], 'score: for the records held out, and for each mark');
cmp_ok($reached->{unseen}, '>=', 0.93, sprintf 'score: the chain from the first field to the last, on records it was not shown (%.1f%%)', 100 * $reached->{unseen});
ok(!eval { $both->score($data, from => 'word'); 1 }, 'score without saying what it is to give is refused');

# A part that is trained already is left alone; one that is not, is trained.
my $third = Peta::NN::Model->new(kind => 'edit', from => 'form', to => 'marked', given => ['which'], reads => { end => 2 });
my $mixed = chain(inflect => $plain, mark => $third);
my $before = $plain->net->weights;
$mixed->train($data, train => { epochs => 6, batch => 16, lr => 0.01 });
is_deeply($plain->net->weights, $before, 'a part that was trained is not trained again');
is(scalar $mixed->predict('stodek', which => 'near'), 'stodku-ta', '... and the chain answers with both');

# What the chain classifies can be what is scored.
my @ends = map { { word => $_, ends => /[aeiou]\z/ ? 'open' : 'closed' } } @{ words(600, 7) };
my $kinds = Peta::NN::Data->new(records => \@ends, fields => [qw(word ends)])->hold_out(0.2);
my $sorter = chain(ends => Peta::NN::Model->new(kind => 'class', from => 'word', to => 'ends', reads => { end => 2 }))->train($kinds, train => { epochs => 6, batch => 16 });
cmp_ok($sorter->score($kinds, from => 'word', to => 'ends', answer => 'ends')->{unseen}, '>=', 0.97, 'score: the answer of a part that classifies, held against a field');

done_testing;
