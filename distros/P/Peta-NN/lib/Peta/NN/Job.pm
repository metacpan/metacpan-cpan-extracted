package Peta::NN::Job;
# ABSTRACT: train a model until it meets given fidelity thresholds, at the smallest size that can

# An optimisation job: say what a model must achieve and what it may cost,
# and get the smallest model that does.
#
# A job trains ONE model until it has got there. It does not run from a model
# that falls short to another one:
#
#   train     until every threshold is met, for as long as the model keeps
#             getting closer to them. What is watched is the distance to the
#             thresholds, not the loss: a model that still has three of its
#             exceptions to learn is not done because its loss has gone flat.
#             Training on is gentler than training: a lower learning rate,
#             so that the model keeps what it has while it learns the rest.
#   weigh     a model that has stopped getting closer while a subset it must
#             retain is still short is trained on with more weight on that
#             subset
#   widen     a model that has stopped getting closer all the same has
#             learned what its size allows. It is given wider hidden layers,
#             which changes none of its answers (Peta::NN::Model's widen),
#             and trains on with what it knows
#
# The job starts at the smallest width it is allowed and widens by `grow`, so
# the model that gets there is the smallest that does, to within that factor.
# A second seed then has to get there as well, from that width: one lucky
# initialisation is not an answer.
#
# What no training can reach is taken out of what must be retained, and
# reported: pairs the model reads exactly as it reads another pair with a
# different answer, because they differ only outside its window. Chasing
# those would widen the model for ever.
#
# The data is split three ways. Thresholds are checked on the validation part
# while training, with the subsets that must be retained on the training
# part; the test part is measured once, on the model returned.

use v5.36;
use utf8;

use Time::HiRes qw(time);

use Peta::NN::Model;
use Peta::NN::RNG;

our $VERSION = '0.2610090';

my %DEFAULT_SEARCH = (scale => [ 8, 256 ], depth => [1], grow => 2);
# epochs is the most one stage trains before the job looks at it again;
# patience is how many epochs a model may go without getting closer to its
# thresholds before it counts as stuck.
my %DEFAULT_TRAIN  = (epochs => 60, batch => 32, lr => 0.01, lr_decay => 0.95, patience => 20);
my %DEFAULT_BUDGET = (runs => 40);
my @DEFAULT_SPLIT  = (0.70, 0.15, 0.15);

my $BOOST          = 30;       # the weight of the pairs of a subset that has to be retained and is short
my $FINE           = 0.3;      # a model that is trained on is trained at this share of the learning rate:
                               # at the full rate it first unlearns, and takes a dozen epochs to be where it was
my $TIMED_ITEMS    = 256;
my $TIMED_REPEATS  = 3;

# The default network for a scale: an embedding that grows slowly with it,
# and `depth` hidden layers of `scale` units. A job takes the embedding of
# its starting width and keeps it; widening changes the hidden layers.
sub default_shape ($scale, $depth) {
    my $embed = int($scale / 4);
    $embed = 4  if $embed < 4;
    $embed = 16 if $embed > 16;
    return [ [ embed => $embed ], map { ([ dense => $scale ], 'relu') } 1 .. $depth ];
}

