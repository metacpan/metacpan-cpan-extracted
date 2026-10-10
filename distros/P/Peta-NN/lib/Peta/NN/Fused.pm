package Peta::NN::Fused;
# ABSTRACT: micro models fused into one, as they are, the seams inside

# Micro models fused into one: the models of a pipeline exactly as they are,
# weight for weight, and between them, inside the model, what a pipeline does
# in Perl between two steps.
#
#   in a pipeline         N1 -> [Perl: the answer becomes the input] -> N2
#   fused                 N3 = N1 -> N2, the seam inside
#   fused, consolidated   N4, one model trained on what the chain does
#
# This module makes the second. Nothing is trained and no weight changes, so
# a fused model answers exactly what its pipeline answers, and has as many
# weights as its parts together. (The third is a new, smaller model; it is
# trained, and it is not the same function.)
#
# The seams. A pipeline does one of three things with a step's outputs, and
# each is an operation without weights in here:
#
#   route    The step is an edit model: its best label is an edit, which is
#            carried out, and the next model reads the new string. Every
#            label is one fixed edit, so what the next model will read is
#            known per label in advance: some characters the label adds, and
#            behind them characters of the string as it came in, shifted.
#   class    The step classifies: its best label is kept as the step's
#            answer and the string passes on as it is.
#   pool     The step classifies a whole text: all strings of the text are
#            evidence, and each gets the one answer they point to together.
#
# A kept answer does two things later on. It chooses which of several models
# a step runs for a string (all of them are computed side by side, and each
# only takes effect on the strings that are its own), and it can be a
# parameter of a later model.
#
# What is kept per string is its two ends as numbers: its last `reach`
# characters, which is as far back as any part can come to read once the
# parts before it have cut as deep as they can, and its first `front`, as
# far as any part reads from the front. A string of any length goes in as
# those and its length, passes all parts without coming back to Perl, and
# comes out as one edit (how much of the string that came in to cut, which
# characters to add) and its answers.
#
# The parts stay separate in the fused model and in its file. One of them can
# be replaced by a better one without touching the others; the seams are
# derived again from the parts' labels, which costs nothing.
#
# Two engines run a fused model. `cpu` computes each part as the inference
# leg does (PDL or plain Perl), so it agrees with the pipeline to the last
# bit. `gpu` keeps the whole batch on the card from the first part to the
# last, seams included, in 32-bit floats.
#
# What fuses: class models, and edit models that rewrite the end of a string.

use v5.36;

use Storable ();

use Peta::NN::Codec qw(PAD UNKNOWN);
use Peta::NN::Inference;

our $VERSION = '0.2610090';

our $FORMAT = 'Peta::NN fused model';

# The layout of a fused model's file.
#   1  the parts' model data under their names, and the steps
our $LAYOUT = 1;

my $ANY        = '*';           # in a routing table: the model for every answer not listed
my $FIRST_CHAR = 2;             # 0 and 1 are PAD and UNKNOWN, as in every model
my $STORE_BITS = 64;            # for a part that came as a trained model, not from a file

my $GPU_REACH    = 64;          # the longest tail the route shader holds
my $GPU_ROWS     = 16384;       # strings per pass on the card, at most
my $GPU_1D_LIMIT = 4_000_000;   # invocations of a one-dimensional dispatch (65535 groups of 64)

my %ENGINE = map { $_ => 1 } qw(cpu gpu);

# A string in flight is a list with these fields.
use constant {
    TAIL       => 0,    # the numbers of its last characters, at least as many as any part will read
    LENGTH     => 1,    # how long it is now
    CUT        => 2,    # how many characters of the string that came in are cut from its end
    ADDED      => 3,    # how many of the tail's last characters are added ones
    CONFIDENCE => 4,    # the product of the parts' confidences so far
    HEAD       => 5,    # the numbers of its first characters
    ANSWERS    => 6,    # per step that classifies: the number of its answer
    TEXT       => 7,    # which text it belongs to
};

# --- the shaders of the gpu engine --------------------------------------------
# Per string s: its tail tl[s * reach + r], r counting from the string's end;
# its head hd[s * front + i]; st[s * 3 ..] its length, cut and added; cf[s]
# its confidence; an[s * slots + k] its answer to classifying step k. A model
# that is one of several a step chooses from is given the slot to choose by
# (as slot + 1; 0 for a model that is the only one) and flags that say for
# which answers there it is the one.

my $IS_MINE = <<'WGSL';
fn is_mine(s: u32, slots: u32, by: u32) -> bool {
    if (by == 0u) { return true; }
    return flags[an[s * slots + by - 1u]] != 0u;
}
WGSL

