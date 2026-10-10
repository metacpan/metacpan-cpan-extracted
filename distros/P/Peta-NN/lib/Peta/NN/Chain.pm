package Peta::NN::Chain;
# ABSTRACT: models put together into a model

# Models put together into a model.
#
#   my $plural = chain(umlaut => $umlaut, ending => $ending);
#   print $plural->predict('apfel', gender => 'masculine');
#
# A chain is what one writes; Peta::NN::Pipeline and Peta::NN::Fused are what
# runs it. Its parts are named and come in order, and each part is a model,
# a model file, or another chain, whose parts then become parts of this one:
# what is put together is again something to put together.
#
# What a part does follows from what it is:
#
#   a model that rewrites (edit, rewrite)   its answer is the string the next
#                                           part reads
#   a model that classifies (class)         its answer is kept under the
#                                           part's name; the string passes on
#   pooled($model)                          the same for a whole text at once:
#                                           every string of the text is
#                                           evidence, all get the one answer
#   chosen($part => { answer => model })    one of several models, chosen for
#                                           each string by what the part
#                                           named $part answered; '*' stands
#                                           for every answer not listed
#
# Parameters go by name. A part's model is given `gender`: if an earlier part
# of the chain is called gender, its answer is the value; if not, gender is
# an argument of the chain, and whoever asks the chain names it. Two parts
# that are given the same name are given the same value.
#
# A chain answers through the pipeline of its parts, or through the same
# fused when it is asked to (on 'gpu'), which is the same function. It is
# saved as one file, its parts in it as they are.

use v5.36;

use Exporter qw(import);
use Storable ();

use Peta::NN::Inference;
use Peta::NN::Pipeline;

our $VERSION = '0.2610090';
our @EXPORT_OK = qw(chain pooled chosen fixed train_together);

our $FORMAT = 'Peta::NN chain';

# The layout of a chain's file.
#   1  the parts as they were given (models' data under their names), and
#      the arguments' names
our $LAYOUT = 1;

my $ANY = '*';

# --- how parts are written --------------------------------------------------------

# chain(name => part, ...): the same as Peta::NN::Chain->new.
sub chain (@parts) { return __PACKAGE__->new(@parts) }

# A classifying model that judges a whole text at once.
sub pooled ($model) { return bless { model => $model }, 'Peta::NN::Chain::Pooled' }

# A model with some of what it is given settled once and for all:
# fixed($model, genus => 'masculine'). The chain then does not ask for it.
sub fixed ($model, %values) {
    die "fixed(\$model, name => value, ...)\n" if !%values;
    return bless { model => $model, values => \%values }, 'Peta::NN::Chain::Fixed';
}

# One of several models, chosen by the answer of an earlier part:
# chosen(language => { ces => $czech, deu => $german, '*' => $other }).
sub chosen ($by, $models) {
    die "chosen(part => { answer => model, ... })\n" if ref $by || ref $models ne 'HASH' || !%$models;
    return bless { by => $by, models => $models }, 'Peta::NN::Chain::Chosen';
}

# Train models that have nothing to do with each other side by side:
# train_together({ name => model, ... }, $data, %options), the data and the
# options being those of a chain's train(). The names are what the data is
# given by where the models learn from different data.
sub train_together ($models, $data, %how) {
    __PACKAGE__->new(map { $_ => $models->{$_} } sort keys %$models)->train($data, %how);
    return;
}

# --- putting it together -------------------------------------------------------------

