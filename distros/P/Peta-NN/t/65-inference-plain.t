use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib', 't/lib';

# The inference leg's own arithmetic in plain Perl loops, which a perl with
# PDL never runs unless told to. It is told to here, before the leg loads.
BEGIN { $ENV{PETA_NN_ENGINE} = 'plain' }
use Peta::NN::Inference;
use Peta::NN::Model;
use Synthetic qw(inflect ending_class split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

is(Peta::NN::Inference::engine(), 'plain', 'PETA_NN_ENGINE=plain is honoured');

my $dir = tempdir(CLEANUP => 1);
my ($train, $test) = split_pairs(\&inflect, 800, 150, 61);
my @words = map { $_->[0] } @$test;

# Every activation the loops have, each in a model of another kind.
my %MODEL = (
    'edit, relu'      => [ { kind => 'edit', window => 4, layers => [ [embed => 6], [dense => 24], 'relu' ] }, $train, $test, 0.95 ],
    'class, tanh'     => [ { kind => 'class', window => 2, layers => [ [embed => 4], [dense => 12], 'tanh' ] },
                           [ map { [ $_->[0], ending_class($_->[0]) ] } @$train ], [ map { [ $_->[0], ending_class($_->[0]) ] } @$test ], 0.95 ],
    'rewrite, sigmoid' => [ { kind => 'rewrite', radius => 1, layers => [ [embed => 4], [dense => 16], 'sigmoid' ] },
                           [ map { [ $_->[0], uc($_->[0]) =~ tr/AEIOU/aeiou/r ] } @$train ], [ map { [ $_->[0], uc($_->[0]) =~ tr/AEIOU/aeiou/r ] } @$test ], 0.90 ],
);
for my $name (sort keys %MODEL) {
    my ($new, $pairs, $held, $floor) = @{ $MODEL{$name} };
    my $model = Peta::NN::Model->new(%$new, seed => 3)->fit($pairs, epochs => 8, batch => 16, lr => 0.01);
    cmp_ok($model->accuracy($held), '>=', $floor, "$name: unseen words come out right");

    for my $bits (32, 8) {
        my $file = "$dir/model-$bits";
        $model->export(file => $file, bits => $bits);
        my $shipped = Peta::NN::Inference->load($file);
        my @got  = $shipped->predict_all(\@words);
        my @want = $model->predict_all(\@words);
        my $same = grep { $got[$_] eq $want[$_] } 0 .. $#words;
        cmp_ok($same / @words, '>=', $bits == 32 ? 1 : 0.97, "$name: the $bits-bit model file answers as the model does");
        is_deeply([ map { scalar $shipped->predict($_) } @words[ 0 .. 9 ] ], [ @got[ 0 .. 9 ] ], "$name, $bits bits: one string at a time gives what many at once give");
    }

    my $spread = $model->distribution($words[0]);
    $spread = $spread->[0] if $new->{kind} eq 'rewrite';       # one distribution per character
    my $sum = 0;
    $sum += $_->[1] for @$spread;
    cmp_ok(abs($sum - 1), '<', 1e-9, "$name: the probabilities of a distribution add up to 1");
    ok(!(grep { $spread->[$_][1] > $spread->[ $_ - 1 ][1] } 1 .. $#$spread), "$name: and are sorted, the most probable first");
}

done_testing;
