package Peta::NN::Model;
# ABSTRACT: train a micro model from string pairs, export it as a model file

# The training leg's view of a micro model: a small network with the string
# handling around it, trained from pairs of strings. What it produces is a
# model file for the inference leg (Peta::NN::Inference).
#
# Three kinds, differing only in what one decision of the network means:
#   class     the string as a whole gets a label
#   edit      one end of the string, or both, is rewritten; the label is the edit
#   rewrite   every character gets a replacement of its own
#
# A training pair is [input, output] followed by any number of parameters:
# [input, output, 'dative'], [input, output, 'feminine', 'comparative']. A
# parameter is an opaque value. The model learns what to do for each value
# it is shown; it knows nothing of what a value means, and every pair must
# have the same number of them.
#
# Answers always come from Peta::NN::Inference, here as after shipping, so
# what is measured during training is what a user of the model file gets.

use v5.36;

use Storable ();

use Peta::NN;
use Peta::NN::Codec qw(build_vocab edit_label edit2_label);
use Peta::NN::Inference;
use Peta::NN::RNG;

our $VERSION = '0.2610090';

my %KIND = map { $_ => 1 } qw(class edit rewrite);

my @DEFAULT_LAYERS = ([ embed => 8 ], [ dense => 32 ], 'relu');
my @CONFIG_KEYS    = qw(kind window side radius layers seed given from to goal);      # not `how`: a state is plain data, and that may hold subs
my @LEARNED_KEYS   = qw(vocab labels params);
my @READING_KEYS   = qw(kind window side radius vocab labels params given);   # what inference needs besides the weights
my @META_KEYS      = qw(name description source fidelity);
my $STATE_FORMAT   = 'Peta::NN training state';
my $EXPORT_BITS    = 32;       # model files carry 32-bit floats unless asked for 8; training state keeps doubles
my $EPOCHS         = 30;       # train() without a goal: at most so many epochs,
my $PATIENCE       = 3;        # and no more than so many without the held-out records being answered better
my %SEARCH         = (scale => [ 16, 512 ], start => 64, depth => [1]);    # train() to a goal: the widths a job tries

# What a model reads of a string, said in one table: { end => 8 }, { front => 2 },
# { both => 5 } (so many characters of each end), or for a rewrite model
# { around => 2 } (so many either side of each character).
my %READS = (end => [ side => 'right' ], front => [ side => 'left' ], both => [ side => 'both' ], around => []);

sub new ($class, %arg) {
    my $kind = $arg{kind} // die "kind => class, edit or rewrite is required\n";
    die "unknown kind '$kind'\n" if !$KIND{$kind};
    if (my $reads = delete $arg{reads}) {
        my ($where, @more) = ref $reads eq 'HASH' ? keys %$reads : ();
        die "reads => { end => N }, { front => N }, { both => N } or { around => N }\n" if !defined $where || @more || !$READS{$where};
        %arg = (%arg, @{ $READS{$where} }, ($where eq 'around' ? 'radius' : 'window') => $reads->{$where});
    }
    my $side = $arg{side} // 'right';
    die "side is 'left', 'right', 'both' or 'auto'\n" if $side !~ /\A(?:left|right|both|auto)\z/;
    die "side 'auto' is for edit models\n" if $kind ne 'edit' && $side eq 'auto';
    return bless {
        kind    => $kind,
        window  => $arg{window} // 6,     # class, edit: characters read from an end
        side    => $side,
        radius  => $arg{radius} // 2,     # rewrite: characters read either side
        layers  => $arg{layers} // [@DEFAULT_LAYERS],
        seed    => $arg{seed}   // 1,
        backend => $arg{backend},         # where training runs; see Peta::NN::Backend
        given   => $arg{given},           # the names of the parameters, in the order the pairs have them
        from    => $arg{from},            # the field of the data it reads, and the one it answers; train()
        to      => $arg{to},
        goal    => $arg{goal},            # what it has to reach: { unseen => share, a mark of the data => share }
        how     => { map { $_ => $arg{$_} } grep { defined $arg{$_} } qw(train search budget) },     # how train() goes about it
        sized   => defined $arg{layers} ? 1 : 0,
    }, $class;
}

sub net    ($self) { return $self->{net} }
sub labels ($self) { return @{ $self->{labels} } }