# A model as a part: what it is called, and the model data it answers from.
sub _model ($name, $model) {
    if (ref $model eq 'Peta::NN::Chain::Fixed') {
        my $of = _model($name, $model->{model});
        defined { map { $_ => 1 } @{ $of->{given} } }->{$_} or die "the part '$name' fixes '$_', which its model is not given\n" for keys %{ $model->{values} };
        return { %$of, fixed => $model->{values} };
    }
    # A model that is yet to be trained: it is a part, and the chain cannot answer until train().
    return { name => $name, pending => $model, kind => $model->{kind}, given => [ @{ $model->{given} // [] } ] }
        if ref $model && ref $model ne 'HASH' && $model->isa('Peta::NN::Model') && !$model->net;
    my $data = !ref $model          ? Peta::NN::Inference::read_file($model, $Peta::NN::Inference::FORMAT)
             : ref $model eq 'HASH' ? $model
             : $model->can('data')  ? $model->data
             :                        die "the part '$name' is not a model, a model file or a chain\n";
    my $read = eval { Peta::NN::Inference->new($data) } or die "the part '$name': $@";
    die "the part '$name' has parameters without names; a model in a chain is given names for them (given => [...])\n"
        if @{ $data->{params} // [] } && !$data->{given};
    return { name => $name, data => $data, model => $read, kind => $data->{kind}, given => [ @{ $data->{given} // [] } ],
             (ref $model && ref $model ne 'HASH' && $model->isa('Peta::NN::Model') ? (trained => $model) : ()) };
}

# name => part, in order. A part is a model (Peta::NN::Model, trained;
# Peta::NN::Inference; a model file's path), pooled(...), chosen(...), or a
# chain.
sub new ($class, @parts) {
    die "a chain is made of name => part, name => part, ...\n" if !@parts || @parts % 2;
    my $self = bless { parts => [], model => {} }, $class;
    while (my ($name, $part) = splice @parts, 0, 2) {
        die "a part's name is plain text\n" if ref $name || !length $name;
        if (ref $part && ref $part ne 'HASH' && $part->isa(__PACKAGE__)) {      # a chain: its parts are parts of this one
            $self->_add(%$_) for @{ $part->{parts} };
        }
        elsif (ref $part eq 'Peta::NN::Chain::Chosen') {
            my %models = map { $_ => _model("$name-" . ($_ eq $ANY ? 'other' : $_), $part->{models}{$_}) } keys %{ $part->{models} };
            $self->_add(name => $name, by => $part->{by}, models => \%models);
        }
        elsif (ref $part eq 'Peta::NN::Chain::Pooled') { $self->_add(name => $name, pooled => 1, models => { $ANY => _model($name, $part->{model}) }) }
        else                                           { $self->_add(name => $name, models => { $ANY => _model($name, $part) }) }
    }
    return $self->_wire;
}

# One more part: { name, models => { answer or '*' => model }, by, pooled }.
sub _add ($self, %part) {
    die "the chain has two parts called '$part{name}'\n" if grep { $_->{name} eq $part{name} } @{ $self->{parts} };
    for my $model (values %{ $part{models} }) {
        die "the chain has two models called '$model->{name}'\n" if $self->{model}{ $model->{name} };
        $self->{model}{ $model->{name} } = $model;
    }
    my ($any) = values %{ $part{models} };
    my $class = $any->{kind} eq 'class';
    die "the part '$part{name}' chooses between models that classify and models that rewrite\n"
        if grep { ($_->{kind} eq 'class') != $class } values %{ $part{models} };
    die "the part '$part{name}' is pooled, which is for a model that classifies\n" if $part{pooled} && !$class;
    push @{ $self->{parts} }, { %part, classifies => $class ? 1 : 0 };
    return;
}

# The pipeline of the parts: each parameter is an earlier part's answer if a
# part that classifies has its name, and an argument of the chain if not.
sub _wire ($self) {
    delete @$self{qw(pipeline fused)};
    my (%answers, @arguments, %position, @steps);
    for my $part (@{ $self->{parts} }) {
        my %step;       # only a part that classifies has an answer to keep under its name
        @step{qw(name classify pool)} = ($part->{name}, 1, $part->{pooled} ? 1 : 0) if $part->{classifies};

        my @models = values %{ $part->{models} };
        my @given  = @{ $models[0]{given} };
        die "the models the part '$part->{name}' chooses from are not given the same parameters\n"
            if grep { "@{ $_->{given} }" ne "@given" } @models;
        my $fixed = $models[0]{fixed} // {};
        $step{params} = [
            map {
                my $name = $_;
                defined $fixed->{$name} ? "$fixed->{$name}"
                    : $answers{$name}   ? { answer => $name }
                    :                      \($position{$name} //= do { push @arguments, $name; $#arguments })
            } @given
        ];

        if (defined $part->{by}) {
            die "the part '$part->{name}' chooses by '$part->{by}', which is not an earlier part that classifies\n" if !$answers{ $part->{by} };
            $step{model} = { $part->{by} => { map { $_ => $part->{models}{$_}{name} } keys %{ $part->{models} } } };
        }
        else { $step{model} = $models[0]{name} }
        push @steps, \%step;
        $answers{ $part->{name} } = 1 if $part->{classifies};
    }
    $self->{given} = \@arguments;
    $self->{steps} = \@steps;
    # It answers once all its models are trained.
    $self->{pipeline} = Peta::NN::Pipeline->new(models => { map { $_ => $self->{model}{$_}{model} } keys %{ $self->{model} } }, steps => \@steps)
        if !grep { $_->{pending} } values %{ $self->{model} };
    return $self;
}

# --- what it is ---------------------------------------------------------------------------

# The names of its arguments, in the order the parts first need them.
sub given ($self) { return @{ $self->{given} } }

# The names of its parts, in order.
sub parts ($self) { return map { $_->{name} } @{ $self->{parts} } }

# The names of its models, in the order of the parts; a part that chooses has several.
sub models ($self) { return map { my $part = $_; map { $part->{models}{$_}{name} } sort keys %{ $part->{models} } } @{ $self->{parts} } }

# One of its models, as the inference leg's.
sub model ($self, $name) {
    my $model = $self->{model}{$name} // die "this chain has no model '$name' (it has: @{[ $self->models ]})\n";
    return $model->{model} // die "the model '$name' is not trained yet; train() the chain\n";
}

# The names of the parts that classify: what a record's answers are.
sub answers ($self) { return map { $_->{name} } grep { $_->{classifies} } @{ $self->{parts} } }

sub n_params ($self) {
    my $n = 0;
    $n += $self->model($_)->n_params for $self->models;
    return $n;
}

# The pipeline that runs it.
sub pipeline ($self) {
    # A model that was to be trained may have been, by its own train() or by another chain's.
    my @since = grep { $_->{pending} && $_->{pending}->net } values %{ $self->{model} };
    for my $part (@since) {
        my $model = delete $part->{pending};
        @$part{qw(data model trained)} = ($model->data, $model->inference, $model);
    }
    $self->_wire if @since;
    return $self->{pipeline} // die sprintf "this chain cannot answer yet: %s not trained; train() it\n",
        join ', ', map { "'$_' is" } grep { $self->{model}{$_}{pending} } $self->models;
}

# The same fused, on 'cpu' or 'gpu'; dies with the reason if its parts do not fuse.
sub fused ($self, $engine = 'cpu') {
    require Peta::NN::Fused;
    $self->pipeline;
    return $self->{fused}{$engine} //= Peta::NN::Fused->new(
        models => { map { $_ => $self->{model}{$_}{data} } keys %{ $self->{model} } }, steps => $self->{steps}, engine => $engine);
}

# Where it answers from now on: 'pipeline' (as it starts), or fused on 'cpu'
# or 'gpu'. Returns the chain.
sub on ($self, $where) {
    die "a chain answers through its 'pipeline', or fused on 'cpu' or 'gpu', not on '$where'\n" if $where !~ /\A(?:pipeline|cpu|gpu)\z/;
    $self->fused($where) if $where ne 'pipeline';
    $self->{on} = $where;
    return $self;
}

sub _runner ($self) {
    my $on = $self->{on} // 'pipeline';
    return $on eq 'pipeline' ? $self->pipeline : $self->fused($on);
}

# --- training -----------------------------------------------------------------------------------

# Train the models of the chain that are not trained yet, on data
# (Peta::NN::Data), each as Peta::NN::Model's train() does it: on the fields
# it reads, answers and is given, to its goal if it has one. They have
# nothing to do with each other, so they are trained side by side, as many
# at a time as PETA_NN_WORKERS says. The options are those of a model's
# train(). Returns the chain, which can answer now.
sub train ($self, $data, %how) {
    require Peta::NN::Model;
    require Peta::NN::Parallel;
    my @pending = grep { $_->{pending} } map { $self->{model}{$_} } $self->models;
    # One data for all, or for each model its own: { model => data, ..., '*' => data for the others }.
    my $data_of = sub ($name) {
        return $data if ref $data ne 'HASH';
        return $data->{$name} // $data->{$ANY} // die "there is no data to train the model '$name' on\n";
    };
    my @done = Peta::NN::Parallel::in_parallel(Peta::NN::Parallel::workers(), map {
        my ($model, $on) = ($_->{pending}, $data_of->($_->{name}));
        sub { $model->train($on, %how); return { state => $model->state, report => $model->report, reached => $model->reached } }
    } @pending);
    for my $part (@pending) {
        my ($model, $done) = (delete $part->{pending}, shift @done);
        # What a child process trained comes back as a training state, into the model the caller holds.
        my $trained = Peta::NN::Model->from_state($done->{state}, backend => $model->{backend});
        @$model{qw(layers side vocab labels params net)} = @$trained{qw(layers side vocab labels params net)};
        delete @$model{qw(inference card)};
        @$model{qw(report reached)} = @$done{qw(report reached)};
        @$part{qw(data model trained)} = ($model->data, $model->inference, $model);
    }
    return $self->_wire;
}

# What the jobs that trained the chain's models have to say, model by model;
# for the models that were trained to a goal.
sub report ($self) {
    $self->pipeline;
    return join '', map { my $of = $self->{model}{$_}{trained}; $of && $of->report ? "== $_ ==\n" . $of->report . "\n" : () } $self->models;
}

# How the chain does on data: the share of records for which it turns the
# field `from` into the field `to`, of those that are held out (`unseen`)
# and of each mark of the data. Its arguments are the records' fields of the
# same names. With answer => a part that classifies, it is that part's
# answer that is held against `to`.
sub score ($self, $data, %arg) {
    defined $arg{$_} or die "score(\$data, from => the field the chain reads, to => the field it is to give)\n" for qw(from to);
    my @names = $self->given;
    my %of    = (unseen => $data->held, map { $_ => $data->shown->marked($_) } $data->marks);
    my %score;
    for my $name (keys %of) {
        my @records = $of{$name}->records or next;
        my %together;       # the records that are asked with the same arguments
        push @{ $together{ join "\x{1f}", @$_{@names} } }, $_ for @records;
        my $right = 0;
        for my $group (values %together) {
            my $answers = $self->run([ map { $_->{ $arg{from} } } @$group ], map { $_ => $group->[0]{$_} } @names);
            $right += grep { (defined $arg{answer} ? $answers->[$_]{answers}{ $arg{answer} } : $answers->[$_]{text}) eq $group->[$_]{ $arg{to} } } 0 .. $#$group;
        }
        $score{$name} = $right / @records;
    }
    return \%score;
}

# --- answering --------------------------------------------------------------------------------

# What a caller named, as the arguments in their order.
sub _arguments ($self, @named) {
    my @names = @{ $self->{given} };
    my $takes = @names ? 'takes ' . join(', ', map { "$_ => ..." } @names) : 'takes no arguments';
    die "this chain $takes\n" if @named != 2 * @names;
    my %named = @named;
    return map { delete $named{$_} // die "this chain $takes; '$_' is missing\n" } @names;
}

# One record per string: { text, confidence, answers => { part => answer } }.
sub run ($self, $texts, @named) {
    my @arguments = $self->_arguments(@named);
    return [ map { { text => $_->{text}, confidence => $_->{confidence}, answers => $_->{answers} } } @{ $self->_runner->run($texts, @arguments) } ];
}

# The same for texts, each a list of strings; returns the records per text.
# A pooled part answers once per text.
sub run_texts ($self, $texts, @named) {
    my @arguments = $self->_arguments(@named);
    return [ map { [ map { { text => $_->{text}, confidence => $_->{confidence}, answers => $_->{answers} } } @$_ ] } @{ $self->_runner->run_texts($texts, @arguments) } ];
}

# The chain's answer for a string: the string as its parts have rewritten
# it; in list context also its confidence, the product of the parts'.
sub predict ($self, $text, @named) {
    my ($record) = @{ $self->run([$text], @named) };
    return wantarray ? @$record{qw(text confidence)} : $record->{text};
}

# The answers for many strings at once, in their order.
sub predict_all ($self, $texts, @named) {
    return map { $_->{text} } @{ $self->run($texts, @named) };
}

# --- a file -----------------------------------------------------------------------------------

# A model's data as it goes into a file: as it came from its own file, or
# with its weights packed in full if it came as a trained model.
sub _stored ($data, $bits) {
    return $data if !defined $bits || !grep { ref eq 'ARRAY' } map { @{ $_->{weights} } } @{ $data->{layers} };
    return {
        %$data,
        format => $Peta::NN::Inference::FORMAT,
        layout => $Peta::NN::Inference::LAYOUT,
        bits   => $bits,
        layers => [ map { +{ %$_, weights => [ map { Peta::NN::Inference::pack_weights($_, $bits) } @{ $_->{weights} } ] } } @{ $data->{layers} } ],
    };
}

# With how many bits each model's weights went into the file at the last
# save(): { model => 8 or 32 }; nothing for a model that came from a file.
sub stored ($self) { return $self->{stored} }

# How many bits a model's weights are stored with. A model that came from a
# file stays as it is. One that was trained here is stored with 32 bits; or,
# when the caller says by which data to judge, with 8 if the model as stored
# then still answers every record of that data the way the trained one does,
# and with 32 if not.
sub _bits_for ($part, $judge) {
    my $data = $part->{data};
    return undef if !grep { ref eq 'ARRAY' } map { @{ $_->{weights} } } @{ $data->{layers} };      # as it came from its file
    my $trained = $part->{trained};
    return 32 if !$judge || !$trained || !defined $trained->{from};
    my $records = ref $judge eq 'HASH' ? $judge->{ $part->{name} } // $judge->{$ANY} : $judge;
    return 32 if !$records;
    my $pairs = $records->pairs(from => $trained->{from}, to => $trained->{to}, given => $trained->{given} // []);
    my %with;       # the values given => the strings asked with them
    push @{ $with{ join "\x{1f}", @$_[ 2 .. $#$_ ] } }, $_ for @$pairs;
    my $small = Peta::NN::Inference->new(_stored($data, 8));
    for my $group (values %with) {
        my @values = @{ $group->[0] }[ 2 .. $#{ $group->[0] } ];
        my @texts  = map { $_->[0] } @$group;
        my ($a, $b) = map { join "\x{1f}", map { $_->[0] } @{ $_->answers(\@texts, @values) } } $small, $part->{model};
        return 32 if $a ne $b;
    }
    return 8;
}

# Write the chain to one file: its parts, each model as it is. Models that
# were trained here are stored with 32-bit weights; with small => data (or
# { model => data, ... }) each of them with 8 bits if it then still answers
# every record of that data as before. A table of what the file is to say of
# itself (name, description, ...) may follow. stored() says what was done.
sub save ($self, $file, %meta) {
    my $judge = delete $meta{small};
    $self->pipeline;
    $self->{stored} = { map { $_ => _bits_for($self->{model}{$_}, $judge) } keys %{ $self->{model} } };
    Storable::nstore({
        format  => $FORMAT,
        layout  => $LAYOUT,
        version => $VERSION,
parts   => [ map { my $part = $_; my ($any) = values %{ $part->{models} };
                           +{ %$part{qw(name by pooled)}, fixed => $any->{fixed}, models => { map { $_ => $part->{models}{$_}{name} } keys %{ $part->{models} } } } } @{ $self->{parts} } ],
        models  => { map { $_ => _stored($self->{model}{$_}{data}, $self->{stored}{$_}) } keys %{ $self->{model} } },
        meta    => { created => time, %meta },
    }, $file);
    return $self;
}

# A chain from a file: a chain's file, or a single model's file, which is a
# chain of that one part (called by the file's name without its ending).
sub load ($class, $file) {
    my $data = eval { Storable::retrieve($file, 0) };
    die "$file cannot be read as a chain or a model: " . ($@ =~ s/ at \S+ line \d+.*//sr || "$!") . "\n" if ref $data ne 'HASH';
    if (($data->{format} // '') eq $Peta::NN::Inference::FORMAT) {
        my ($name) = $file =~ m{([^/]+?)(?:\.[^./]*)?\z};
        return $class->new($name => $data);
    }
    die "$file is neither a chain's file nor a model's\n" if ($data->{format} // '') ne $FORMAT;
    die sprintf "$file is in layout %s, and this version reads layout %d; save it again\n", $data->{layout} // '?', $LAYOUT if ($data->{layout} // '') ne $LAYOUT;
    die "$file is a malformed chain: no parts or no models\n" if ref $data->{parts} ne 'ARRAY' || ref $data->{models} ne 'HASH';

    my $self = bless { parts => [], model => {}, meta => $data->{meta} }, $class;
    eval {
        for my $part (@{ $data->{parts} }) {
            my %models = map {
                my $name = $part->{models}{$_};
                my $model = $data->{models}{$name} // die "the part '$part->{name}' uses the model '$name', which is not in the file\n";
                $_ => _model($name, $part->{fixed} ? fixed($model, %{ $part->{fixed} }) : $model)
            } keys %{ $part->{models} };
            $self->_add(name => $part->{name}, models => \%models, map { $_ => $part->{$_} } grep { defined $part->{$_} } qw(by pooled));
        }
        $self->_wire;
        1;
    } or die "$file is a malformed chain: $@";
    return $self;
}

# What there is to know about the chain, for a human.
sub info ($self) {
    return {
        %{ $self->{meta} // {} },
        format  => $FORMAT,
        version => $VERSION,
        kind    => 'chain',
        parts   => [ map { my $part = $_; defined $part->{by} ? "$part->{name}, chosen by $part->{by}" : $part->{pooled} ? "$part->{name}, pooled" : $part->{name} } @{ $self->{parts} } ],
        given   => [ $self->given ],
        answers => [ $self->answers ],
        weights => $self->n_params,
        models  => { map { $_ => $self->model($_)->info } $self->models },
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Chain - models put together into a model

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Chain qw(chain pooled chosen);

    # In series: apfel -> äpfel -> äpfeln
    my $plural = chain(umlaut => $umlaut, ending => $ending);
    print scalar $plural->predict('apfel', gender => 'masculine');          # äpfel

    my $dative = chain(plural => $plural, case => $case);                   # a chain in a chain
    print scalar $dative->predict('apfel', gender => 'masculine', case => 'dative');

    $dative->save('deu-noun-dative.chain');
    my $again = Peta::NN::Chain->load('deu-noun-dative.chain')->on('gpu');  # fused, on the card
    my @forms = $again->predict_all(\@nouns, gender => 'neuter', case => 'dative');

    # One model names the language of a text, and that chooses the model
    # that says what each word is.
    my $tagger = chain(
        language => pooled($language),
        class    => chosen(language => { ces => $czech, deu => $german, eng => $english }),
    );
    for my $word (@{ $tagger->run_texts([ \@words ])->[0] }) {
        print "$word->{text}: $word->{answers}{class} ($word->{answers}{language})\n";
    }

=head1 DESCRIPTION

A chain is a list of named parts, in order. A part is a model, a model
file, or another chain, whose parts become parts of this one. What a part
does follows from what it is: a model that rewrites hands its answer on as
the string the next part reads; a model that classifies has its answer kept
under the part's name, and the string passes on. C<pooled> makes a
classifying model judge a whole text at once, and C<chosen> names several
models of which an earlier part's answer chooses one per string.

Parameters go by name. If a part's model is given C<gender> and an earlier
part of the chain is called C<gender>, that part's answer is the value;
otherwise C<gender> is an argument of the chain. Two parts that are given
the same name are given the same value. C<given> lists a chain's arguments.

A chain is a model like any other: it is asked with C<predict>, saved as one
file, loaded, and put into further chains. It answers through
L<Peta::NN::Pipeline>, or, after C<< on('gpu') >> or C<< on('cpu') >>,
through the same parts fused (L<Peta::NN::Fused>), which is the same
function; not every model fuses, and C<on> says why if these do not.

=head1 FUNCTIONS

Exported on request.

=head2 chain

C<< chain(name => part, ...) >>: a chain; the same as
C<< Peta::NN::Chain->new >>.

=head2 train_together

C<< train_together({ name => $model, ... }, $data, %options) >>: trains
models that have nothing to do with each other side by side, as a chain's
C<train> does. The models are trained in place; chains they are parts of can
answer afterwards.

=head2 pooled

C<pooled($model)>: a classifying model that answers once for a whole text
(C<run_texts>).

=head2 fixed

C<< fixed($model, name => value, ...) >>: the model with some of what it is
given settled; the chain does not ask for those.

=head2 chosen

C<< chosen($part => { answer => $model, ... }) >>: one of these models for
each string, chosen by what the earlier part called C<$part> answered;
C<'*'> stands for every answer not listed.

=head1 METHODS

=head2 new

C<< Peta::NN::Chain->new(name => part, ...) >>. A part is a
L<Peta::NN::Model> (trained, or to be trained by the chain's C<train>), a
L<Peta::NN::Inference>, a model file's path, what C<pooled> or C<chosen>
give, or a chain.

=head2 load

C<< Peta::NN::Chain->load($file) >>: a chain from its file. A single model's
file loads as a chain of that one part.

=head2 save

C<< save($file, name => ..., description => ...) >>: writes the chain to one
file. A model that came from a file goes in as it is; one that was trained
here with 32-bit weights, or, with C<< small => $data >>, with 8-bit weights
if it then still answers every record of that data as before.

=head2 stored

With how many bits each model went into the file at the last C<save>.

=head2 train

C<train($data, %options)>: trains the models of the chain that are not
trained yet on a L<Peta::NN::Data>, each as L<Peta::NN::Model/train> does,
side by side. Where the models learn from different data, C<$data> is a table
C<< { model => data, '*' => data for the others } >>. Until then such a chain has parts and arguments but cannot
answer. Returns the chain.

=head2 report

What the jobs that trained the chain's models have to say, model by model.

=head2 score

C<< score($data, from => $field, to => $field) >>: the share of records for
which the chain turns the one field into the other, of the records that are
held out (C<unseen>), and of each mark of the data, of its records that are
not held out; as a table. The chain's
arguments are the records' fields of the same names. With
C<< answer => $part >> it is that classifying part's answer that is compared.

=head2 predict

C<< predict($string, name => value, ...) >>: the string as the parts have
rewritten it; in list context also its confidence, the product of the
parts'.

=head2 predict_all

C<< predict_all(\@strings, name => value, ...) >>: the answers, in order.

=head2 run

C<< run(\@strings, name => value, ...) >>: one record per string,
C<< { text, confidence, answers } >>, the answers being those of the parts
that classify, under the parts' names.

=head2 run_texts

C<< run_texts(\@texts, name => value, ...) >>: the same for texts, each a
list of strings; returns the records per text. A pooled part answers once
per text.

=head2 on

C<on($where)>: where the chain answers from now on: C<'pipeline'> (as it
starts), or fused on C<'cpu'> or C<'gpu'>. Returns the chain.

=head2 given

The names of the chain's arguments, in the order its parts first need them.

=head2 parts

The names of the parts, in order.

=head2 answers

The names of the parts that classify.

=head2 models

The names of the chain's models, in the order of the parts. A part that
chooses has one per answer, called C<part-answer>.

=head2 model

C<model($name)>: that model, as a L<Peta::NN::Inference>.

=head2 n_params

How many weights the chain has: those of its models.

=head2 pipeline

The L<Peta::NN::Pipeline> that runs the chain.

=head2 fused

C<fused($engine)>: the same parts as a L<Peta::NN::Fused>, on C<'cpu'> (the
default) or C<'gpu'>.

=head2 info

What there is to know about the chain, as a table.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