# name => [ bindings, dimensions, body, functions ], as the backend's define() takes them.
my %SHADER = (

    # A part's input: for every string the table rows of its parameters'
    # tokens and of its window's characters, read from head and tail.
    #   n0 dim, n1 parameters, n2 characters from the front, n3 from the end,
    #   n4 reach, n5 front
    fused_read => [ [qw(r:e u:hd u:tl u:ptok u:cmap w:y)], 1, <<'WGSL' ],
    let i = id.x;
    if (i >= arrayLength(&y)) { return; }
    let per = (p.n1 + p.n2 + p.n3) * p.n0;
    let s = i / per; let t = (i % per) / p.n0;
    var tok = 0u;
    if (t < p.n1)             { tok = ptok[s * p.n1 + t]; }
    else if (t < p.n1 + p.n2) { tok = cmap[hd[s * p.n5 + t - p.n1]]; }
    else                      { tok = cmap[tl[s * p.n4 + (p.n3 - 1u - (t - p.n1 - p.n2))]]; }
    y[i] = e[tok * p.n0 + i % p.n0];
WGSL

    # A parameter that is an earlier answer: the token for it, per string.
    #   n0 parameters, n1 which of them, n2 slots, n3 the slot
    fused_param => [ [qw(u:an u:table x:ptok)], 1, <<'WGSL' ],
    let s = id.x;
    if (s * p.n0 >= arrayLength(&ptok)) { return; }
    ptok[s * p.n0 + p.n1] = table[an[s * p.n2 + p.n3]];
WGSL

    # Route: the best label of an edit model's outputs, and its edit carried
    # out on the string's two ends. ed holds per label: how many characters
    # to cut, how many to add, and those, the last one first. An edit that
    # cuts more than the string has leaves it as it is.
    #   n0 labels, n1 reach, n2 the longest addition, n3 front, n4 slots,
    #   n5 the slot to choose by
    fused_route => [ [qw(r:z u:ed x:tl x:st w:cf x:hd u:an u:flags)], 1, <<'WGSL', $IS_MINE ],
    let s = id.x;
    if (s >= arrayLength(&cf) || !is_mine(s, p.n4, p.n5)) { return; }
    let at = s * p.n0;
    var best = 0u;
    var top = z[at];
    for (var i = 1u; i < p.n0; i++) { if (z[at + i] > top) { top = z[at + i]; best = i; } }
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) { sum += exp(z[at + i] - top); }
    cf[s] = cf[s] / sum;

    let row = best * (2u + p.n2);
    let cut = ed[row]; let grow = ed[row + 1u];
    let len = st[s * 3u];
    if (cut > len) { return; }
    var was: array<u32, 64>;
    for (var r = 0u; r < p.n1; r++) { was[r] = tl[s * p.n1 + r]; }
    for (var r = 0u; r < p.n1; r++) {
        var c = 0u;
        if (r < grow) { c = ed[row + 2u + r]; }
        else {
            let source = r - grow + cut;
            if (source < p.n1) { c = was[source]; }
        }
        tl[s * p.n1 + r] = c;
    }
    let kept = len - cut;
    for (var i = kept; i < p.n3; i++) {
        var c = 0u;
        if (i - kept < grow) { c = ed[row + 2u + (grow - 1u - (i - kept))]; }
        hd[s * p.n3 + i] = c;
    }
    let added = st[s * 3u + 2u];
    if (cut <= added) { st[s * 3u + 2u] = added - cut + grow; }
    else {
        st[s * 3u + 1u] = st[s * 3u + 1u] + cut - added;
        st[s * 3u + 2u] = grow;
    }
    st[s * 3u] = kept + grow;
WGSL

    # Class: the best label of a class model's outputs, kept as the step's
    # answer. names holds for each label its number among the step's answers.
    #   n0 labels, n1 slots, n2 the step's slot, n3 the slot to choose by
    fused_class => [ [qw(r:z w:cf x:an u:flags u:names)], 1, <<'WGSL', $IS_MINE ],
    let s = id.x;
    if (s >= arrayLength(&cf) || !is_mine(s, p.n1, p.n3)) { return; }
    let at = s * p.n0;
    var best = 0u;
    var top = z[at];
    for (var i = 1u; i < p.n0; i++) { if (z[at + i] > top) { top = z[at + i]; best = i; } }
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) { sum += exp(z[at + i] - top); }
    cf[s] = cf[s] / sum;
    an[s * p.n1 + p.n2] = names[best];
WGSL

    # Pool, first half: the logarithm of every label's probability, per
    # string; no probability counts as less than 1e-12, as in the inference leg.
    #   n0 labels
    fused_logp => [ [qw(r:z w:lp)], 1, <<'WGSL' ],
    let s = id.x;
    if (s * p.n0 >= arrayLength(&lp)) { return; }
    let at = s * p.n0;
    var top = z[at];
    for (var i = 1u; i < p.n0; i++) { top = max(top, z[at + i]); }
    var sum = 0.0;
    for (var i = 0u; i < p.n0; i++) { sum += exp(z[at + i] - top); }
    for (var i = 0u; i < p.n0; i++) { lp[at + i] = log(max(exp(z[at + i] - top) / sum, 1e-12)); }
WGSL

    # Pool, second half, per text: the label its strings point to together,
    # kept as the answer of each of them. tx holds where each text's strings
    # start, and one more.
    #   n0 labels, n1 slots, n2 the step's slot, n3 the slot to choose by
    fused_pool => [ [qw(r:lp u:tx w:cf x:an u:flags u:names)], 1, <<'WGSL', $IS_MINE ],
    let g = id.x;
    if (g + 1u >= arrayLength(&tx)) { return; }
    var best = 0u;
    var top = 0.0;
    var some = false;
    for (var l = 0u; l < p.n0; l++) {
        var sum = 0.0;
        for (var s = tx[g]; s < tx[g + 1u]; s++) { if (is_mine(s, p.n1, p.n3)) { sum += lp[s * p.n0 + l]; some = true; } }
        if (l == 0u || sum > top) { top = sum; best = l; }
    }
    if (!some) { return; }
    var all = 0.0;
    for (var l = 0u; l < p.n0; l++) {
        var sum = 0.0;
        for (var s = tx[g]; s < tx[g + 1u]; s++) { if (is_mine(s, p.n1, p.n3)) { sum += lp[s * p.n0 + l]; } }
        all += exp(sum - top);
    }
    for (var s = tx[g]; s < tx[g + 1u]; s++) {
        if (is_mine(s, p.n1, p.n3)) {
            cf[s] = cf[s] / all;
            an[s * p.n1 + p.n2] = names[best];
        }
    }
WGSL
);

sub _max (@n) { my $max = 0; for (@n) { $max = $_ if $_ > $max } return $max }

# --- fusing ---------------------------------------------------------------------

