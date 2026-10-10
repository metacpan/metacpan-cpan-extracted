use v5.36;
use utf8;
use Test::More;
use lib 'lib', 't/lib';
use Peta::NN;
use Peta::NN::Backend;
use Peta::NN::Model;
use Synthetic qw(inflect ending_class split_pairs);

# What stays on the graphics card when a model is trained there: the samples
# of a training run, which a step then picks its batch from, and the model
# when it is measured. Both are ways of doing the same thing with less
# carrying, so each is held against the way that carries.

plan skip_all => 'no graphics card to compute on in this perl' if !Peta::NN::Backend::try('gpu');

my ($train, $test) = split_pairs(\&inflect, 600, 150, 23);
my @classes = map { [ $_->[0], ending_class($_->[0]) ] } @$train;

# --- an epoch whose samples stay on the card ----------------------------------
my %weights;
for my $kept (0, 1) {
    local $Peta::NN::EPOCH_ON_BACKEND = $kept;
    my $model = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], seed => 3, backend => 'gpu');
    $model->fit($train, epochs => 3, batch => 50, lr => 0.01, weight => sub (@pair) { length($pair[0]) > 5 ? 3 : 1 }, validate => $test);
    $weights{$kept} = $model->net->weights;
}
is_deeply($weights{1}, $weights{0}, 'samples kept on the card, batches picked there (a last batch that is not full, weights per sample): the weights are those of carrying every batch, to the last bit');

# --- a model measured where it is trained -----------------------------------------
my %model = (
    'an edit model' => [ Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], backend => 'gpu'), $train, $test ],
    'a class model' => [ Peta::NN::Model->new(kind => 'class', side => 'both', window => 3, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], backend => 'gpu'), \@classes, [ map { [ $_->[0], ending_class($_->[0]) ] } @$test ] ],
    'a model with a parameter' => [ Peta::NN::Model->new(kind => 'edit', window => 3, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], backend => 'gpu'),
                                    [ map { ([ $_->[0], "$_->[0]-a", 'near' ], [ $_->[0], "$_->[0]-o", 'far' ]) } @$train[ 0 .. 299 ] ],
                                    [ map { ([ $_->[0], "$_->[0]-a", 'near' ], [ $_->[0], "$_->[0]-o", 'far' ]) } @$test ] ],
);
for my $what (sort keys %model) {
    my ($model, $pairs, $held) = @{ $model{$what} };
    $model->fit($pairs, epochs => 4, batch => 32, lr => 0.01);
    cmp_ok(abs($model->accuracy($held, where_trained => 1) - $model->accuracy($held)), '<=', 1 / @$held, "$what, measured on the card: what the inference leg measures, give or take one answer of @{[ scalar @$held ]}");
    $model->tune($pairs, epochs => 2, batch => 32, lr => 0.01);
    cmp_ok(abs($model->accuracy($held, where_trained => 1) - $model->accuracy($held)), '<=', 1 / @$held, "$what: and again after more training, with the weights as they are then");
}
my $front = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 2, layers => [ [ embed => 6 ], [ dense => 16 ], 'relu' ], backend => 'gpu')
    ->fit([ map { [ $_->[0], "x$_->[0]" ] } @$train ], epochs => 3, batch => 32, lr => 0.01);
is($front->accuracy([ map { [ $_->[0], "x$_->[0]" ] } @$test ], where_trained => 1), $front->accuracy([ map { [ $_->[0], "x$_->[0]" ] } @$test ]),
   'a model of a kind the card does not answer for is measured by the inference leg, whatever is asked');
my $elsewhere = Peta::NN::Model->new(kind => 'edit', window => 4, layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ], backend => 'plain')->fit($train, epochs => 2, batch => 32, lr => 0.01);
is($elsewhere->accuracy($test, where_trained => 1), $elsewhere->accuracy($test), 'and so is a model that is not trained on the card');

done_testing;
