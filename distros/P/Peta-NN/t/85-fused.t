use v5.36;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib', 't/lib';
use Peta::NN::Backend;
use Peta::NN::Fused;
use Peta::NN::Inference;
use Peta::NN::Model;
use Peta::NN::Parallel;
use Peta::NN::Pipeline;
use Synthetic qw(inflect ending_class split_pairs);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# Micro models fused into one. The measure is the pipeline of the same steps:
# a fused model has to answer what it answers, for every string, whatever the
# models make of it. So the strings here include what no model was trained
# on: one letter, nothing at all, letters no model knows, very long words.

my %LAYERS = (layers => [ [embed => 6], [dense => 24], 'relu' ], seed => 4);
my %TRAIN  = (epochs => 6, batch => 16, lr => 0.01);
my ($train, $test) = split_pairs(\&inflect, 1200, 200, 51);
my @words = map { $_->[0] } @$train;
my @fresh = map { $_->[0] } @$test;

my $inflect = Peta::NN::Model->new(kind => 'edit', window => 4, %LAYERS)->fit($train, %TRAIN);
my %suffix  = (near => '-ta', far => '-tam');
my @forms   = (@words, map { inflect($_) } @words);
my $mark    = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)
    ->fit([ map { my $w = $_; map { [ $w, $w . $suffix{$_}, $_ ] } qw(near far) } @forms[ 0 .. 799 ] ], %TRAIN);
# strip cuts deeper than anything adds: three characters off, whatever they are.
my $strip   = Peta::NN::Model->new(kind => 'edit', window => 5, %LAYERS)
    ->fit([ map { [ $_, substr($_, 0, -3) ] } grep { length > 3 } @forms ], %TRAIN);
my $class   = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)->fit([ map { [ $_, ending_class($_) ] } @words ], %TRAIN);
my $front   = Peta::NN::Model->new(kind => 'edit', side => 'left', window => 2, %LAYERS)
    ->fit([ map { [ $_, "x$_" ] } @words ], %TRAIN);

# Models that classify: by the end of a word, by both its ends, by its front;
# and tag, whose answers are values of mark's parameter.
my $ends   = Peta::NN::Model->new(kind => 'class', side => 'both', window => 3, %LAYERS)
    ->fit([ map { [ $_, (/\A[bcd]/ ? 'soft' : 'hard') . '-' . ending_class($_) ] } @forms ], %TRAIN);
my $starts = Peta::NN::Model->new(kind => 'class', side => 'left', window => 2, %LAYERS)
    ->fit([ map { [ $_, /\A[bcd]/ ? 'soft' : 'hard' ] } @words ], %TRAIN);
my $tag    = Peta::NN::Model->new(kind => 'class', window => 2, %LAYERS)
    ->fit([ map { [ $_, ending_class($_) eq 'open' ? 'near' : 'far' ] } @words ], %TRAIN);
my $double = Peta::NN::Model->new(kind => 'edit', window => 2, %LAYERS)
    ->fit([ map { [ $_, $_ . substr($_, -1) ] } @words ], %TRAIN);

my %models  = (inflect => $inflect, mark => $mark, strip => $strip, class => $class, front => $front,
               ends => $ends, starts => $starts, tag => $tag, double => $double);
my @strange = ('', qw(a ek el ž žluťoučký stodek), 'bra' x 30, 'stodekstodekstodekstodekel');
my @strings = (@fresh, @strange);

# What a fused model and a pipeline make of the same strings: how many come
# out the same, answers of the classifying steps included, and how far the
# confidences of those are apart at most. With a size the strings go in as
# texts of that many.
sub compared ($fused, $pipeline, @arguments) { return compared_as(0, $fused, $pipeline, @arguments) }