# A model as given to new(), as a part.
sub _part ($name, $model) {
    my $data = !ref $model          ? Peta::NN::Inference::read_file($model, $Peta::NN::Inference::FORMAT)
             : ref $model eq 'HASH' ? $model
             :                        $model->data;
    my $read = eval { Peta::NN::Inference->new($data) } or die "the model '$name': $@";
    die "the model '$name' is a $data->{kind} model that does not fuse; class models do, and edit models that rewrite the end of a string\n"
        if $data->{kind} eq 'rewrite' || $data->{kind} eq 'edit' && $data->{side} ne 'right';
    return {
        name   => $name, data => $data, model => $read, kind => $data->{kind}, params => $data->{params} // [],
        front  => $data->{side} ne 'right' ? $data->{window} : 0,
        end    => $data->{side} ne 'left'  ? $data->{window} : 0,
        labels => $data->{labels},
    };
}

# models   { name => model }: a model file's path, model data, or an object
#          that has it (Peta::NN::Inference, or the training leg's
#          Peta::NN::Model)
# steps    the steps, in order, as a pipeline takes them (Peta::NN::Pipeline)
# engine   'cpu' or 'gpu'; cpu unless PETA_NN_ENGINE says gpu
# meta     a table that describes the fused model (name, description, ...)
sub new ($class, %arg) {
    my $models = $arg{models} // die "models => { name => model, ... } is required\n";
    my $steps  = $arg{steps}  // die "steps => [ ... ] is required\n";
    die "a fused model needs at least one step\n" if !@$steps;
    my $engine = $arg{engine} // (($ENV{PETA_NN_ENGINE} // '') eq 'gpu' ? 'gpu' : 'cpu');
    die "a fused model runs on cpu or gpu, not on '$engine'\n" if !$ENGINE{$engine};
    die "the description of the fused model is not a table\n" if defined $arg{meta} && ref $arg{meta} ne 'HASH';

    my $self = bless { engine => $engine, given => [], steps => [], part => {}, slot => {}, slots => [], meta => $arg{meta} }, $class;

    # The steps, as a pipeline reads them. A step becomes one `use` of a part
    # per model it may run.
    my $arguments = 0;
    for my $n (0 .. $#$steps) {
        my $where = 'step ' . ($n + 1);
        die "$where is not a table\n" if ref $steps->[$n] ne 'HASH';
        my %step = %{ $steps->[$n] };
        my $spec = $step{model} // die "$where names no model\n";
        push @{ $self->{given} }, { map { $_ => $step{$_} } grep { defined $step{$_} } qw(name model params classify pool) };

        # Which model, for which answers of which earlier step.
        my (%by_model, $by);
        if (ref $spec eq 'HASH') {
            my ($from, @more) = keys %$spec;
            die "$where routes by more than one step\n" if @more;
            $by = $self->{slot}{$from} // die "$where routes by '$from', which is not an earlier step that classifies\n";
            for my $answer (@{ $by->{labels} }) {
                my $name = $spec->{$from}{$answer} // $spec->{$from}{$ANY}
                    // die "$where has no model for the answer '$answer' of step '$from'\n";
                push @{ $by_model{$name} }, $answer;
            }
        }
        elsif (ref $spec) { die "$where names its model by something that is neither a name nor a routing table\n" }
        else              { $by_model{$spec} = undef }

        my @params = @{ $step{params} // [] };
        my @uses;
        for my $name (sort keys %by_model) {
            my $of = $self->{part}{$name}
                //= _part($name, $models->{$name} // die "$where uses the model '$name', which is not among the models\n");
            die "$where: the model '$name' is a class model, so the step has to classify (classify => 1, and a name)\n"
                if $of->{kind} eq 'class' && !$step{classify};
            die "$where classifies with the model '$name', which is an edit model\n" if $of->{kind} ne 'class' && $step{classify};
            die sprintf "$where gives the model '$name' %d parameter%s; it takes %d\n",
                scalar @params, @params == 1 ? '' : 's', scalar @{ $of->{params} } if @params != @{ $of->{params} };

            my @take;
            for my $at (0 .. $#params) {
                my ($param, $known) = ($params[$at], $of->{params}[$at]);
                if (ref $param eq 'SCALAR') {
                    die "$where has an argument number that is not a whole number\n" if $$param !~ /\A[0-9]+\z/;
                    $arguments = $$param + 1 if $$param + 1 > $arguments;
                    push @take, { argument => $$param };
                }
                elsif (ref $param eq 'HASH') {
                    my $from = $param->{answer} // die "$where has a parameter that is a table without `answer`\n";
                    my $slot = $self->{slot}{$from} // die "$where takes a parameter from '$from', which is not an earlier step that classifies\n";
                    die "$where pools and takes a parameter from an answer; that does not fuse\n" if $step{pool};
                    # Only the answers that can reach this model need to be values it knows.
                    my %reach = map { $_ => 1 } $by && $by == $slot ? @{ $by_model{$name} } : @{ $slot->{labels} };
                    push @take, { slot => $slot->{at}, tokens => [
                        map { !$reach{$_} ? 0 : $known->{$_} // die "$where: the model '$name' has no value '$_' for its parameter @{[ $at + 1 ]}, which step '$from' can answer\n" }
                            @{ $slot->{labels} }
                    ] };
                }
                elsif (ref $param) { die "$where has a parameter that is neither text, \\N nor { answer => step }\n" }
                else               { push @take, { token => Peta::NN::Inference::param_tokens([$known], $param) } }      # dies if unknown
            }
            my %mine = map { $_ => 1 } @{ $by_model{$name} // [] };
            push @uses, {
                part   => $of,
                params => \@take,
                ($by ? (by => $by->{at}, flags => [ map { $mine{$_} ? 1 : 0 } @{ $by->{labels} } ]) : ()),
            };
        }

        # A step that classifies has a slot for its answer: the labels of all
        # the models it may run, numbered together.
        my %made = (uses => \@uses, pool => $step{pool} ? 1 : 0);
        if ($step{classify}) {
            die "$where only classifies, so it needs a name for its answer\n" if !defined $step{name};
            my %seen  = map { $_ => 1 } map { @{ $_->{part}{labels} } } @uses;
            my @names = sort keys %seen;
            my %at    = map { $names[$_] => $_ } 0 .. $#names;
            my $slot  = { at => scalar @{ $self->{slots} }, name => $step{name}, labels => \@names };
            $_->{names} = [ map { $at{$_} } @{ $_->{part}{labels} } ] for @uses;
            $made{slot} = $slot->{at};
            push @{ $self->{slots} }, $slot;
            $self->{slot}{ $step{name} } = $slot;       # from here on later steps can refer to it
        }
        elsif ($step{pool}) { die "$where pools, which is for a step that classifies\n" }
        push @{ $self->{steps} }, \%made;
    }
    $self->{arguments} = $arguments;

    # One numbering of characters for the whole fused model: everything a part
    # can read and everything a part can add.
    my @parts = values %{ $self->{part} };
    my @edit  = grep { $_->{kind} eq 'edit' } @parts;
    $_->{edits} = [ map { my ($cut, $add) = split /:/, $_, 2; [ $cut, $add ] } @{ $_->{labels} } ] for @edit;
    my %seen  = map { $_ => 1 } (map { keys %{ $_->{data}{vocab} } } @parts), map { map { split //, $_->[1] } @{ $_->{edits} } } @edit;
    my @chars = sort keys %seen;
    my $next  = $FIRST_CHAR;
    $self->{id}   = { map { $_ => $next++ } @chars };
    $self->{char} = [ '', '', @chars ];

    # The seams, from each part's labels: its edits in the common numbering,
    # and for its window the token it reads each character as.
    for my $of (@parts) {
        my $vocab = $of->{data}{vocab};
        $of->{cmap} = [ PAD, UNKNOWN, map { $vocab->{$_} // UNKNOWN } @chars ];
        next if $of->{kind} ne 'edit';
        $of->{edits}   = [ map { [ $_->[0], [ map { $self->{id}{$_} } split //, $_->[1] ] ] } @{ $of->{edits} } ];
        $of->{deepest} = _max(map { $_->[0] } @{ $of->{edits} });
        $of->{longest} = _max(map { scalar @{ $_->[1] } } @{ $of->{edits} });
    }

    # How much of a string's end must be kept: a step reads its window after
    # the steps before it have cut as deep as they can; and everything the
    # steps add together has to fit. And of its front: the widest window there.
    my ($depth, $grown, $reach) = (0, 0, 1);
    for my $step (@{ $self->{steps} }) {
        my @of = map { $_->{part} } @{ $step->{uses} };
        $reach  = _max($reach, map { $_->{end} ? $_->{end} + $depth : 0 } @of);
        $depth += _max(map { $_->{deepest} // 0 } @of);
        $grown += _max(map { $_->{longest} // 0 } @of);
    }
    $self->{reach} = _max($reach, $grown);
    $self->{front} = _max(map { $_->{front} } @parts);
    return $self;
}

# From a fused model's file (by convention *.fused). `engine` as for new().
sub load ($class, $file, %arg) {
    my $data = Peta::NN::Inference::read_file($file, $FORMAT);
    die sprintf "$file is in layout %s, and this version reads layout %d; fuse it again\n", $data->{layout} // '?', $LAYOUT
        if ($data->{layout} // '') ne $LAYOUT;
    die "$file is a malformed fused model: no models or no steps\n" if ref $data->{models} ne 'HASH' || ref $data->{steps} ne 'ARRAY';
    my $self = eval { $class->new(models => $data->{models}, steps => $data->{steps}, meta => $data->{meta}, %arg) }
        or die "$file is a malformed fused model: $@";
    return $self;
}

# A part's data as it goes into a file: as it came from its own file, or, for
# a part that came as a trained model, with its weights packed in full.
sub _stored ($data) {
    return $data if !grep { ref eq 'ARRAY' } map { @{ $_->{weights} } } @{ $data->{layers} };
    return {
        %$data,
        format => $Peta::NN::Inference::FORMAT,
        layout => $Peta::NN::Inference::LAYOUT,
        bits   => $STORE_BITS,
        layers => [
            map { { %$_, weights => [ map { ref eq 'ARRAY' ? Peta::NN::Inference::pack_weights($_, $STORE_BITS) : $_ } @{ $_->{weights} } ] } }
                @{ $data->{layers} }
        ],
    };
}

# Write the fused model to a file: its parts, each as it is, and the steps.
sub save ($self, $file) {
    Storable::nstore({
        format  => $FORMAT,
        layout  => $LAYOUT,
        version => $VERSION,
        models  => { map { $_ => _stored($self->{part}{$_}{data}) } keys %{ $self->{part} } },
        steps   => $self->{given},
        meta    => { created => time, %{ $self->{meta} // {} } },
    }, $file);
    return $self;
}

# The same fused model with some parts replaced: replace(name => model, ...),
# a model being what new() takes. The others are not touched.
sub replace ($self, %models) {
    defined $self->{part}{$_} or die "this fused model has no part '$_'\n" for keys %models;
    return ref($self)->new(
        models => { (map { $_ => $self->{part}{$_}{data} } keys %{ $self->{part} }), %models },
        steps  => $self->{given},
        engine => $self->{engine},
        meta   => $self->{meta},
    );
}

# --- what it is -----------------------------------------------------------------

sub engine    ($self) { return $self->{engine} }
sub arguments ($self) { return $self->{arguments} }
sub reach     ($self) { return $self->{reach} }
sub front     ($self) { return $self->{front} }

# The names of the parts, in the order the steps first use them.
sub parts ($self) {
    my %seen;
    return grep { !$seen{$_}++ } map { map { $_->{part}{name} } @{ $_->{uses} } } @{ $self->{steps} };
}

# A part, as the inference leg's model.
sub part ($self, $name) { return ($self->{part}{$name} // die "this fused model has no part '$name'\n")->{model} }

# The names of the steps that classify, in order: what a record's answers are.
sub names ($self) { return map { $_->{name} } @{ $self->{slots} } }

sub n_params ($self) {
    my $n = 0;
    $n += $self->part($_)->n_params for $self->parts;
    return $n;
}

# What there is to know about the fused model, for a human. A step is the
# name of its model, or of its models with | between them.
sub info ($self) {
    return {
        %{ $self->{meta} // {} },
        format    => $FORMAT,
        version   => $VERSION,
        kind      => 'fused',
        reads     => join(' and ', ($self->{front} ? "the first $self->{front}" : ()), "the last $self->{reach}") . ' characters',
        steps     => [ map { join '|', map { $_->{part}{name} } @{ $_->{uses} } } @{ $self->{steps} } ],
        answers   => [ $self->names ],
        weights   => $self->n_params,
        arguments => $self->{arguments},
        parts     => { map { $_ => $self->part($_)->info } $self->parts },
    };
}

# --- answering --------------------------------------------------------------------

# One edit, carried out on a string in flight.
sub _route ($row, $edit, $front) {
    my ($cut, $add) = @$edit;
    return if $cut > $row->[LENGTH];
    my $tail = $row->[TAIL];
    splice @$tail, -$cut if $cut;
    push @$tail, @$add;
    my $kept = $row->[LENGTH] - $cut;
    if ($kept < $front) {
        my $head = $row->[HEAD];
        $head->[$_] = $add->[ $_ - $kept ] // PAD for $kept .. $front - 1;
    }
    if ($cut <= $row->[ADDED]) { $row->[ADDED] += @$add - $cut }
    else                       { $row->[CUT] += $cut - $row->[ADDED]; $row->[ADDED] = @$add }
    $row->[LENGTH] = $kept + @$add;
    return;
}

# The parts are computed as the inference leg computes them; the seams are here.
sub _run_cpu ($self, $rows) {
    my $front = $self->{front};
    for my $step (@{ $self->{steps} }) {
        for my $use (@{ $step->{uses} }) {
            my $of   = $use->{part};
            my @mine = defined $use->{by} ? grep { $use->{flags}[ $_->[ANSWERS][ $use->{by} ] ] } @$rows : @$rows;
            next if !@mine;
            my ($from_front, $from_end, $cmap) = @$of{qw(front end cmap)};
            my @windows = map {
                my $row = $_;
                [   (map { $_->{token} // $_->{tokens}[ $row->[ANSWERS][ $_->{slot} ] ] } @{ $use->{tokens} }),
                    ($from_front ? @$cmap[ @{ $row->[HEAD] }[ 0 .. $from_front - 1 ] ] : ()),
                    ($from_end   ? @$cmap[ @{ $row->[TAIL] }[ -$from_end .. -1 ] ]     : ()),
                ]
            } @mine;

            if ($of->{kind} eq 'edit') {
                my $decided = $of->{model}->decisions(\@windows);
                for my $i (0 .. $#mine) {
                    $mine[$i][CONFIDENCE] *= $decided->[$i][1];
                    _route($mine[$i], $of->{edits}[ $decided->[$i][0] ], $front);
                }
            }
            elsif ($step->{pool}) {
                my $probabilities = $of->{model}->probabilities(\@windows);
                my (%text, @order);
                for my $i (0 .. $#mine) {
                    push @order, $mine[$i][TEXT] if !$text{ $mine[$i][TEXT] };
                    push @{ $text{ $mine[$i][TEXT] } }, $i;
                }
                my %at = map { $of->{labels}[$_] => $use->{names}[$_] } 0 .. $#{ $of->{labels} };
                for my $members (@text{@order}) {
                    my ($answer, $share) = @{ $of->{model}->pool([ @$probabilities[@$members] ])->[0] };
                    for my $row (@mine[@$members]) {
                        $row->[CONFIDENCE] *= $share;
                        $row->[ANSWERS][ $step->{slot} ] = $at{$answer};
                    }
                }
            }
            else {
                my $decided = $of->{model}->decisions(\@windows);
                for my $i (0 .. $#mine) {
                    $mine[$i][CONFIDENCE] *= $decided->[$i][1];
                    $mine[$i][ANSWERS][ $step->{slot} ] = $use->{names}[ $decided->[$i][0] ];
                }
            }
        }
    }
    return;
}

# The backend, and each part on the card: its weights, its window's tokens
# and its edits. A forked child puts them on its own device.
sub _on_gpu ($self) {
    delete $self->{gpu} if $self->{gpu} && $self->{gpu}{owner} != $$;
    return $self->{gpu} //= do {
        require Peta::NN::Backend;
        my $gpu = Peta::NN::Backend::try('gpu') // die "a fused model cannot run on the gpu here: $@";
        die "this fused model keeps $self->{reach} characters per string; the gpu engine holds $GPU_REACH\n" if $self->{reach} > $GPU_REACH;
        $gpu->define($_, @{ $SHADER{$_} }) for keys %SHADER;

        my ($widest, %on) = (1);
        for my $name ($self->parts) {
            my $of = $self->{part}{$name};
            my ($embed, @rest) = @{ $of->{model}{layers} };
            die "the model '$name' does not start with an embedding\n" if $embed->{type} ne 'embed';
            my $width  = $embed->{dim} * ($of->{front} + $of->{end} + @{ $of->{params} });
            my @layers = map {
                my $layer = $_;
                $widest = _max($widest, $width);
                if ($layer->{type} eq 'dense') {
                    my ($W, $b) = @{ $layer->{weights} };
                    my $n_in = $width;
                    $width = @$b;
                    [ $gpu->tensor($W, $n_in), $gpu->tensor($b, scalar @$b) ]
                }
                else { $layer->{type} }
            } @rest;
            $widest = _max($widest, $width);
            my $longest = $of->{longest} // 0;
            $on{$name} = {
                dim    => $embed->{dim},
                table  => $gpu->tensor($embed->{weights}[0], $embed->{dim}),
                layers => \@layers,
                cmap   => $gpu->buffer(pack 'L*', @{ $of->{cmap} }),
                ($of->{kind} eq 'edit'
                    ? (edits => $gpu->buffer(pack 'L*', map { my @add = reverse @{ $_->[1] }; ($_->[0], scalar @add, @add, (0) x ($longest - @add)) } @{ $of->{edits} }))
                    : ()),
            };
        }
        # What each use of a part adds to it: for which answers it is the
        # one, the numbers of its labels, the tokens of answers as parameters.
        my $none = $gpu->buffer(pack 'L', 0);
        my %used;
        for my $use (map { @{ $_->{uses} } } @{ $self->{steps} }) {
            $used{$use} = {
                flags  => $use->{flags} ? $gpu->buffer(pack 'L*', @{ $use->{flags} }) : $none,
                names  => $use->{names} ? $gpu->buffer(pack 'L*', @{ $use->{names} }) : $none,
                tokens => [ map { $_->{tokens} ? $gpu->buffer(pack 'L*', @{ $_->{tokens} }) : undef } @{ $use->{params} } ],
            };
        }
        my $rows = int($GPU_1D_LIMIT / $widest);
        { owner => $$, backend => $gpu, on => \%on, used => \%used, none => $none, spare => $gpu->buffer(pack 'L', 0), rows => $rows < $GPU_ROWS ? $rows : $GPU_ROWS };
    };
}

# One batch, everything on the card: the strings' ends go up once, every part
# and every seam runs there, and what became of them comes back once.
sub _batch_gpu ($self, $rows) {
    my $card  = $self->_on_gpu;
    my $gpu   = $card->{backend};
    my ($reach, $front) = @$self{qw(reach front)};
    my $slots = @{ $self->{slots} };
    my $count = @$rows;

    my $tail    = $gpu->buffer(pack 'L*', map { reverse @{ $_->[TAIL] } } @$rows);
    my $head    = $front ? $gpu->buffer(pack 'L*', map { @{ $_->[HEAD] } } @$rows) : $card->{none};
    my $state   = $gpu->buffer(pack 'L*', map { @$_[ LENGTH, CUT, ADDED ] } @$rows);
    my $heads   = $front ? $head : $card->{spare};      # where route writes them: never the buffer it also only reads
    my $conf    = $gpu->buffer(pack 'f*', map { $_->[CONFIDENCE] } @$rows);
    my $answers = $slots ? $gpu->buffer(pack 'L*', (0) x ($count * $slots)) : $card->{none};

    # Where each text's strings start, for the steps that pool.
    my @starts = (0);
    for my $i (1 .. $count - 1) { push @starts, $i if $rows->[$i][TEXT] != $rows->[ $i - 1 ][TEXT] }
    my $texts = $gpu->buffer(pack 'L*', @starts, $count);

    for my $step (@{ $self->{steps} }) {
        for my $use (@{ $step->{uses} }) {
            my $of     = $use->{part};
            my $on     = $card->{on}{ $of->{name} };
            my $used   = $card->{used}{$use};
            my @params = @{ $use->{tokens} };
            my $ptok   = @params ? $gpu->buffer(pack 'L*', (map { $_->{token} // 0 } @params) x $count) : $card->{none};
            for my $at (grep { defined $params[$_]{slot} } 0 .. $#params) {
                $gpu->dispatch('fused_param', [ $answers, $used->{tokens}[$at], $ptok ], [ scalar @params, $at, $slots, $params[$at]{slot} ], $count);
            }
            my $cols = $on->{dim} * (@params + $of->{front} + $of->{end});
            my $x    = [ $gpu->buffer(4 * $count * $cols), $count, $cols ];
            $gpu->dispatch('fused_read', [ $on->{table}[0], $head, $tail, $ptok, $on->{cmap}, $x->[0] ],
                [ $on->{dim}, scalar @params, $of->{front}, $of->{end}, $reach, $front ], $count * $cols);
            for my $layer (@{ $on->{layers} }) {
                $x = ref $layer ? $gpu->affine($x, @$layer) : $gpu->activate($layer, $x);
            }

            my $labels = @{ $of->{labels} };
            my $by     = defined $use->{by} ? $use->{by} + 1 : 0;
            if ($of->{kind} eq 'edit') {
                $gpu->dispatch('fused_route', [ $x->[0], $on->{edits}, $tail, $state, $conf, $heads, $answers, $used->{flags} ],
                    [ $labels, $reach, $of->{longest}, $front, $slots, $by ], $count);
            }
            elsif ($step->{pool}) {
                my $logp = $gpu->buffer(4 * $count * $labels);
                $gpu->dispatch('fused_logp', [ $x->[0], $logp ], [$labels], $count);
                $gpu->dispatch('fused_pool', [ $logp, $texts, $conf, $answers, $used->{flags}, $used->{names} ],
                    [ $labels, $slots, $step->{slot}, $by ], scalar @starts);
            }
            else {
                $gpu->dispatch('fused_class', [ $x->[0], $conf, $answers, $used->{flags}, $used->{names} ],
                    [ $labels, $slots, $step->{slot}, $by ], $count);
            }
        }
    }

    my @tail    = unpack 'L*', $tail->read;
    my @state   = unpack 'L*', $state->read;
    my @conf    = unpack 'f*', $conf->read;
    my @answers = $slots ? unpack 'L*', $answers->read : ();
    for my $i (0 .. $count - 1) {
        my $row = $rows->[$i];
        $row->[TAIL] = [ reverse @tail[ $i * $reach .. ($i + 1) * $reach - 1 ] ];
        @$row[ LENGTH, CUT, ADDED ] = @state[ 3 * $i .. 3 * $i + 2 ];
        $row->[CONFIDENCE] = $conf[$i];
        $row->[ANSWERS]    = [ @answers[ $i * $slots .. ($i + 1) * $slots - 1 ] ] if $slots;
    }
    return;
}

# In batches the card takes, a text never split over two.
sub _run_gpu ($self, $rows) {
    my $most = $self->_on_gpu->{rows};
    my $from = 0;
    while ($from < @$rows) {
        my $to = $from + $most - 1;
        if ($to >= $#$rows) { $to = $#$rows }
        else {
            $to-- while $to > $from && $rows->[ $to + 1 ][TEXT] == $rows->[$to][TEXT];
            # One text that is longer than a batch goes in whole.
            $to++ while $to < $#$rows && $rows->[ $to + 1 ][TEXT] == $rows->[$to][TEXT];
        }
        $self->_batch_gpu([ @$rows[ $from .. $to ] ]);
        $from = $to + 1;
    }
    return;
}

# The strings in flight after all parts: one row per string. $of says for
# each string which text it belongs to; the strings of a text follow one
# another.
sub _rows ($self, $texts, $of, @arguments) {
    die sprintf "this fused model takes %d argument%s after the string, not %d\n",
        $self->{arguments}, $self->{arguments} == 1 ? '' : 's', scalar @arguments if @arguments != $self->{arguments};
    # The parameters that are arguments, as tokens: the same for every string.
    for my $use (map { @{ $_->{uses} } } @{ $self->{steps} }) {
        my $known = $use->{part}{params};
        $use->{tokens} = [
            map {
                my $param = $use->{params}[$_];
                defined $param->{argument} ? { token => Peta::NN::Inference::param_tokens([ $known->[$_] ], $arguments[ $param->{argument} ]) } : $param
            } 0 .. $#{ $use->{params} }
        ];
    }

    my ($reach, $front, $id) = @$self{qw(reach front id)};
    my $slots = @{ $self->{slots} };
    # A model that reads no front keeps none, and one without parts that
    # classify no answers: every string then has the same empty list for it,
    # which nothing writes to.
    my $nothing = [];
    my @rows    = map {
        my $text   = $texts->[$_];
        my $length = length $text;
        my @tail   = map { $id->{$_} // UNKNOWN } split //, $length > $reach ? substr($text, -$reach) : $text;
        my $head   = $nothing;
        if ($front) {
            my @head = map { $id->{$_} // UNKNOWN } split //, substr($text, 0, $front);
            $head = [ @head, (PAD) x ($front - @head) ];
        }
        [ [ (PAD) x ($reach - @tail), @tail ], $length, 0, 0, 1, $head, ($slots ? [ (0) x $slots ] : $nothing), $of->[$_] ]
    } 0 .. $#$texts;

    if ($self->{engine} eq 'gpu') { $self->_run_gpu(\@rows) }
    else                          { $self->_run_cpu(\@rows) }

    return \@rows;
}

# What became of a string: it as it came in, less what was cut from its end,
# and what was added.
sub _text ($self, $text, $row) {
    my $tail = $row->[TAIL];
    return substr($text, 0, length($text) - $row->[CUT]) . join '', @{ $self->{char} }[ @$tail[ @$tail - $row->[ADDED] .. $#$tail ] ];
}

# One record per string: { text, confidence, answers => { step name => answer } }.
sub _run ($self, $texts, $of, @arguments) {
    my $rows  = $self->_rows($texts, $of, @arguments);
    my $named = $self->{slots};
    return [
        map {
            my $row = $rows->[$_];
            {   text       => $self->_text($texts->[$_], $row),
                confidence => $row->[CONFIDENCE],
                answers    => { map { $_->{name} => $_->{labels}[ $row->[ANSWERS][ $_->{at} ] ] } @$named },
            }
        } 0 .. $#$texts
    ];
}

# Run many strings through the fused model. Returns one record per string:
# { text, confidence, answers => { step name => answer } }.
sub run ($self, $texts, @arguments) { return $self->_run($texts, [ 0 .. $#$texts ], @arguments) }

# Run many texts, each a list of strings (its words, say). Returns for each
# text the records of its strings. What differs from run() is a pooling
# step: it answers once per text.
sub run_texts ($self, $texts, @arguments) {
    my @of      = map { my $n = $_; ($n) x @{ $texts->[$n] } } 0 .. $#$texts;
    my $records = $self->_run([ map { @$_ } @$texts ], \@of, @arguments);
    my @result  = map { [] } @$texts;
    push @{ $result[ $of[$_] ] }, $records->[$_] for 0 .. $#of;
    return \@result;
}

# [answer, confidence] for each of many strings, all with the same arguments.
sub answers ($self, $texts, @arguments) {
    my $rows = $self->_rows($texts, [ 0 .. $#$texts ], @arguments);
    return [ map { [ $self->_text($texts->[$_], $rows->[$_]), $rows->[$_][CONFIDENCE] ] } 0 .. $#$texts ];
}

# The fused model's answer for a string; in list context also its confidence,
# the product of its parts' confidences.
sub predict ($self, $text, @arguments) {
    my ($record) = @{ $self->run([$text], @arguments) };
    return wantarray ? @$record{qw(text confidence)} : $record->{text};
}

# The answers for many strings at once, in their order.
sub predict_all ($self, $texts, @arguments) {
    return map { $_->[0] } @{ $self->answers($texts, @arguments) };
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Fused - micro models fused into one, as they are, the seams inside

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Fused;

    # Apfel -> Äpfel -> Äpfeln, in one model. The steps are a pipeline's.
    my $decline = Peta::NN::Fused->new(
        models => { map { $_ => "deu-noun/$_.model" } qw(umlaut ending case) },
        steps  => [
            { model => 'umlaut', params => [ \0 ] },
            { model => 'ending', params => [ \0 ] },
            { model => 'case',   params => [ \1 ] },
        ],
    );
    print scalar $decline->predict('apfel', 'masculine', 'dative');     # äpfeln

    $decline->save('deu-noun-decline.fused');
    my $on_the_card = Peta::NN::Fused->load('deu-noun-decline.fused', engine => 'gpu');
    my @plurals     = $on_the_card->predict_all(\@nouns, 'neuter', 'nominative');

    # a better part, the others untouched
    my $improved = $decline->replace(ending => 'deu-noun/ending-2.model');

    # One model names the language of a text, and that chooses the model
    # that says what each of its words is.
    my $tagger = Peta::NN::Fused->new(
        models => { language => 'language.model', map { $_ => "wordclass-$_.model" } qw(ces deu eng) },
        steps  => [
            { name => 'language', model => 'language', classify => 1, pool => 1 },
            { name => 'class', model => { language => { map { $_ => $_ } qw(ces deu eng) } }, classify => 1 },
        ],
    );
    for my $text (@{ $tagger->run_texts([ \@words_of_one_text, \@words_of_another ]) }) {
        printf "%s %s %s\n", @{ $_->{answers} }{qw(language class)}, $_->{text} for @$text;
    }

=head1 DESCRIPTION

Three ways to put micro models together:

=over

=item in a pipeline

C<< N1 -> [Perl: the answer becomes the input] -> N2 >>. L<Peta::NN::Pipeline>.

=item fused

C<< N3 = N1 -> N2 >>: both networks as they are, in one model, the seam
between them inside it. This module. No training; the fused model has the
weights of its parts and answers exactly what the pipeline answers.

=item fused, consolidated

C<N4>: one model trained on what the chain does. Smaller and faster, and a
different function.

=back

A fused model takes the steps a pipeline takes, written the same way. What a
pipeline does with a step's outputs is in here an operation without weights:
I<route> takes an edit model's best label and carries its edit out on the
characters kept per string, which the next part then reads; I<class> keeps a
class model's best label as the step's answer; I<pool> does that for a whole
text, whose strings then all have the one answer. An answer can choose which
of several models a later step runs for a string, and can be a later model's
parameter. Where a step has several models to choose from, all of them are
computed, side by side, and each takes effect only on its own strings.

What is kept per string is its last C<reach> and its first C<front>
characters. A string of any length goes in as those and its length, and
comes out as one edit and its answers.

The parts stay separate, in the object and in its file. C<replace> swaps one
for a better one; the seams are derived again from the labels.

=head2 What fuses

Class models, and edit models that rewrite the end of a string
(C<< side => 'right' >>). Edit models that rewrite the front or both ends,
and rewrite models, do not.

Where a pipeline would stop in the middle of a call, a fused model refuses
when it is built: an answer a routing table has no model for, or an answer
that is not a value of the parameter it is to be.

=head2 Engines

C<cpu> computes each part as L<Peta::NN::Inference> does, so the answers and
confidences are those of the pipeline to the last bit. C<gpu> keeps a whole
batch on the graphics card from the first part to the last; it computes in
32-bit floats, so a confidence agrees to about six digits, and a decision
between two labels that close can fall the other way. It needs a pperl with
WebGPU and is the engine when C<< engine => 'gpu' >> is given or
C<PETA_NN_ENGINE=gpu> is set.

=head1 METHODS

=head2 new

C<< Peta::NN::Fused->new(models => { name => model }, steps => [...]) >>,
optionally with C<engine> and C<meta>. A model is a model file's path, model
data, or an object that has it. The steps are those of
L<Peta::NN::Pipeline/new>.

=head2 load

C<< Peta::NN::Fused->load($file, engine => ...) >>: a fused model from its
file.

=head2 save

C<save($file)>: writes the parts, each as it is, and the steps.

=head2 replace

C<< replace(name => model, ...) >>: a new fused model with those parts
replaced.

=head2 predict

C<predict($string, @arguments)>: the answer; in list context also its
confidence, the product of the parts'.

=head2 predict_all

C<predict_all(\@strings, @arguments)>: the answers, in order.

=head2 answers

C<answers(\@strings, @arguments)>: C<[answer, confidence]> per string.

=head2 run

C<run(\@strings, @arguments)>: one record per string,
C<< { text, confidence, answers } >>, the answers being those of the steps
that classify, under the steps' names.

=head2 run_texts

C<run_texts(\@texts, @arguments)>: the same for texts, each a list of
strings; returns the records per text. A pooling step answers once per text.

=head2 parts

The names of the parts, in the order the steps first use them.

=head2 part

C<part($name)>: that part, as a L<Peta::NN::Inference> model.

=head2 names

The names of the steps that classify, in order.

=head2 n_params

How many weights the fused model has: those of its parts.

=head2 reach

How many characters of a string's end the fused model reads.

=head2 front

How many characters of a string's front the fused model reads.

=head2 arguments

How many arguments a call takes after the string.

=head2 engine

C<cpu> or C<gpu>.

=head2 info

What there is to know about the fused model, as a table.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