sub new ($class, %arg) {
    my $self = bless {
        model        => $arg{model}    // die("model => { kind => ..., window => ... } is required\n"),
        pairs        => $arg{pairs}    // die("pairs => [[input, output], ...] is required\n"),
        fidelity     => $arg{fidelity} // die("fidelity => { all => 0.97, ... } is required\n"),
        subsets      => $arg{subsets}  // {},
        group        => $arg{group}    // sub ($pair) { $pair->[0] },
        always_train => $arg{always_train},
        split        => $arg{split}    // [@DEFAULT_SPLIT],
        shape        => $arg{shape}    // \&default_shape,
        search       => { %DEFAULT_SEARCH, %{ $arg{search} // {} } },
        train        => { %DEFAULT_TRAIN,  %{ $arg{train}  // {} } },
        budget       => { %DEFAULT_BUDGET, %{ $arg{budget} // {} } },
        seed         => $arg{seed} // 1,
        backend      => $arg{backend} // $ENV{PETA_NN_BACKEND} // 'auto',
        attempts     => [],
    }, $class;
    for my $name (keys %{ $self->{fidelity} }) {
        die "fidelity names '$name', which is neither 'all' nor one of the subsets\n"
            if $name ne 'all' && !$self->{subsets}{$name};
    }
    my ($min, $max) = @{ $self->{search}{scale} };
    $self->{search}{start} //= $min;
    die "the search starts at a width of $self->{search}{start}, outside its scale of $min to $max\n"
        if $self->{search}{start} < $min || $self->{search}{start} > $max;
    die "grow is a factor above 1, not '$self->{search}{grow}'\n" if $self->{search}{grow} <= 1;
    $self->_drop_contradictions;
    $self->_split;
    return $self;
}

# Two pairs that give one input (with the same parameters) different outputs cannot both be
# answered right, by any model. Such an input keeps its first pair; the
# others are set aside and listed by contradictions(), so that a threshold is
# not missed for a reason no training can remove.
sub _drop_contradictions ($self) {
    my (%first, @kept, @dropped);
    for my $pair (@{ $self->{pairs} }) {
        my $key = join "\x{1f}", @$pair[ 0, 2 .. $#$pair ];
        if    (!exists $first{$key})        { $first{$key} = $pair->[1]; push @kept, $pair }
        elsif ($first{$key} eq $pair->[1]) { push @kept, $pair }
        else                               { push @dropped, [ $pair, $first{$key} ] }
    }
    @$self{qw(pairs contradictions)} = (\@kept, \@dropped);
    return;
}

# [the pair, the output that was kept for its input] for every pair set aside.
sub contradictions ($self) { return @{ $self->{contradictions} } }

# Whole groups go to one part: all forms of one word stay together, so the
# held-out parts hold words the model has never seen in any form.
sub _split ($self) {
    my (%group, @order);
    for my $pair (@{ $self->{pairs} }) {
        my $key = $self->{group}->($pair);
        push @order, $key if !$group{$key};
        push @{ $group{$key} }, $pair;
    }
    my $forced = $self->{always_train};
    my @fixed  = grep {  $forced && grep { $forced->($_) } @{ $group{$_} } } @order;
    my @free   = grep { !($forced && grep { $forced->($_) } @{ $group{$_} }) } @order;
    Peta::NN::RNG->new($self->{seed})->shuffle(\@free);

    my ($train_share, $validation_share) = @{ $self->{split} };
    my $n_train      = int(@free * $train_share);
    my $n_validation = int(@free * $validation_share);
    my %part = (
        train      => [ @fixed, @free[ 0 .. $n_train - 1 ] ],
        validation => [ @free[ $n_train .. $n_train + $n_validation - 1 ] ],
        test       => [ @free[ $n_train + $n_validation .. $#free ] ],
    );
    $self->{part}{$_} = [ map { @{ $group{$_} } } @{ $part{$_} } ] for keys %part;
    die "the split leaves the validation part empty\n" if !@{ $self->{part}{validation} };
    return;
}

sub part ($self, $name) { return @{ $self->{part}{$name} } }

# The pairs a threshold is measured on: 'all' is the whole held-out part; a
# subset is the pairs its `where` accepts, of that part or, with of =>
# 'train', of the training part (what was shown and must be retained).
sub _measured_on ($self, $name, $held_out) {
    return $self->{part}{$held_out} if $name eq 'all';
    my $subset = $self->{subsets}{$name};
    return [ grep { $subset->{where}->($_) } @{ $self->{part}{$held_out} } ] if ($subset->{of} // '') ne 'train';
    # What must be retained, but for what the model cannot tell apart.
    return $self->{retained}{$name} //= [ grep { $subset->{where}->($_) && !$self->{is_indistinct}{$_} } @{ $self->{part}{train} } ];
}

# The pairs of the training part that the model reads as it reads another
# pair with a different answer; see Peta::NN::Model's indistinct. They are
# found once, with the first model that has been fitted: what a model reads
# does not depend on its width.
sub _find_indistinct ($self, $model) {
    return if $self->{indistinct};
    $self->{indistinct}    = [ $model->indistinct($self->{part}{train}) ];
    $self->{is_indistinct} = { map { $_->[0] => 1 } @{ $self->{indistinct} } };
    delete $self->{retained};
    return;
}

# [pair, another answer, a pair that has it] for every training pair the
# model cannot tell from one with a different answer.
sub indistinct ($self) { return @{ $self->{indistinct} // [] } }

# { name => share of pairs answered exactly } for every threshold.
# With $quick the model is measured where it is trained: on the graphics card,
# if that is where, which is what watching every epoch can afford. What a
# stage records, and what decides, is measured by the inference leg.
sub _fidelity ($self, $model, $held_out, $quick = 0) {
    my %value;
    for my $name (sort keys %{ $self->{fidelity} }) {
        my $pairs = $self->_measured_on($name, $held_out);
        $value{$name} = @$pairs ? $model->accuracy($pairs, where_trained => $quick) : 1;
    }
    return \%value;
}

# Milliseconds per item on the inference leg, which is what a user of the
# model runs: the best of a few timed passes over a batch of held-out inputs.
sub _ms_per_item ($self, $model) {
    my @pairs = @{ $self->{part}{validation} };
    # One pass has one set of parameters: those of the first pair.
    my @values = @{ $pairs[0] }[ 2 .. $#{ $pairs[0] } ];
    @pairs = grep { "@$_[ 2 .. $#$_ ]" eq "@values" } @pairs;
    $#pairs = $TIMED_ITEMS - 1 if @pairs > $TIMED_ITEMS;
    my @inputs      = map { $_->[0] } @pairs;
    my $best;
    for (1 .. $TIMED_REPEATS) {
        my $start   = time;
        my @answers = @{ $model->inference->answers(\@inputs, @values) };
        my $seconds = time - $start;
        $best = $seconds if !defined $best || $seconds < $best;
    }
    return 1000 * $best / @inputs;
}

# How much a pair counts in training: the pairs of the subsets in %$boost
# count that many times.
sub _weight ($self, $boost) {
    return if !%$boost;
    my $subsets = $self->{subsets};
    return sub (@pair) {
        my $weight = 1;
        for my $name (keys %$boost) {
            $weight *= $boost->{$name} if $subsets->{$name}{where}->(\@pair);
        }
        return $weight;
    };
}

sub _out_of_budget ($self) {
    my $budget = $self->{budget};
    return 'run limit reached'  if @{ $self->{attempts} } >= $budget->{runs};
    return 'time limit reached' if defined $budget->{seconds} && time - $self->{started} >= $budget->{seconds};
    return;
}

# How far a model is from the thresholds: the shortfalls added up, 0 when
# every one is met.
sub _distance ($self, $fidelity) {
    my $distance = 0;
    for my $name (keys %$fidelity) {
        my $gap = $self->{fidelity}{$name} - $fidelity->{$name};
        $distance += $gap if $gap > 0;
    }
    return $distance;
}

# One stage of training: the model is trained, from nothing if it is new and
# on from where it is if not, until every threshold is met, or it has gone
# `patience` epochs without getting closer to them, or the stage's epochs or
# the job's time are used up. The weights it is left with are those of the
# epoch that was closest, or the ones it came with if no epoch got closer
# than it already was. The record says what the stage came to; `ended` is
# 'met', 'stuck', 'epochs' or 'time'.
sub _stage ($self, $model, $stage, $boost, %opt) {
    my $start    = time;
    my $train    = $self->{train};
    my $patience = $train->{patience};
    my $limit    = $self->{budget}{seconds};
    my ($closest, $stale, $ended) = (undef, 0, 'epochs');

    # A model that has been trained comes with a distance of its own to beat.
    my $came_with = $model->net ? { distance => $self->_distance($self->_fidelity($model, 'validation')), weights => $model->net->weights } : undef;
    $closest = $came_with->{distance} if $came_with;

    # What training watches, epoch by epoch: the distance to the thresholds.
    my $watch = sub ($loss, $held) {
        my $distance = $self->_distance($self->_fidelity($model, 'validation', 1));
        if    (!defined $closest || $distance < $closest) { ($closest, $stale) = ($distance, 0) }
        else                                              { $stale++ }
        return $distance;
    };
    my $go_on = sub ($epoch, $loss) {
        if    ($closest == 0)                                             { $ended = 'met' }
        elsif ($stale >= $patience)                                       { $ended = 'stuck' }
        elsif (defined $limit && time - $self->{started} >= $limit)       { $ended = 'time' }
        return $ended eq 'epochs';
    };
    my $weight = $self->_weight($boost);
    my @how    = (validate => $self->{part}{validation}, ($weight ? (weight => $weight) : ()),
                  %$train, ($came_with ? (lr => $train->{lr} * $FINE) : ()),
                  patience => $train->{epochs} + 1, watch => $watch, on_epoch => $go_on);
    if ($model->net) { $model->tune($self->{part}{train}, @how) }
    else {
        # A new model is fitted for one epoch first, so that what it cannot
        # tell apart is known before anything is asked of it.
        $model->fit($self->{part}{train}, @how, epochs => 1, watch => undef, on_epoch => undef, patience => undef);
        $self->_find_indistinct($model);
        $model->tune($self->{part}{train}, @how, epochs => $train->{epochs} - 1);
    }
    my $epochs = ($came_with ? 0 : 1) + (() = $model->net->history);
    if ($came_with && $self->_distance($self->_fidelity($model, 'validation')) > $came_with->{distance}) {
        $model->net->set_weights($came_with->{weights});
        $ended = 'stuck' if $ended eq 'epochs';
    }

    my $fidelity = $self->_fidelity($model, 'validation');
    my ($width)  = map { $_->[1] } grep { ref && $_->[0] eq 'dense' } @{ $model->{layers} };
    my $record   = {
        stage    => $stage,
        scale    => $width,
        depth    => scalar(grep { ref && $_->[0] eq 'dense' } @{ $model->{layers} }),
        seed     => $model->{seed},
        params   => $model->net->n_params,
        epochs   => $epochs,
        fidelity => $fidelity,
        missed   => [ grep { $fidelity->{$_} < $self->{fidelity}{$_} } sort keys %$fidelity ],
        ended    => $ended,
        ms       => $self->_ms_per_item($model),
        seconds  => time - $start,
        confirmation => $opt{confirmation} ? 1 : 0,
        backend  => $model->net->backend,
    };
    my $budget = $self->{budget};
    $record->{over} = join ', ',
        (defined $budget->{params} && $record->{params} > $budget->{params} ? 'parameters' : ()),
        (defined $budget->{ms}     && $record->{ms}     > $budget->{ms}     ? 'milliseconds' : ());
    $record->{passed} = !@{ $record->{missed} } && !$record->{over} ? 1 : 0;
    push @{ $self->{attempts} }, $record;
    $self->{progress}->($record) if $self->{progress};
    return $record;
}

# Train one model until it has got there, giving it weight on what is short
# and, with $widen, more width when it is stuck. Returns the model and the
# record of its last stage.
sub _grow ($self, $width, $depth, $seed, %opt) {
    my ($min, $max) = @{ $self->{search}{scale} };
    my $model = Peta::NN::Model->new(%{ $self->{model} }, layers => $self->{shape}->($width, $depth), seed => $seed,
                                     backend => $self->{backend});
    my (%boost, $record);
    my $stage = 'train';
    while (!$self->_out_of_budget) {
        $record = $self->_stage($model, $stage, \%boost, confirmation => $opt{confirmation});
        last if $record->{passed} || $record->{over} || $record->{ended} eq 'time';
        if ($record->{ended} eq 'epochs') { $stage = 'train on'; next }      # still getting closer: it only needs more

        # Stuck. First more weight on what must be retained and is not, once
        # per subset; then more room.
        my @short = grep { $_ ne 'all' && ($self->{subsets}{$_}{of} // '') eq 'train' && !$boost{$_} } @{ $record->{missed} };
        if (@short) {
            $boost{$_} = $BOOST for @short;
            $stage = "more weight on: @short";
            next;
        }
        last if !$opt{widen} || $width >= $max;
        my $wider = int($width * $self->{search}{grow} + 0.5);
        $width = $wider > $max ? $max : $wider;
        $model->widen($width);
        $stage = "widened to $width";
    }
    return ($model, $record);
}

# Find the smallest model that meets the thresholds, and return it. If none
# does within the budget, the closest is returned; result() says which.
sub run ($self, %arg) {
    $self->{progress} = $arg{progress};
    $self->{started}  = time;

    # One model per depth, grown from the starting width until it gets there.
    my ($chosen, $model);
    for my $depth (@{ $self->{search}{depth} }) {
        last if $self->_out_of_budget;
        my ($grown, $record) = $self->_grow($self->{search}{start}, $depth, $self->{seed}, widen => 1);
        next if !$record;
        my $better = !$chosen
                  || $record->{passed} > $chosen->{passed}
                  || $record->{passed} == $chosen->{passed}
                     && ($record->{passed} ? $record->{params} < $chosen->{params}
                                           : $self->_distance($record->{fidelity}) < $self->_distance($chosen->{fidelity}));
        ($chosen, $model) = ($record, $grown) if $better;
        last if $record->{passed};
    }
    die "the budget allows no training at all\n" if !$chosen;

    # Confirm it: a second seed, from nothing and from the size the first one
    # reached, has to get there by the same rules. The model returned is the
    # first seed's.
    my $confirmed = 0;
    if ($chosen->{passed} && !$self->_out_of_budget) {
        my (undef, $again) = $self->_grow(@$chosen{qw(scale depth)}, $self->{seed} + 1, widen => 1, confirmation => 1);
        $confirmed = 1 if $again && $again->{passed};
    }

    $self->{result} = {
        met       => $chosen->{passed} ? 1 : 0,
        confirmed => $confirmed,
        %$chosen{qw(scale depth params ms fidelity missed over stage)},
        test      => $self->_fidelity($model, 'test'),
        runs      => scalar @{ $self->{attempts} },
        epochs    => eval { my $n = 0; $n += $_->{epochs} for grep { !$_->{confirmation} } @{ $self->{attempts} }; $n },
        seconds   => time - $self->{started},
        stopped   => $self->_out_of_budget // 'done',
    };
    return $model;
}

sub attempts ($self) { return @{ $self->{attempts} } }
sub result   ($self) { return $self->{result} }

# Every stage in the order it was run, and the outcome.
sub report ($self) {
    my @names = sort keys %{ $self->{fidelity} };
    my @clash = $self->contradictions;
    my $text  = !@clash ? '' : sprintf "%d pairs set aside: their input already had another answer (%s%s)\n", scalar @clash,
        join(', ', map { "$_->[0][0] → $_->[0][1], kept $_->[1]" } @clash[ 0 .. ($#clash < 2 ? $#clash : 2) ]), @clash > 3 ? ', ...' : '';
    my @same = $self->indistinct;
    $text .= sprintf "%d training pairs the model cannot tell from a pair with a different answer; a wider window would (%s%s)\n", scalar @same,
        join(', ', map { "$_->[0][0] → $_->[0][1] as $_->[2][0] → $_->[2][1]" } @same[ 0 .. ($#same < 2 ? $#same : 2) ]), @same > 3 ? ', ...' : '' if @same;
    $text .= sprintf "%-3s %-24s %5s %7s %6s %-5s %7s  %s  %s\n", '#', 'stage', 'width', 'params', 'epochs', 'on', 'ms',
        join(' ', map { sprintf '%-12s', substr($_, 0, 12) } @names), 'outcome';
    $text .= sprintf "%-3s %-24s %5s %7s %6s %-5s %7s  %s\n", '', 'required', '', '', '', '', $self->{budget}{ms} // '',
        join(' ', map { sprintf '%-12s', sprintf '>= %.1f%%', 100 * $self->{fidelity}{$_} } @names);
    my %ENDED = (stuck => 'no closer', epochs => 'still getting closer', time => 'out of time');
    my $n = 0;
    for my $a (@{ $self->{attempts} }) {
        my $outcome = $a->{passed} ? ($a->{confirmation} ? 'confirmed' : 'met')
                    : $a->{over}   ? "over budget: $a->{over}"
                    :                "$ENDED{ $a->{ended} }; short: @{ $a->{missed} }";
        $text .= sprintf "%-3d %-24s %5d %7d %6d %-5s %7.3f  %s  %s\n", ++$n,
            substr(($a->{confirmation} ? 'second seed: ' : '') . $a->{stage}, 0, 24), @$a{qw(scale params epochs backend ms)},
            join(' ', map { sprintf '%-12s', sprintf '%.2f%%', 100 * $a->{fidelity}{$_} } @names), $outcome;
    }
    my $r = $self->{result} or return $text;
    $text .= sprintf "\n%s: depth %d, width %d, %d parameters, %.3f ms per item. %s%d stages, %d epochs, %.0f s (%s).\n",
        ($r->{met} ? 'the model meets the thresholds' : 'the model does NOT meet the thresholds; this is the closest it got'),
        @$r{qw(depth scale params ms)},
        ($r->{met} ? ($r->{confirmed} ? 'Confirmed on a second seed. ' : 'NOT confirmed on a second seed. ') : ''),
        @$r{qw(runs epochs seconds stopped)};
    $text .= sprintf "on the test part, measured once: %s\n",
        join ', ', map { sprintf '%s %.1f%%', $_, 100 * $r->{test}{$_} } @names;
    return $text;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Job - train a model until it meets given fidelity thresholds, at the smallest size that can

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Job;

    my $job = Peta::NN::Job->new(
        model    => { kind => 'edit', side => 'both', window => 7 },
        pairs    => \@pairs,                          # [input, output, parameters...]
        group    => sub ($pair) { $lemma_of{ $pair->[0] } },
        always_train => sub ($pair) { $is_exception{ $pair->[0] } },
        subsets  => {
            exceptions    => { of => 'train', where => sub ($pair) { $is_exception{ $pair->[0] } } },
            'to positive' => { where => sub ($pair) { $pair->[2] eq 'positive' } },   # by a parameter
        },
        fidelity => { all => 0.96, exceptions => 1.00, 'to positive' => 0.85 },
        budget   => { ms => 1, seconds => 600 },
        search   => { scale => [8, 256], depth => [1, 2] },
    );
    my $model = $job->run;
    print $job->report;
    $model->export(...) if $job->result->{met};

=head1 DESCRIPTION

C<fidelity> names what must hold: C<all> is the share of held-out pairs
answered exactly; any other name is a subset from C<subsets>, measured on
the held-out part, or with C<< of => 'train' >> on the training part (what
the model was shown and must retain).

A job trains one model until it meets them. Training watches the distance to
the thresholds and goes on for as long as the model gets closer. A model
that has stopped getting closer is first trained with more weight on what it
must retain and has not, and then given wider hidden layers, which changes
none of its answers, and trained on. It is not thrown away for a larger one.

C<search> gives the C<scale>, the smallest and the largest width; C<start>,
the width to begin at, the smallest unless given; C<grow>, the factor by
which a stuck model is widened (2); and the depths to try, the next one only
if the one before could not get there. C<shape> turns the starting width
and a depth into a layer list; the default is an embedding and C<depth>
hidden layers.

C<train> is passed on to training. Its C<epochs> is the most one stage trains
before the job looks at the model again, its C<patience> the number of
epochs a model may go without getting closer before it counts as stuck.

C<budget> limits the cost: C<params>, C<ms> (per item, timed on the inference
leg), C<runs> (stages of training) and C<seconds> (wall clock for the job).

C<run> returns the model. If it met everything it is trained once more from
nothing on a second seed, at its size, to confirm; C<result> says whether it
met and was confirmed, and carries the one measurement on the test part.

=head1 METHODS

=head2 new

C<model>, C<pairs> and C<fidelity> are required. C<subsets>, C<group>,
C<always_train>, C<split>, C<shape>, C<search>, C<train>, C<budget>, C<seed>
and C<backend> are optional.

=head2 run

C<< run(progress => sub ($stage) { ... }) >>: trains, and returns the model:
the one that meets the thresholds, or the closest it got.

=head2 result

What the run came to: C<met>, C<confirmed>, the model's size, cost and
fidelity, the fidelity on the test part, the number of stages and epochs and
the time.

=head2 attempts

Every stage of training, in the order it was run: its name, the width, the
epochs it trained, the fidelity it reached, and how it ended.

=head2 report

The stages and the outcome as text.

=head2 part

C<part('train')>, C<part('validation')>, C<part('test')>: the pairs of a
part of the split.

=head2 contradictions

C<[the pair, the output that was kept for its input]> for every pair that was
set aside because its input already had another answer.

=head2 indistinct

C<[pair, another answer, a pair that has it]> for every training pair the
model reads exactly as it reads a pair with a different answer. Such pairs
are not counted in what must be retained: no training can get them right
together, only a wider window.

=head1 FUNCTIONS

=head2 default_shape

C<default_shape($scale, $depth)>: the layers for a starting width and a
depth unless C<shape> says otherwise.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