# The values known for each parameter: one sorted list per position.
sub parameters ($self) { return map { [ sort keys %$_ ] } @{ $self->{params} // [] } }

# The names of the parameters, in their order, if they were given any.
sub given ($self) { return @{ $self->{given} // [] } }

# How many token positions the network reads per decision.
sub _tokens ($self) {
    my $params = @{ $self->{params} // [] };
    return $params + 2 * $self->{radius} + 1 if $self->{kind} eq 'rewrite';
    return $params + ($self->{side} eq 'both' ? 2 : 1) * $self->{window};
}

# How the output differs from the input, as the model's side sees it: at the
# end, at the front (an edit at the end of the reversed string), or at both.
sub _edit_label ($self, $in, $out) {
    my $side = $self->{side};
    return edit2_label($in, $out) if $side eq 'both';
    return $side eq 'left' ? edit_label(scalar reverse($in), scalar reverse($out)) : edit_label($in, $out);
}

# One training pair becomes one or more (tokens, label) decisions. The
# windows are the inference leg's: both legs read a string the same way.
sub _decisions ($self, $in, $out, @values) {
    my @chars  = split //, $in;
    my @tokens = Peta::NN::Inference::param_tokens($self->{params}, @values);
    my $kind   = $self->{kind};
    return [ Peta::NN::Inference::end_window($self, \@chars, @tokens), $out ]                          if $kind eq 'class';
    return [ Peta::NN::Inference::end_window($self, \@chars, @tokens), $self->_edit_label($in, $out) ] if $kind eq 'edit';

    my @target = split //, $out;
    die "rewrite needs pairs of equal length: '$in' / '$out'\n" if @chars != @target;
    return map { [ Peta::NN::Inference::char_window($self, \@chars, $_, @tokens), $target[$_] ] } 0 .. $#chars;
}

# Learn from [input, output, parameters...] string pairs, starting from
# nothing: the vocabulary, the parameter values, the labels and a fresh
# network all come from these pairs. Two of the remaining arguments are the
# model's own:
#   validate   string pairs that are not trained on; their loss is measured
#              every epoch, which is what `patience` then watches
#   weight     sub ($in, $out, parameters...) giving how much a pair counts;
#              1 is plain
# Everything else goes to Peta::NN's train().
sub fit ($self, $pairs, %train) {
    # An edit model told to choose its side takes the end at which the pairs
    # differ in fewer ways: a prefix shows as a handful of edits from the
    # left and as one edit per word from the right.
    if ($self->{side} eq 'auto') {
        my %count;
        for my $side (qw(right left)) {
            $self->{side} = $side;
            my %seen = map { $self->_edit_label(@$_[ 0, 1 ]) => 1 } @$pairs;
            $count{$side} = keys %seen;
        }
        $self->{side} = $count{left} < $count{right} ? 'left' : 'right';
    }

    die "there are no pairs to learn from\n" if !@$pairs;
    $self->{vocab} = build_vocab([ map { $_->[0] } @$pairs ]);

    # Parameter values are tokens after the characters, one embedding row
    # each. A value has its own token per position: 'a' as first parameter
    # and 'a' as second are different things to the model.
    my $positions = @{ $pairs->[0] } - 2;
    die "every pair must have the same number of parameters\n" if grep { @$_ - 2 != $positions } @$pairs;
    die sprintf "the pairs have %d parameter%s, and the model is given %d name%s for them (%s)\n", $positions, $positions == 1 ? '' : 's',
        scalar @{ $self->{given} }, @{ $self->{given} } == 1 ? '' : 's', join ', ', @{ $self->{given} }
        if $self->{given} && @{ $self->{given} } != $positions;
    my $next = 2 + keys %{ $self->{vocab} };
    $self->{params} = [
        map {
            my $position = $_;
            my %seen = map { ($_->[ 2 + $position ] // die "a parameter is undefined\n") => 1 } @$pairs;
            +{ map { $_ => $next++ } sort keys %seen }
        } 0 .. $positions - 1
    ];

    # Labels are numbered in order of first appearance.
    my (%seen, @labels);
    for my $label (map { $_->[1] } map { $self->_decisions(@$_) } @$pairs) {
        push @labels, $label if !$seen{$label}++;
    }
    $self->{labels} = \@labels;

    $self->{net} = $self->_network($self->{layers});
    return $self->_train($pairs, %train);
}

# Go on training the network the model has, on new pairs. What the model can
# read and answer stays as it is: a character it has never seen reads as
# unknown, and a pair whose answer is not one of its labels, or whose
# parameter value it does not know, cannot be learned this way and is
# refused. The arguments are fit()'s.
sub tune ($self, $pairs, %train) {
    die "the model has not been trained; use fit\n" if !$self->{net};
    my %known   = map { $_ => 1 } @{ $self->{labels} };
    my @foreign = grep { !$known{ $_->[1] } } map { $self->_decisions(@$_) } @$pairs;
    die sprintf "%d of the pairs need an answer this model does not have (%s); that takes a fit from scratch\n",
        scalar @foreign, join ', ', map { "'$_->[1]'" } @foreign[ 0 .. ($#foreign < 2 ? $#foreign : 2) ] if @foreign;
    return $self->_train($pairs, %train);
}

# Make the hidden layers wider, to $width units each, without changing a
# single answer: a new unit reads with fresh random weights and is read with
# zeros, so the model computes what it did until training gives the new
# units something to say. A layer that is as wide already stays as it is.
# This is how a model that has learned all its size allows gets more room
# and goes on learning, instead of a larger one starting from nothing.
sub widen ($self, $width) {
    die "the model has not been trained; a model is widened after fit\n" if !$self->{net};
    die "the width is a positive whole number, not '$width'\n" if $width !~ /\A[1-9][0-9]*\z/;
    my @layers  = $self->{net}->layers;
    my @weights = @{ $self->{net}->weights };
    my $rng     = Peta::NN::RNG->new($self->{seed} * 7919 + $width);
    my ($last)  = grep { $layers[$_]->type eq 'dense' } reverse 0 .. $#layers;      # the output layer keeps its size
    my $added   = 0;         # how many inputs the layer in hand has gained, at the end of each row
    my (@new, @spec);
    for my $at (0 .. $#layers) {
        my $layer = $layers[$at];
        my @own   = splice @weights, 0, scalar(() = $layer->param_names);
        if ($layer->type ne 'dense') { push @new, @own; push @spec, $layer->spec if $at < $last; next }

        my ($W, $b) = @own;
        my $out  = @$b;
        my $in   = @$W / $out;
        my $more = $at < $last && $width > $out ? $width - $out : 0;
        my $limit = sqrt(6 / ($in + $added + $out + $more));
        my @W = map { (@$W[ $_ * $in .. ($_ + 1) * $in - 1 ], (0.0) x $added) } 0 .. $out - 1;     # what was there reads nothing new
        push @W, map { (2 * $rng->uniform - 1) * $limit } 1 .. $more * ($in + $added);            # a new unit reads everything
        push @new, \@W, [ @$b, (0.0) x $more ];
        push @spec, [ dense => $out + $more ] if $at < $last;
        $added = $more;
    }
    $self->{layers} = \@spec;
    $self->{net}    = $self->_network(\@spec)->set_weights(\@new);
    delete @$self{qw(inference inference_of)};
    return $self;
}

# How many rows the embedding table needs: the two reserved tokens, the
# characters, and every value of every parameter.
sub _token_rows ($self) {
    my $rows = 2 + keys %{ $self->{vocab} };
    $rows += keys %$_ for @{ $self->{params} // [] };
    return $rows;
}

# A network for this model's reading and labels: the given hidden layers and
# an output layer of one unit per label.
sub _network ($self, $hidden) {
    return Peta::NN->new(
        input   => { tokens => $self->_tokens, vocab => $self->_token_rows },
        layers  => [ @$hidden, [ dense => scalar @{ $self->{labels} } ] ],
        loss    => 'softmax',
        seed    => $self->{seed},
        backend => $self->{backend},
    );
}

# Train the network on the pairs, with the labels the model has.
sub _train ($self, $pairs, %train) {
    my $validate = delete $train{validate};
    my $weight   = delete $train{weight};
    my %index;
    @index{ @{ $self->{labels} } } = 0 .. $#{ $self->{labels} };

    # [tokens, class, weight]; one pair may be several decisions, all of its weight.
    my @data = map {
        my $counts = $weight ? $weight->(@$_) : undef;
        map { [ $_->[0], $index{ $_->[1] }, $counts ] } $self->_decisions(@$_)
    } @$pairs;

    # A validation pair whose answer is a label the model does not have cannot
    # be scored by the loss; accuracy() will count it as the miss it is.
    my @held = map { [ $_->[0], $index{ $_->[1] } ] } grep { exists $index{ $_->[1] } }
               map { $self->_decisions(@$_) } @{ $validate // [] };
    $self->{net}->train(data => \@data, (@held ? (validate => \@held) : ()), %train);
    return $self;
}

# A trainable model from a model file: what export() wrote is enough to grow
# the training leg's side back. The architecture follows from the layers in
# the file; the weights are the file's, so as coarse as it stored them.
# tune() goes on from there.
sub from_model ($class, $file, %arg) {
    my $data = Peta::NN::Inference::read_file($file, $Peta::NN::Inference::FORMAT);
    my $read = eval { Peta::NN::Inference->new($data) } or die $@ =~ s/\Amalformed model:/$file is a malformed model:/r;

    my @layers = @{ $read->{layers} };        # checked, and with their weights unpacked
    my @hidden = map { $_->{type} eq 'embed' ? [ embed => $_->{dim} ]
                     : $_->{type} eq 'dense' ? [ dense => scalar @{ $_->{weights}[1] } ]
                     :                         $_->{type} } @layers;
    die "$file does not end in a dense layer\n" if !ref $hidden[-1] || $hidden[-1][0] ne 'dense';
    pop @hidden;                                # the output layer: _network adds it, one unit per label

    my $self = $class->new(%$data{qw(kind window side radius given)}, layers => \@hidden, %arg);
    @$self{qw(vocab labels)} = @$data{qw(vocab labels)};
    $self->{params} = $data->{params} // [];
    $self->{net}    = $self->_network(\@hidden)->set_weights([ map { @{ $_->{weights} } } @layers ]);
    return $self;
}

# --- trained on data, to a goal ----------------------------------------------------

# The pairs this model learns from, of some data: what it reads, what it
# answers and what it is given are fields of the records.
sub _pairs_of ($self, $data) {
    defined $self->{$_} or die "a model that is trained on data says which field it reads and which it answers: from => ..., to => ...\n" for qw(from to);
    return $data->pairs(from => $self->{from}, to => $self->{to}, given => $self->{given} // []);
}

# Train the model on data (Peta::NN::Data): on the records that are not held
# out, reading the field `from`, answering the field `to`, given the fields
# `given`. A model with a goal is trained until it gets there, by a job
# (Peta::NN::Job): `unseen` is the share of records it was not shown that it
# has to answer right, and every other name is a mark of the data, the share
# of those records it has to. Without a goal it is fitted once, with the
# held-out records to say when to stop. Options:
#   train    what goes to the training itself (batch, lr, epochs, ...)
#   search   for a goal: the widths to try, { scale => [min, max], start => N }
#   budget   for a goal: { seconds => N, ms => N per answer }
#   backend  where; the fastest there is unless named
sub train ($self, $data, %how) {
    # What the model was told when it was made, and over that what this call says.
    %how = (%how, map { $_ => { %{ $self->{how}{$_} // {} }, %{ $how{$_} // {} } } } grep { $self->{how}{$_} || $how{$_} } qw(train search budget));
    my $pairs = $self->_pairs_of($data->shown);
    die "there are no records to train on\n" if !@$pairs;
    my $goal = $self->{goal};
    $self->{backend} = $how{backend} if defined $how{backend};
    $self->{backend} //= $ENV{PETA_NN_BACKEND} // 'auto';
    if (!$goal) {
        my $held = $self->_pairs_of($data->held);
        $self->fit($pairs, (@$held ? (validate => $held, patience => $PATIENCE) : ()), epochs => $EPOCHS, %{ $how{train} // {} });
        return $self;
    }

    require Peta::NN::Job;
    my $key    = sub ($pair) { join "\x{1f}", @$pair[ 0, 2 .. $#$pair ] };
    my %marked = map { $_ => { map { $key->($_) => 1 } @{ $self->_pairs_of($data->shown->marked($_)) } } } grep { $_ ne 'unseen' } keys %$goal;
    my $job = Peta::NN::Job->new(
        model    => { map { $_ => $self->{$_} } grep { defined $self->{$_} } qw(kind window side radius given) },
        pairs    => $pairs,
        fidelity => { (defined $goal->{unseen} ? (all => $goal->{unseen}) : ()), map { $_ => $goal->{$_} } keys %marked },
        subsets  => { map { my $set = $marked{$_}; ($_ => { of => 'train', where => sub ($pair) { $set->{ $key->($pair) } } }) } keys %marked },
        (%marked ? (always_train => sub ($pair) { my $k = $key->($pair); scalar grep { $_->{$k} } values %marked }) : ()),
        backend  => $self->{backend},
        seed     => $self->{seed},
        search   => { %SEARCH, %{ $how{search} // {} } },
        (map { $_ => $how{$_} } grep { defined $how{$_} } qw(budget train)),
    );
    my $trained = $job->run;
    @$self{qw(layers side vocab labels params net)} = @$trained{qw(layers side vocab labels params net)};
    delete @$self{qw(inference card)};
    $self->{report}  = $job->report;
    $self->{reached} = $job->result;
    return $self;
}

# What the job that trained the model has to say, and what it measured; for
# a model trained to a goal.
sub report  ($self) { return $self->{report} }
sub reached ($self) { return $self->{reached} }

# How the model does on data: the share of records it answers exactly, of
# those that are held out (`unseen`), and of each mark of the data, of its
# records that are not held out: those are the ones a goal is about.
sub score ($self, $data) {
    my %of = (unseen => $data->held, map { $_ => $data->shown->marked($_) } $data->marks);
    return { map { my $pairs = $self->_pairs_of($of{$_}); @$pairs ? ($_ => $self->accuracy($pairs)) : () } keys %of };
}

# The model as the inference leg's data: how it reads a string, its labels,
# and its layers with their weights as lists.
sub data ($self) {
    die "the model has not been trained\n" if !$self->{net};
    my @weights = @{ $self->{net}->weights };    # in layer order, as many lists as each layer has parameters
    my @layers  = map {
        {   type    => $_->type,
            ($_->type eq 'embed' ? (dim => $_->{dim}) : ()),
            weights => [ splice @weights, 0, scalar(() = $_->param_names) ],
        }
    } $self->{net}->layers;
    return { %$self{@READING_KEYS}, layers => \@layers };
}

# The inference object for the weights as they are now. It is rebuilt when
# the network has been updated since, so it is safe to ask during training.
sub inference ($self) {
    my $generation = $self->{net} ? $self->{net}->generation : die "the model has not been trained\n";
    if (!$self->{inference} || $self->{inference_of} != $generation) {
        $self->{inference}    = Peta::NN::Inference->new($self->data);
        $self->{inference_of} = $generation;
    }
    return $self->{inference};
}

# The model's answer for a string and its parameters; in list context also
# its confidence (for rewrite: that of its least certain character).
sub predict ($self, $text, @values) { return $self->inference->predict($text, @values) }

sub predict_all ($self, $texts, @values) { return $self->inference->predict_all($texts, @values) }

# Every answer the model considers, with its probability; see Peta::NN::Inference.
sub distribution ($self, $text, @values) { return $self->inference->distribution($text, @values) }

# One distribution for several strings together; class models only.
sub pooled ($self, $texts, @values) { return $self->inference->pooled($texts, @values) }

# This model as one that answers on the graphics card, when that is where it
# is trained and it is of a kind the card answers for (class models, and edit
# models that rewrite the end): the weights as they are now, in single
# precision. Nothing otherwise.
sub _on_card ($self) {
    my $net = $self->{net} or die "the model has not been trained\n";
    return if $net->backend ne 'gpu' || $self->{kind} eq 'rewrite' || $self->{kind} eq 'edit' && $self->{side} ne 'right';
    if (!$self->{card} || $self->{card_of} != $net->generation) {
        require Peta::NN::Fused;
        my @params = map { \(my $n = $_) } 0 .. $#{ $self->{params} // [] };
        $self->{card} = Peta::NN::Fused->new(
            models => { model => $self->data },
            steps  => [ { model => 'model', params => \@params, ($self->{kind} eq 'class' ? (name => 'answer', classify => 1) : ()) } ],
            engine => 'gpu',
        );
        $self->{card_of} = $net->generation;
    }
    return $self->{card};
}

# The pairs this model cannot get right together with all the others: those
# it reads exactly as it reads some other pair that has a different answer.
# The model sees a window of a string, not the string, so two strings that
# differ outside it are one and the same to it (with nine characters from
# the end, frühschichten and geschichten are both "schichten"). No training
# changes that; a wider window does. Returned as [pair, another answer, a
# pair that has it], one for each such pair.
sub indistinct ($self, $pairs) {
    die "the model has not been trained\n" if !$self->{net};
    my (%answers, @read);
    for my $pair (@$pairs) {
        my @keys;
        for my $decision ($self->_decisions(@$pair)) {
            my $key = join ' ', @{ $decision->[0] };
            $answers{$key}{ $decision->[1] } //= $pair;
            push @keys, [ $key, $decision->[1] ];
        }
        push @read, [ $pair, \@keys ];
    }
    my @found;
    for my $read (@read) {
        my ($pair, $keys) = @$read;
        for my $key (@$keys) {
            my ($other) = grep { $_ ne $key->[1] } sort keys %{ $answers{ $key->[0] } } or next;
            push @found, [ $pair, $other, $answers{ $key->[0] }{$other} ];
            last;
        }
    }
    return @found;
}

# Share of pairs reproduced exactly. Pairs with the same parameters are
# answered in one pass.
sub accuracy ($self, $pairs, %how) {
    my %same;
    push @{ $same{ join "\x{1f}", @$_[ 2 .. $#$_ ] } }, $_ for @$pairs;
    my $card  = $how{where_trained} ? $self->_on_card : undef;
    my $right = 0;
    for my $group (values %same) {
        my @values  = @{ $group->[0] }[ 2 .. $#{ $group->[0] } ];
        my $inputs  = [ map { $_->[0] } @$group ];
        my @answers = !$card                  ? map { $_->[0] } @{ $self->inference->answers($inputs, @values) }
                    : $self->{kind} eq 'class' ? map { $_->{answers}{answer} } @{ $card->run($inputs, @values) }
                    :                           map { $_->{text} } @{ $card->run($inputs, @values) };
        $right += grep { $answers[$_] eq $group->[$_][1] } 0 .. $#$group;
    }
    return $right / @$pairs;
}

# The training state as plain data: the model's definition and its weights
# at full precision. It is what a state file holds, and what carries a model
# from one process to another.
sub state ($self) {
    die "the model has not been trained\n" if !$self->{net};
    return { %$self{ @CONFIG_KEYS, @LEARNED_KEYS }, format => $STATE_FORMAT, version => $VERSION,
             net => Peta::NN::freeze_state($self->{net}->state) };
}

# The model a training state describes. The network inside refuses weights
# that do not fit its definition.
sub from_state ($class, $state, %arg) {
    die "this is not a training state\n"
        if ref $state ne 'HASH' || ($state->{format} // '') ne $STATE_FORMAT || ref $state->{net} ne 'HASH' || ref $state->{layers} ne 'ARRAY';
    my $self  = $class->new(%$state{@CONFIG_KEYS}, %arg);
    @$self{@LEARNED_KEYS} = @$state{@LEARNED_KEYS};
    $self->{params} //= [];
    $self->{net} = Peta::NN->from_state(Peta::NN::thaw_state($state->{net}), backend => $self->{backend});
    return $self;
}

# The training state as a file (by convention *.state), to be loaded again by
# this class.
sub save ($self, $file) {
    Storable::nstore($self->state, $file);
    return $self;
}

# The file is read as plain data.
sub load ($class, $file, %arg) {
    my $model = eval { $class->from_state(Peta::NN::Inference::read_file($file, $STATE_FORMAT), %arg) };
    die $@ =~ s/\Athis is not a training state/$file is a malformed training state/r if !$model;
    return $model;
}

# Write the model file that ships (by convention *.model): the inference
# leg's data with the weights packed, and what the file says of itself.
#   file          where to write it
#   bits          32 (the default) for 32-bit floats, 8 for signed bytes with
#                 a scale per weight array: a quarter of the size, at some
#                 cost in accuracy that is the caller's to measure
#   name, description, source, fidelity
#                 free-form: what the model is, what it was trained from, and
#                 the fidelity measured for it ({ name => share })
# Peta::NN::Inference->load reads the file.
sub export ($self, %arg) {
    my $file = $arg{file} // die "file => path is required\n";
    my $bits = $arg{bits} // $EXPORT_BITS;
    die "a model file stores weights with 8 or 32 bits, not '$bits'\n" if $bits != 8 && $bits != 32;
    my $data = $self->data;
    for my $layer (@{ $data->{layers} }) {
        $layer->{weights} = [ map { Peta::NN::Inference::pack_weights($_, $bits) } @{ $layer->{weights} } ];
    }
    Storable::nstore({
        %$data,
        format  => $Peta::NN::Inference::FORMAT,
        layout  => $Peta::NN::Inference::LAYOUT,
        version => $VERSION,
        bits    => $bits,
        meta    => { created => time, map { $_ => $arg{$_} } grep { defined $arg{$_} } @META_KEYS },
    }, $file);
    return $self;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Model - train a micro model from string pairs, export it as a model file

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Model;

    my $model = Peta::NN::Model->new(
        kind   => 'edit',                                  # rewrite the end of a word
        window => 5,                                       # reading its last 5 characters
        layers => [ [embed => 8], [dense => 32], 'relu' ], # the output layer is added
    );
    $model->fit(\@pairs, epochs => 12, batch => 16);       # [ ['Apfel', 'Äpfel', 'plural'], ... ]

    print scalar $model->predict('Vogel', 'plural');       # Vögel
    printf "%.1f%%\n", 100 * $model->accuracy(\@held_out);

    $model->export(file => 'deu-noun.model', bits => 8, name => 'German noun forms');

and wherever that file goes, with only the inference leg installed:

    use Peta::NN::Inference;
    my $noun = Peta::NN::Inference->load('deu-noun.model');
    print scalar $noun->predict('Vogel', 'plural');

=head1 KINDS

=over

=item class

The output of a pair is a label for the whole input. The network reads
C<window> characters from the C<side>: 'right' (the default), 'left', or
'both' for the first and the last C<window> characters together.

=item edit

The output is the input with one end, or both, rewritten. Each pair is
reduced to an edit, "cut this many characters, add this text", and the
network learns to choose the edit. With C<side> 'right' (the default) it
reads and rewrites the end of the string, with 'left' its beginning, with
'both' both at once; 'auto' picks 'left' or 'right', whichever end the
training pairs differ at in fewer ways.

=item rewrite

Input and output have the same length and each character is decided on its
own, from the C<radius> characters on either side of it.

=back

=head1 PARAMETERS

Whatever follows input and output in a pair is a parameter: C<[$in, $out,
'dative']>, C<[$in, $out, 'feminine', 'comparative']>. The model treats each
as an opaque value and learns what to do for it; it has no notion of what
the value means. All pairs of a model have the same number of parameters,
and a call (C<predict>, C<predict_all>, C<distribution>) passes the same
number after the string.

=head1 TRAINING FURTHER

C<fit> starts from nothing. C<tune> goes on training the network a model
already has, with the same arguments: on corrections, or on more data.
It keeps what the model can read and answer; a pair whose answer is not one
of the model's labels is refused, since that needs a new output and a fit
from scratch.

C<widen> gives a trained model wider hidden layers and leaves its answers as
they are; training goes on from there with C<tune>. A model that has learned
all its size allows is given room this way, and not replaced by a larger one
that starts from nothing.

A model to tune comes from C<load> (a training state) or from
C<from_model> (a model file, as shipped: the architecture is read back from
its layers, the weights are as coarse as the file stored them).

=head1 TWO FILES

C<save> writes the training state, by convention C<*.state>: everything
needed to load the model into this class again, weights at full precision.
C<export> writes the model file for the inference leg, by convention
C<*.model>: smaller, with 32-bit or 8-bit weights, and all a user of the
model needs.

Each kind carries its own marker and is refused by the loader of the other.

=head1 METHODS

=head2 new

    my $model = Peta::NN::Model->new(kind => 'edit', window => 6, side => 'right', layers => [...], seed => 1, backend => 'auto');

C<kind> is required. C<window> defaults to 6, C<side> to C<right>, C<radius>
(for C<rewrite>) to 2, C<layers> to an embedding of 8 and one hidden layer of
32. What a model reads can be said in one table instead: C<< reads => { end
=> 8 } >>, C<< { front => 2 } >>, C<< { both => 5 } >>, or for a rewrite model
C<< { around => 2 } >>.

For a model that is trained on a L<Peta::NN::Data>: C<from> and C<to>, the
fields it reads and answers; C<given>, the fields it is given beside, which
are then the names of its parameters; and C<goal>, what it has to reach
((see C<train>); and C<train>, C<search> and C<budget>, the options its
C<train> then has without being told again.

=head2 train

C<train($data, %options)>: trains the model on a L<Peta::NN::Data>: on the
records that are not held out, reading the field C<from>, answering the field
C<to>, given the fields C<given> (all said when the model was made). With a
C<goal>, C<< { unseen => 0.98, core => 1 } >>, it is trained by a
L<Peta::NN::Job> until it answers that share of the records it was not shown
and of the records of each named mark of the data; without, it is fitted
once and the held-out records say when to stop. Options: C<train> (what goes
to the training: C<batch>, C<lr>, ...), C<search> and C<budget> (the job's),
C<backend>.

=head2 score

C<score($data)>: the share of records the model answers exactly, of those
held out (C<unseen>), and of each mark of the data, of its records that are
not held out; as a table.

=head2 report

What the job that trained the model to its goal has to say.

=head2 reached

What that job measured.

=head2 fit

C<fit(\@pairs, %train)>: learns from C<[input, output, parameters...]> pairs,
starting from nothing. C<validate> (pairs that are not trained on) and
C<weight> (a sub giving how much a pair counts) are the model's own
arguments; everything else goes to L<Peta::NN/train>. Returns the model.

=head2 tune

C<tune(\@pairs, %train)>: goes on training the network the model has. What
the model can read and answer stays as it is.

=head2 widen

C<widen($width)>: makes the hidden layers C<$width> units wide without
changing an answer; C<tune> then trains the wider model on. A new unit reads
with random weights and is read with zeros.

=head2 predict

C<predict($string, @parameters)>: the answer; in list context also its
confidence.

=head2 predict_all

C<predict_all(\@strings, @parameters)>: the answers, in order.

=head2 distribution

Every answer the model considers, with its probability; see
L<Peta::NN::Inference/distribution>.

=head2 pooled

One distribution for several strings together; class models only.

=head2 accuracy

C<accuracy(\@pairs)>: the share of pairs reproduced exactly, by the inference
leg. With C<< where_trained => 1 >> a model that is trained on the graphics
card is measured there, in single precision and many times faster; any
other model as always.

=head2 indistinct

C<indistinct(\@pairs)>: the pairs the model reads exactly as it reads another
pair with a different answer, each as C<[pair, the other answer, a pair that
has it]>. It cannot get such pairs right together, whatever the training; a
wider window tells them apart.

=head2 labels

The answers the model can give.

=head2 parameters

The values known for each parameter: one sorted list per position.

=head2 given

The names of the parameters, in their order, if the model was given any
(C<< given => ['gender'] >> when it was made). A model whose parameters have
names is asked by name: C<< predict($noun, gender => 'neuter') >>.

=head2 net

The L<Peta::NN> network inside.

=head2 inference

The L<Peta::NN::Inference> object for the weights as they are now.

=head2 data

The model as the inference leg's data: how it reads a string, its labels, and
its layers with their weights as lists.

=head2 export

C<< export(file => $path, bits => 32, name => ..., description => ..., source => ..., fidelity => {...}) >>:
writes the model file that ships. C<bits> is 32 or 8.

=head2 from_model

C<< Peta::NN::Model->from_model($file) >>: a trainable model from a model
file.

=head2 state

The training state as plain data: the model's definition and its weights at
full precision.

=head2 from_state

C<< Peta::NN::Model->from_state($state, backend => ...) >>: the model a
training state describes.

=head2 save

Writes the training state to a file, by convention C<*.state>.

=head2 load

C<< Peta::NN::Model->load($file, backend => ...) >>: the model of a state
file.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