sub compared_as ($size, $fused, $pipeline, @arguments) {
    my ($got, $want);
    if ($size) {
        my @texts = map { [ @strings[ $_ * $size .. ($_ * $size + $size - 1 < $#strings ? $_ * $size + $size - 1 : $#strings) ] ] } 0 .. int($#strings / $size);
        ($got, $want) = map { [ map { @$_ } @{ $_->run_texts(\@texts, @arguments) } ] } $fused, $pipeline;
    }
    else { ($got, $want) = map { $_->run(\@strings, @arguments) } $fused, $pipeline }
    my @same = grep {
        my ($g, $w) = ($got->[$_], $want->[$_]);
        $g->{text} eq $w->{text} && join("\0", map { "$_=$g->{answers}{$_}" } sort keys %{ $g->{answers} }) eq join("\0", map { "$_=$w->{answers}{$_}" } sort keys %{ $w->{answers} })
    } 0 .. $#strings;
    my $off = 0;
    for (@same) { my $d = abs($got->[$_]{confidence} - $want->[$_]{confidence}); $off = $d if $d > $off }
    return (scalar @same, $off);
}

# --- a fused model is its pipeline --------------------------------------------
my %CHAIN = (
    'two in series'                    => [ [ { model => 'inflect' }, { model => 'mark', params => [ \0 ] } ], 'far' ],
    'a fixed parameter'                => [ [ { model => 'inflect' }, { model => 'mark', params => ['near'] } ] ],
    'one model three times'            => [ [ ({ model => 'inflect' }) x 3 ] ],
    'cutting into what was added'      => [ [ { model => 'mark', params => ['far'] }, { model => 'strip' }, { model => 'inflect' } ] ],
    'cutting deep, again and again'    => [ [ { model => 'strip' }, { model => 'strip' }, { model => 'mark', params => [ \0 ] }, { model => 'strip' } ], 'near' ],
    'a single step'                    => [ [ { model => 'strip' } ] ],
);
for my $what (sort keys %CHAIN) {
    my ($steps, @arguments) = @{ $CHAIN{$what} };
    my $pipeline = Peta::NN::Pipeline->new(models => \%models, steps => $steps);
    my $fused    = Peta::NN::Fused->new(models => \%models, steps => $steps, engine => 'cpu');
    my ($same, $off) = compared($fused, $pipeline, @arguments);
    is($same, scalar @strings, "$what: every one of @{[ scalar @strings ]} strings comes out as from the pipeline");
    cmp_ok($off, '==', 0, "$what: with the same confidence, to the last bit");
}

# --- steps that classify: an answer chooses the model, or is a parameter -------
my %CHOICE = (
    'an answer chooses between two models' => [ { name => 'c', model => 'class', classify => 1 }, { model => { c => { open => 'double', '*' => 'inflect' } } } ],
    'an answer as a parameter'             => [ { name => 'which', model => 'tag', classify => 1 }, { model => 'mark', params => [ { answer => 'which' } ] } ],
    'both ends read after the end was rewritten' => [ { model => 'strip' }, { model => 'mark', params => ['far'] }, { name => 'e', model => 'ends', classify => 1 }, { model => 'strip' }, { name => 's', model => 'starts', classify => 1 } ],
    'a model chosen, and then models chosen by its answer' => [
        { name => 's', model => 'starts', classify => 1 },
        { name => 'k', model => { s => { soft => 'tag', hard => 'class' } }, classify => 1 },
        { model => { k => { near => 'double', far => 'inflect', open => 'strip', '*' => 'double' } } },
        { model => { s => { soft => 'mark', hard => 'mark' } }, params => [ \0 ] },
    ],
);
my %POOLED = (
    'a text classified as one' => [ { name => 't', model => 'ends', classify => 1, pool => 1 }, { name => 'w', model => 'class', classify => 1 } ],
    'a text classified, and that chooses the model for its words' => [
        { name => 't', model => 'starts', classify => 1, pool => 1 },
        { name => 'w', model => { t => { soft => 'tag', hard => 'ends' } }, classify => 1 },
    ],
    'pooled among the words an earlier answer chose' => [
        { name => 's', model => 'starts', classify => 1 },
        { name => 't', model => { s => { soft => 'class', hard => 'ends' } }, classify => 1, pool => 1 },
    ],
);
for my $what (sort keys %CHOICE) {
    my $steps    = $CHOICE{$what};
    my @arguments = $what =~ /chosen by its answer/ ? ('near') : ();
    my ($same, $off) = compared(Peta::NN::Fused->new(models => \%models, steps => $steps, engine => 'cpu'), Peta::NN::Pipeline->new(models => \%models, steps => $steps), @arguments);
    is($same, scalar @strings, "$what: every string and its answers as from the pipeline");
    cmp_ok($off, '==', 0, "$what: with the same confidence, to the last bit");
}
for my $what (sort keys %POOLED) {
    my $steps = $POOLED{$what};
    for my $size (1, 7, 40) {
        my ($same, $off) = compared_as($size, Peta::NN::Fused->new(models => \%models, steps => $steps, engine => 'cpu'), Peta::NN::Pipeline->new(models => \%models, steps => $steps));
        is($same, scalar @strings, "$what, texts of $size: every string and its answers as from the pipeline");
        cmp_ok($off, '==', 0, "$what, texts of $size: with the same confidence, to the last bit");
    }
}
{
    my $steps = $POOLED{'a text classified, and that chooses the model for its words'};
    my $fused = Peta::NN::Fused->new(models => \%models, steps => $steps, engine => 'cpu');
    is_deeply([ $fused->names ], [qw(t w)], 'the names of the steps that classify');
    is_deeply([ $fused->parts ], [qw(starts ends tag)], 'the parts of a step that chooses are all parts');
    is($fused->front, 3, 'it reads as much of the front as the part that reads most of it');
    my $texts = $fused->run_texts([ [qw(stoka banek)], [], [qw(drak)] ]);
    is_deeply([ map { scalar @$_ } @$texts ], [ 2, 0, 1 ], 'run_texts: the records of each text, an empty text included');
    is($texts->[0][0]{answers}{t}, $texts->[0][1]{answers}{t}, 'run_texts: the words of a text have its one pooled answer');
    is($texts->[0][1]{text}, 'banek', 'run_texts: a word that is only classified comes out as it went in');
}

my @series = ({ model => 'inflect' }, { model => 'mark', params => [ \0 ] });
my $pipeline = Peta::NN::Pipeline->new(models => \%models, steps => \@series);
my $fused    = $pipeline->fuse(engine => 'cpu');
is(scalar $fused->predict('stodek', 'far'), 'stodku-tam', 'a pipeline fuses itself; the answer');
my ($answer, $confidence) = $fused->predict('stodek', 'far');
my (undef, $expected)     = $pipeline->predict('stodek', 'far');
cmp_ok($confidence, '==', $expected, 'in list context also the confidence, the product of the parts\'');
is_deeply([ $fused->predict_all(\@fresh, 'near') ], [ $pipeline->predict_all(\@fresh, 'near') ], 'many strings at once');

# --- what it is ---------------------------------------------------------------
is($fused->arguments, 1, 'it takes the arguments its steps refer to');
is_deeply([ $fused->parts ], [qw(inflect mark)], 'its parts, in the order of the steps');
is($fused->n_params, $inflect->inference->n_params + $mark->inference->n_params, 'it has the weights of its parts, no more and no fewer');
is($fused->engine, 'cpu', 'its engine');
my ($deepest, $longest) = (0, 0);
for ($inflect->labels) { my ($cut) = split /:/; $deepest = $cut if $cut > $deepest }
for ($inflect->labels, $mark->labels) { my $add = length((split /:/, $_, 2)[1]); $longest = $add if $add > $longest }
ok($fused->reach >= 2 + $deepest, 'it reads as far back as the second model can come to read after the first has cut its deepest');
ok($fused->reach >= $longest, '... and holds the longest text a part adds');
is_deeply([ $fused->part('mark')->labels ], [ $mark->labels ], 'a part is the model it was');
my $info = $fused->info;
is_deeply([ @$info{qw(kind weights arguments)} ], [ 'fused', $fused->n_params, 1 ], 'info: what it is');
is_deeply($info->{steps}, [qw(inflect mark)], 'info: the steps');

# --- a file, and the parts in it as they are ----------------------------------
my $dir = tempdir(CLEANUP => 1);
$inflect->export(file => "$dir/inflect.model", bits => 8);
$mark->export(file => "$dir/mark.model");
my %files    = (models => { inflect => "$dir/inflect.model", mark => "$dir/mark.model" }, steps => \@series);
my $shipped  = Peta::NN::Pipeline->new(%files);
my $from     = Peta::NN::Fused->new(%files, meta => { name => 'inflect and mark' });
is(($from->save("$dir/both.fused"))[0], $from, 'save returns the fused model');
my $loaded   = Peta::NN::Fused->load("$dir/both.fused");
my ($same, $off) = compared($loaded, $shipped, 'far');
is($same, scalar @strings, 'from its file: every string as from the pipeline of the model files');
cmp_ok($off, '==', 0, 'from its file: the weights are the files\', 8-bit ones included, so is the confidence');
is($loaded->info->{name}, 'inflect and mark', 'from its file: its description');
ok($loaded->info->{created}, 'from its file: when it was written');

$fused->save("$dir/trained.fused");
($same, $off) = compared(Peta::NN::Fused->load("$dir/trained.fused"), $pipeline, 'near');
is($same, scalar @strings, 'parts that came as trained models: saved and loaded, the same answers');
cmp_ok($off, '==', 0, '... and confidences: their weights are stored in full');

# --- a part replaced ----------------------------------------------------------
my $other = Peta::NN::Model->new(kind => 'edit', window => 3, %LAYERS)
    ->fit([ map { my $w = $_; map { [ $w, $w . ($_ eq 'near' ? '+n' : '+f'), $_ ] } qw(near far) } @forms[ 0 .. 799 ] ], %TRAIN);
my $replaced = $fused->replace(mark => $other);
my $rebuilt  = Peta::NN::Pipeline->new(models => { inflect => $inflect, mark => $other }, steps => \@series);
($same) = compared($replaced, $rebuilt, 'far');
is($same, scalar @strings, 'replace: one part exchanged, the result is the pipeline with that model');
is(scalar $fused->predict('stodek', 'far'), 'stodku-tam', 'replace: the fused model it came from is as it was');
is_deeply($replaced->part('inflect')->data, $fused->part('inflect')->data, 'replace: the other part is untouched');
ok(!eval { $fused->replace(nowhere => $other); 1 }, 'replace: a part it does not have is refused');

# --- what does not fuse, and calls that cannot work ---------------------------
my @BAD = (
    [ 'no steps',                           [] ],
    [ 'a step without a model',             [ {} ] ],
    [ 'a model that is not there',          [ { model => 'decline' } ] ],
    [ 'a class model in a step that does not classify', [ { model => 'class' } ] ],
    [ 'an edit model in a step that classifies', [ { name => 'c', model => 'inflect', classify => 1 } ] ],
    [ 'a classifying step without a name',   [ { model => 'class', classify => 1 } ] ],
    [ 'a model chosen by a step that is not there', [ { model => { c => { open => 'inflect' } } } ] ],
    [ 'an answer the routing table has no model for', [ { name => 'c', model => 'class', classify => 1 }, { model => { c => { open => 'inflect' } } } ] ],
    [ 'a parameter from a step that is not there', [ { model => 'mark', params => [ { answer => 'c' } ] } ] ],
    [ 'an answer that is no value of the parameter', [ { name => 'c', model => 'class', classify => 1 }, { model => 'mark', params => [ { answer => 'c' } ] } ] ],
    [ 'pooling in a step that does not classify', [ { model => 'inflect', pool => 1 } ] ],
    [ 'a model that rewrites the front',    [ { model => 'front' } ] ],
    [ 'too few parameters',                 [ { model => 'mark' } ] ],
    [ 'too many parameters',                [ { model => 'inflect', params => ['far'] } ] ],
    [ 'a fixed parameter the model does not know', [ { model => 'mark', params => ['nowhere'] } ] ],
);
for my $case (@BAD) {
    my ($what, $steps) = @$case;
    ok(!eval { Peta::NN::Fused->new(models => \%models, steps => $steps); 1 }, "refused when fused: $what");
}
ok(!eval { Peta::NN::Fused->new(models => \%models, steps => \@series, engine => 'abacus'); 1 }, 'refused when fused: an unknown engine');
ok(!eval { $fused->predict('stodek'); 1 }, 'refused when called: an argument missing');
like($@, qr/takes 1 argument after the string, not 0/, '... saying how many it takes');
ok(!eval { $fused->predict('stodek', 'nowhere'); 1 }, 'refused when called: a parameter value the model does not have');
ok(!eval { Peta::NN::Fused->load("$dir/inflect.model"); 1 }, 'a model file is not a fused model\'s file');
like($@, qr/is not a Peta::NN fused model file/, '... and it says so');

# --- on the graphics card -------------------------------------------------------
# 32-bit floats there: the confidences agree to about six digits, and a
# decision between two labels that close may fall the other way.
SKIP: {
    skip 'no graphics card to compute on in this perl', 16 if !Peta::NN::Backend::try('gpu');
    for my $what ('two in series', 'cutting deep, again and again', 'cutting into what was added') {
        my ($steps, @arguments) = @{ $CHAIN{$what} };
        my $on_card = Peta::NN::Fused->new(models => \%models, steps => $steps, engine => 'gpu');
        ($same, $off) = compared($on_card, Peta::NN::Pipeline->new(models => \%models, steps => $steps), @arguments);
        cmp_ok($same / @strings, '>=', 0.99, "gpu, $what: at least 99% of the strings as from the pipeline ($same of @{[ scalar @strings ]})");
    }
    for my $what (sort keys %CHOICE) {
        my @arguments = $what =~ /chosen by its answer/ ? ('near') : ();
        ($same) = compared(Peta::NN::Fused->new(models => \%models, steps => $CHOICE{$what}, engine => 'gpu'), Peta::NN::Pipeline->new(models => \%models, steps => $CHOICE{$what}), @arguments);
        cmp_ok($same / @strings, '>=', 0.99, "gpu, $what: at least 99% of the strings and their answers as from the pipeline ($same of @{[ scalar @strings ]})");
    }
    for my $what (sort keys %POOLED) {
        ($same, $off) = compared_as(7, Peta::NN::Fused->new(models => \%models, steps => $POOLED{$what}, engine => 'gpu'), Peta::NN::Pipeline->new(models => \%models, steps => $POOLED{$what}));
        cmp_ok($same / @strings, '>=', 0.99, "gpu, $what, texts of 7: at least 99% as from the pipeline ($same of @{[ scalar @strings ]})");
        cmp_ok($off, '<', 1e-4, "gpu, $what: the confidences agree to single precision");
    }
    my $on_card = Peta::NN::Fused->load("$dir/both.fused", engine => 'gpu');
    is($on_card->engine, 'gpu', 'gpu: the engine of a loaded fused model');
    ($same, $off) = compared($on_card, $shipped, 'far');
    cmp_ok($off, '<', 1e-4, 'gpu: the confidences agree to single precision');

    # After it has computed on the card here, in a forked child: on the child's device.
    my @here = $on_card->predict_all(\@fresh, 'far');
    my ($there) = Peta::NN::Parallel::in_parallel(2, map { sub { [ $on_card->predict_all(\@fresh, 'far') ] } } 1, 2);
    is_deeply($there, \@here, 'gpu: a fused model that has been on the card answers the same in a forked child');
}

done_testing;
