package Peta::NN::Inference;
# ABSTRACT: load a trained model and get answers from it

# The inference leg: load a trained model and get answers from it. Nothing of
# the training leg is needed; this module, Peta::NN::Codec and a model file
# are all that ships.
#
# A model is plain data: what kind it is, how it reads a string (window,
# side, radius, vocabulary, parameters), its labels, and the layers with
# their weights. Model files hold exactly that, in Storable's portable
# format, with each weight array packed.
#
# A model takes a string and, if it was trained with them, parameters:
# opaque values it has learned to react to, without knowing what they mean.
# "Äpfel" with "dative" gives "Äpfeln" because the training pairs said so. A
# model does not judge its input either; given nonsense it answers something.
#
# The arithmetic runs on PDL when this perl has it and in plain Perl loops
# when not; the answers are the same. PETA_NN_ENGINE=plain forces the loops.

use v5.36;
use feature 'refaliasing';
no warnings 'experimental::refaliasing';

use Storable ();

use Peta::NN::Codec qw(window apply_edit apply_edit2);

our $VERSION = '0.2610090';

our $FORMAT = 'Peta::NN model';

# The layout of a model file. It goes up when files of the old layout can no
# longer be read; such a file is refused by number, not by a puzzling detail.
#   1  one optional task, weights packed as named by `pack`
#   2  any number of parameters, `bits`, a description of the model
our $LAYOUT = 2;

# PDL exports dozens of functions; they go into a package of their own.
my $ENGINE = ($ENV{PETA_NN_ENGINE} // '') ne 'plain'
    && eval "package Peta::NN::Inference::PDL; use PDL::LiteF; 1" ? 'pdl' : 'plain';

my $SATURATED = 20;       # beyond this exp() adds nothing in a double
my $CHUNK     = 256;      # windows per forward pass
my $FLOOR     = 1e-12;    # the least probability a pooled label is given, so one zero cannot veto

sub engine { return $ENGINE }

# --- how a model reads a string ----------------------------------------------
# Used here to answer and by the training leg to build its training data, so
# that both see a string the same way. $config is anything with the keys
# side, window, radius and vocab; @tokens are the parameters' tokens.

# The window of the whole-string kinds: the first characters, the last, or
# the first followed by the last.
sub end_window ($config, $chars, @tokens) {
    my ($side, $size, $vocab) = @$config{qw(side window vocab)};
    return [
        @tokens,
        ($side ne 'right' ? @{ window($chars, 0, $size, $vocab) } : ()),
        ($side ne 'left'  ? @{ window($chars, @$chars - $size, $size, $vocab) } : ()),
    ];
}

# The window around one character, for rewrite.
sub char_window ($config, $chars, $pos, @tokens) {
    my $radius = $config->{radius};
    return [ @tokens, @{ window($chars, $pos - $radius, 2 * $radius + 1, $config->{vocab}) } ];
}

# The tokens of a call's parameters. $params is the model's list of tables,
# one per parameter position, each from value to token. The number of
# parameters must be the model's; a value the model was never trained with
# is refused.
sub param_tokens ($params, @values) {
    my @tables = @{ $params // [] };
    die sprintf "this model takes %d parameter%s, not %d\n", scalar @tables, @tables == 1 ? '' : 's', scalar @values
        if @values != @tables;
    return map {
        my $value = $values[$_] // die "parameter @{[ $_ + 1 ]} is undefined\n";
        $tables[$_]{$value} // die "parameter @{[ $_ + 1 ]} has no value '$value' in this model (it has: @{[ sort keys %{ $tables[$_] } ]})\n"
    } 0 .. $#tables;
}

# --- weights as stored ---------------------------------------------------------
# A weight array is, in memory, a list of numbers. In a file it is a string
# packed as 32- or 64-bit floats, or { int8 => string, scale => number }:
# signed bytes that give the weights when multiplied by the scale.

my %FLOAT_PACK = (32 => 'f<', 64 => 'd<');

sub pack_weights ($weights, $bits) {
    return pack "$FLOAT_PACK{$bits}*", @$weights if $FLOAT_PACK{$bits};
    die "weights can be stored with 8, 32 or 64 bits, not '$bits'\n" if $bits != 8;
    my $largest = 0;
    for my $w (@$weights) { $largest = abs $w if abs $w > $largest }
    my $scale = $largest ? $largest / 127 : 1;
    return { scale => $scale, int8 => pack 'c*', map { my $q = $_ / $scale; int($q + ($q < 0 ? -0.5 : 0.5)) } @$weights };
}

sub _unpack_weights ($stored, $bits) {
    return $stored if ref $stored eq 'ARRAY';
    return [ map { $_ * $stored->{scale} } unpack 'c*', $stored->{int8} ] if ref $stored eq 'HASH';
    return [ unpack "$FLOAT_PACK{$bits}*", $stored ];
}

# How many numbers a stored weight array holds, or nothing if it is not one.
sub _stored_length ($stored, $bits) {
    return scalar @$stored if ref $stored eq 'ARRAY';
    if (ref $stored eq 'HASH') {
        return if ($bits // 0) != 8 || ref $stored->{int8} || !defined $stored->{int8};
        return if !defined $stored->{scale} || ref $stored->{scale} || $stored->{scale} !~ /\A[0-9.eE+-]+\z/ || $stored->{scale} <= 0;
        return length $stored->{int8};
    }
    my $bytes = !defined $bits ? undef : $bits == 32 ? 4 : $bits == 64 ? 8 : undef;
    return if ref $stored || !defined $stored || !$bytes || length($stored) % $bytes;
    return length($stored) / $bytes;
}

# --- reading and checking a model ---------------------------------------------

my %KIND       = map { $_ => 1 } qw(class edit rewrite);
my %SIDE       = map { $_ => 1 } qw(left right both);
my %ACTIVATION = map { $_ => 1 } qw(relu tanh sigmoid);
my %BITS       = map { $_ => 1 } qw(8 32 64);

# Read a Storable file as plain data. Flags 0: nothing in the file is blessed
# into a class or tied, so reading it runs no code of anyone's choosing.
sub read_file ($file, $format) {
    my $data = eval { Storable::retrieve($file, 0) };
    die "$file cannot be read as a $format file: " . ($@ =~ s/ at \S+ line \d+.*//sr || "$!") . "\n" if !defined $data;
    die "$file is not a $format file\n" if ref $data ne 'HASH' || ($data->{format} // '') ne $format;
    return $data;
}

sub _is_count ($value) { return defined $value && !ref $value && $value =~ /\A[1-9][0-9]*\z/ }

# Die unless $data is a model this module can answer from: every field of the
# right type, and every layer of the size its neighbours need. A model that
# passes cannot index outside its weights or its labels.
sub _validate ($data) {
    my $bad = sub ($what) { die "malformed model: $what\n" };

    # Data built in this process carries no layout; a file always does.
    $bad->(sprintf 'it is in layout %s, and this version reads layout %d; export it again', $data->{layout} // 1, $LAYOUT)
        if defined $data->{format} && ($data->{layout} // 1) ne $LAYOUT;

    $bad->('unknown kind')  if !$KIND{ $data->{kind} // '' };
    $bad->('unknown side')  if !$SIDE{ $data->{side} // '' };
    $bad->('window is not a positive whole number') if !_is_count($data->{window});
    $bad->('radius is not a positive whole number') if !_is_count($data->{radius});

    my ($vocab, $labels, $params, $layers) = @$data{qw(vocab labels params layers)};
    $bad->('no vocabulary') if ref $vocab ne 'HASH';
    $bad->('no labels')     if ref $labels ne 'ARRAY' || !@$labels || grep { !defined || ref } @$labels;
    $bad->('parameters are not a list of tables')
        if defined $params && (ref $params ne 'ARRAY' || grep { ref ne 'HASH' || !%$_ } @$params);
    # The parameters' names, if the model has them: one each, no name twice.
    if (defined(my $given = $data->{given})) {
        my %seen;
        $bad->('the names of the parameters are not one plain name for each parameter')
            if ref $given ne 'ARRAY' || @$given != @{ $params // [] } || grep { !defined || ref || !length || $seen{$_}++ } @$given;
    }
    $bad->('no layers')     if ref $layers ne 'ARRAY' || !@$layers;
    $bad->('the description of the model is not a table') if defined $data->{meta} && ref $data->{meta} ne 'HASH';

    # Token indices: 0 and 1 are reserved; the characters and the parameter
    # values follow, no index twice and none beyond the table.
    my @index = (values %$vocab, map { values %$_ } @{ $params // [] });
    my %seen;
    $bad->('a token index is not a whole number of 2 or more, or is used twice')
        if grep { !_is_count($_) || $_ < 2 || $seen{$_}++ } @index;
    my $rows = 2 + @index;
    $bad->('token indices leave gaps') if grep { $_ >= $rows } @index;

    # An edit's label must be an edit: "cut:add", or for both ends "cut:add|cut:add".
    if ($data->{kind} eq 'edit') {
        my $form = $data->{side} eq 'both' ? qr/\A[0-9]+:[^|]*\|[0-9]+:.*\z/s : qr/\A[0-9]+:.*\z/s;
        $bad->('an edit label is not an edit') if grep { $_ !~ $form } @$labels;
    }

    my $bits = $data->{bits};
    $bad->('unknown weight size') if defined $bits && !$BITS{$bits};

    # Follow the sizes through the layers. $width is what a layer hands on.
    my $tokens = @{ $params // [] }
               + ($data->{kind} eq 'rewrite' ? 2 * $data->{radius} + 1 : ($data->{side} eq 'both' ? 2 : 1) * $data->{window});
    my $width;
    for my $n (0 .. $#$layers) {
        my $layer = $layers->[$n];
        $bad->("layer $n is not a layer") if ref $layer ne 'HASH' || ref $layer->{weights} ne 'ARRAY';
        my $type   = $layer->{type} // '';
        my @length = map { _stored_length($_, $bits) // $bad->("layer $n has weights that are not stored as the file says") }
                     @{ $layer->{weights} };

        if ($type eq 'embed') {
            $bad->('an embedding that is not the first layer') if $n != 0;
            $bad->('embedding dimension is not a positive whole number') if !_is_count($layer->{dim});
            $bad->('the embedding table does not have one row per token') if @length != 1 || $length[0] != $rows * $layer->{dim};
            $width = $tokens * $layer->{dim};
        }
        elsif ($type eq 'dense') {
            $bad->('a dense layer with nothing before it') if !defined $width;
            $bad->("dense layer $n does not fit the layer before it")
                if @length != 2 || !$length[1] || $length[0] != $width * $length[1];
            $width = $length[1];
        }
        elsif ($ACTIVATION{$type}) {
            $bad->("activation $n has weights, or nothing before it") if @length || !defined $width;
        }
        else { $bad->("layer $n is of unknown type") }
    }
    $bad->('the last layer does not have one output per label') if ($width // -1) != @$labels;
    return;
}

# --- a model -----------------------------------------------------------------

# From model data, which is checked first. Weight arrays may be lists, or
# stored as `bits` says. A weight that is not a finite number is refused: it
# would poison every answer.
sub new ($class, $data) {
    die "a model is a table of fields\n" if ref $data ne 'HASH';
    _validate($data);
    my $self = bless { %$data }, $class;
    $self->{as_stored} = $data;
    $self->{layers} = [
        map {
            my $layer = { %$_ };
            $layer->{weights} = [ map { _unpack_weights($_, $data->{bits}) } @{ $layer->{weights} } ];
            $layer
        } @{ $data->{layers} }
    ];
    for my $weights (map { @{ $_->{weights} } } @{ $self->{layers} }) {
        die "malformed model: a weight is not a finite number\n" if grep { $_ != $_ || abs($_) == 9**9**9 } @$weights;
    }
    if ($ENGINE eq 'pdl') {
        for my $layer (grep { $_->{type} eq 'dense' } @{ $self->{layers} }) {
            my ($W, $b) = @{ $layer->{weights} };
            # (in, out) as stored, transposed once: a batch (in, rows) times it is (out, rows).
            $layer->{Wt}   = PDL->pdl(PDL::double(), $W)->reshape(@$W / @$b, scalar @$b)->transpose->copy;
            $layer->{bias} = PDL->pdl(PDL::double(), $b);
        }
    }
    return $self;
}

# From a model file (by convention *.model). The file is read as plain data
# and checked in full before anything is computed from it.
sub load ($class, $file) {
    my $model = eval { $class->new(read_file($file, $FORMAT)) };
    die $@ =~ s/\Amalformed model:/$file is a malformed model:/r if !$model;
    return $model;
}

sub kind   ($self) { return $self->{kind} }

# The model data this object was made from, weights as they were stored.
sub data ($self) { return $self->{as_stored} }
sub labels ($self) { return @{ $self->{labels} } }

# The values the model knows for each of its parameters: one sorted list per
# parameter position. A model without parameters has none.
sub parameters ($self) {
    return map { [ sort keys %$_ ] } @{ $self->{params} // [] };
}

# The names of the parameters, in their order; none for a model without
# parameters, or for one whose parameters were not given names.
sub given ($self) { return @{ $self->{given} // [] } }

# What a caller gave after the string, as the parameters' values in their
# order. A model whose parameters have names takes them by name
# (gender => 'neuter'); one whose parameters have none, in their order.
sub values_from ($self, @given) {
    my $names = $self->{given} or return @given;
    die sprintf "this model takes %s, by name\n", join ', ', map { "$_ => ..." } @$names if @given != 2 * @$names;
    my %named = @given;
    return map { delete $named{$_} // die sprintf "this model takes %s; '%s' is missing\n", join(', ', @$names), $_ } @$names;
}

sub n_params ($self) {
    my $n = 0;
    $n += @$_ for map { @{ $_->{weights} } } @{ $self->{layers} };
    return $n;
}

# What there is to know about the model, for a human: what the file says of
# itself (name, description, source, when it was made, the fidelity it was
# measured at) and what follows from its contents.
sub info ($self) {
    my @shape = map {
        my $type = $_->{type};
        $type eq 'embed' ? "embed $_->{dim}" : $type eq 'dense' ? 'dense ' . @{ $_->{weights}[1] } : $type
    } @{ $self->{layers} };
    return {
        %{ $self->{meta} // {} },
        format     => $self->{format},
        version    => $self->{version},
        bits       => $self->{bits},
        kind       => $self->{kind},
        reads      => $self->{kind} eq 'rewrite' ? "$self->{radius} characters either side of each character"
                    : $self->{side} eq 'both'    ? "the first and the last $self->{window} characters"
                    :                              "the " . ($self->{side} eq 'left' ? 'first' : 'last') . " $self->{window} characters",
        layers     => join(', ', @shape),
        weights    => $self->n_params,
        labels     => scalar @{ $self->{labels} },
        characters => scalar keys %{ $self->{vocab} },
        parameters => [ $self->parameters ],
        given      => [ $self->given ],
    };
}

# The table rows of every token of every window, one window after another.
sub _embedded ($layer, $windows) {
    my ($table, $dim) = ($layer->{weights}[0], $layer->{dim});
    return [ map { my $at = $_ * $dim; @$table[ $at .. $at + $dim - 1 ] } map { @$_ } @$windows ];
}

# Y = X W^T + b for rows of $n_in numbers. The arrays are aliased to lexical
# ones so that the loops are plain array code, which is what a JIT compiles.
sub _affine ($X, $W, $b, $n_in) {
    \my @x = $X;
    \my @W = $W;
    \my @b = $b;
    my $n_out = @b;
    my $rows  = @x / $n_in;
    my @y     = (0.0) x ($rows * $n_out);
    for my $s (0 .. $rows - 1) {
        my $x_at = $s * $n_in;
        my $y_at = $s * $n_out;
        for my $j (0 .. $n_out - 1) {
            my $sum  = $b[$j];
            my $w_at = $j * $n_in;
            for my $i (0 .. $n_in - 1) {
                $sum += $W[ $w_at + $i ] * $x[ $x_at + $i ];
            }
            $y[ $y_at + $j ] = $sum;
        }
    }
    return \@y;
}

# In place.
sub _activate ($type, $X) {
    \my @x = $X;
    if ($type eq 'relu') {
        for my $i (0 .. $#x) { $x[$i] = 0.0 if $x[$i] < 0 }
    }
    elsif ($type eq 'tanh') {
        for my $i (0 .. $#x) {
            my $v = $x[$i];
            if    ($v >  $SATURATED) { $x[$i] =  1.0 }
            elsif ($v < -$SATURATED) { $x[$i] = -1.0 }
            else                     { my $e = exp(2 * $v); $x[$i] = ($e - 1) / ($e + 1) }
        }
    }
    else {
        for my $i (0 .. $#x) {
            my $v = $x[$i];
            $x[$i] = $v > $SATURATED ? 1.0 : $v < -$SATURATED ? 0.0 : 1 / (1 + exp(-$v));
        }
    }
    return;
}

# The network's outputs for a list of windows, as one flat list of rows.
sub _outputs_plain ($self, $windows) {
    my ($x, $cols);
    for my $layer (@{ $self->{layers} }) {
        my $type = $layer->{type};
        if ($type eq 'embed') {
            $x    = _embedded($layer, $windows);
            $cols = @$x / @$windows;
        }
        elsif ($type eq 'dense') {
            $x    = _affine($x, @{ $layer->{weights} }, $cols);
            $cols = @{ $layer->{weights}[1] };
        }
        else { _activate($type, $x) }
    }
    return $x;
}

sub _outputs_pdl ($self, $windows) {
    my $x;
    for my $layer (@{ $self->{layers} }) {
        my $type = $layer->{type};
        if ($type eq 'embed') {
            my $flat = _embedded($layer, $windows);
            $x = PDL->pdl(PDL::double(), $flat)->reshape(@$flat / @$windows, scalar @$windows);
        }
        elsif ($type eq 'dense') { $x = ($x x $layer->{Wt}) + $layer->{bias} }
        elsif ($type eq 'relu')  { $x = $x * ($x > 0) }
        elsif ($type eq 'tanh')  { $x = PDL::tanh($x) }
        else                     { $x = 1 / (1 + exp(-$x)) }
    }
    return [ $x->list ];
}

# For each window the probability of every label, in the labels' order.
sub _probabilities ($self, $windows) {
    my $cols = @{ $self->{labels} };
    my @rows;
    for (my $start = 0; $start < @$windows; $start += $CHUNK) {
        my $end = $start + $CHUNK - 1;
        $end = $#$windows if $end > $#$windows;
        my @chunk = @$windows[ $start .. $end ];
        my $out   = $ENGINE eq 'pdl' ? $self->_outputs_pdl(\@chunk) : $self->_outputs_plain(\@chunk);
        for my $row (0 .. $#chunk) {
            my @z   = @$out[ $row * $cols .. ($row + 1) * $cols - 1 ];
            my $top = $z[0];
            for my $v (@z) { $top = $v if $v > $top }
            my $sum = 0;
            $sum += ($_ = exp($_ - $top)) for @z;       # the largest first becomes 1: nothing overflows
            $_ /= $sum for @z;
            push @rows, \@z;
        }
    }
    return \@rows;
}

sub _best ($probabilities) {
    my $best = 0;
    for my $i (1 .. $#$probabilities) { $best = $i if $probabilities->[$i] > $probabilities->[$best] }
    return $best;
}

# A decided edit, carried out. An edit that cannot apply to this string
# leaves it as it is.
sub _edited ($self, $text, $label) {
    my $side = $self->{side};
    return apply_edit2($text, $label) // $text if $side eq 'both';
    return apply_edit($text, $label)  // $text if $side eq 'right';
    my $result = apply_edit(scalar reverse($text), $label);    # at the front: the same on the reversed string
    return defined $result ? scalar reverse $result : $text;
}

# The windows of many strings and, for rewrite, how many belong to each.
sub _windows ($self, $texts, @values) {
    my @tokens = param_tokens($self->{params}, @values);
    my @chars  = map { [ split // ] } @$texts;
    return [ map { end_window($self, $_, @tokens) } @chars ] if $self->{kind} ne 'rewrite';
    return ([ map { my $c = $_; map { char_window($self, $c, $_, @tokens) } 0 .. $#$c } @chars ], [ map { scalar @$_ } @chars ]);
}

# The probability of every label, in the labels' order, for each of many
# windows.
sub probabilities ($self, $windows) { return $self->_probabilities($windows) }

# [index of the best label, its probability] for each of many windows: the
# model's decisions for input that is already tokens, which is what a fused
# model hands its parts.
sub decisions ($self, $windows) {
    return [ map { my $best = _best($_); [ $best, $_->[$best] ] } @{ $self->_probabilities($windows) } ];
}

# [answer, confidence] for each of many strings, all their decisions in one
# pass. For a rewrite the confidence is that of its least certain character.
sub answers ($self, $texts, @values) {
    my ($windows, $lengths) = $self->_windows($texts, @values);
    my $rows   = $self->_probabilities($windows);
    my $labels = $self->{labels};

    if ($self->{kind} eq 'rewrite') {
        my @answers;
        for my $length (@$lengths) {
            my ($result, $confidence) = ('', 1);
            for my $p (splice @$rows, 0, $length) {
                my $best = _best($p);
                $result .= $labels->[$best];
                $confidence = $p->[$best] if $p->[$best] < $confidence;
            }
            push @answers, [ $result, $confidence ];
        }
        return \@answers;
    }

    my $edit = $self->{kind} eq 'edit';
    return [
        map {
            my $best = _best($rows->[$_]);
            [ $edit ? $self->_edited($texts->[$_], $labels->[$best]) : $labels->[$best], $rows->[$_][$best] ]
        } 0 .. $#$texts
    ];
}

# The model's answer for a string, with its parameters if the model has any;
# in list context also its confidence.
sub predict ($self, $text, @given) {
    my ($answer) = @{ $self->answers([$text], $self->values_from(@given)) };
    return wantarray ? @$answer : $answer->[0];
}

# The answers for many strings at once, in their order, all with the same
# parameters.
sub predict_all ($self, $texts, @given) {
    return map { $_->[0] } @{ $self->answers($texts, $self->values_from(@given)) };
}

# Everything the model considers for a string, not only its best answer: a
# list of [answer, probability], most probable first, the probabilities
# adding up to 1. A model that is not sure shows it here. For an edit model
# the answers are the resulting strings (two edits giving the same string
# are one answer). For a rewrite it is one such list per character.
sub distribution ($self, $text, @given) {
    my ($windows) = $self->_windows([$text], $self->values_from(@given));
    my $rows   = $self->_probabilities($windows);
    my $labels = $self->{labels};
    my $sorted = sub ($p) {
        my %share;
        for my $i (0 .. $#$labels) {
            my $answer = $self->{kind} eq 'edit' ? $self->_edited($text, $labels->[$i]) : $labels->[$i];
            $share{$answer} += $p->[$i];
        }
        return [ map { [ $_, $share{$_} ] } sort { $share{$b} <=> $share{$a} || $a cmp $b } keys %share ];
    };
    return $self->{kind} eq 'rewrite' ? [ map { $sorted->($_) } @$rows ] : $sorted->($rows->[0]);
}

# One distribution for several strings together, for a class model: what
# label fits ALL of them, taking each string as independent evidence (the
# product of the probabilities, renormalised). A long text sharpens it; one
# short ambiguous word leaves it flat. Returned as distribution() does.
sub pooled ($self, $texts, @given) { return $self->pooled_for($texts, $self->values_from(@given)) }

# The same with the parameters' values in their order, as answers() takes them.
sub pooled_for ($self, $texts, @values) {
    die "pooling is for class models\n" if $self->{kind} ne 'class';
    my ($windows) = $self->_windows($texts, @values);
    return $self->pool($self->_probabilities($windows));
}

# The same from the probabilities themselves: one list per string, as
# probabilities() gives them.
sub pool ($self, $rows) {
    my $labels = $self->{labels};
    my @log    = (0) x @$labels;
    for my $p (@$rows) {
        $log[$_] += log($p->[$_] > $FLOOR ? $p->[$_] : $FLOOR) for 0 .. $#log;
    }
    my $top = $log[0];
    for my $v (@log) { $top = $v if $v > $top }
    my @share = map { exp($_ - $top) } @log;
    my $sum   = 0;
    $sum += $_ for @share;
    return [ sort { $b->[1] <=> $a->[1] || $a->[0] cmp $b->[0] } map { [ $labels->[$_], $share[$_] / $sum ] } 0 .. $#share ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Inference - load a trained model and get answers from it

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Inference;

    my $degree = Peta::NN::Inference->load('ces-adjective-degree.model');
    print scalar $degree->predict('chytřejší');                 # comparative

    my $convert = Peta::NN::Inference->load('ces-adjective-convert.model');
    print scalar $convert->predict('chytrý', 'superlative');    # nejchytřejší
    my @all = $convert->predict_all(\@adjectives, 'comparative');

    my ($answer, $confidence) = $degree->predict('nejistý');

    # every answer the model considers, most probable first
    printf "%-12s %.3f\n", @$_ for @{ $degree->distribution('lepší') };

    # one verdict for several strings together
    my $language = $identify->pooled([ split ' ', $sentence ]);

=head1 DESCRIPTION

This is the inference leg of Peta::NN. A model file is written by the
training leg (C<< Peta::NN::Model->export >>); reading and using it needs
only this module and L<Peta::NN::Codec>.

=head2 Parameters

A model may take parameters after the string: as many as it was trained
with, each one of the values it was trained with. A model whose parameters
have names takes them by name, C<< predict($noun, gender =E<gt> 'neuter') >>;
C<given> lists the names. (C<answers>, which pipelines and fused models
call, takes the values in their order.) They are opaque: the model
has learned what to do for C<'dative'>, not what a dative is. C<parameters>
lists the known values per position. The wrong number of parameters, or a
value the model never saw, is an error; nonsense that is well-formed is
answered like anything else.

=head2 Certainty

C<predict> gives the best answer and, in list context, its probability.
C<distribution> gives every answer with its probability. C<pooled> combines
the distributions of several strings into one, for class models.

=head2 Engine

C<engine> says what the arithmetic runs on: C<pdl> when this perl has PDL,
C<plain> otherwise or when C<PETA_NN_ENGINE=plain> is set.

=head2 Files

A model file is read as plain data (nothing in it is turned into an object,
so reading runs no code from the file) and checked in full before use: the
format marker, every field's type, that each layer fits its neighbours and
the labels, and that every weight is a finite number. A file that fails is
refused with the reason. By convention model files end in C<.model>.

Weights are stored with 32 bits each, or 8 (signed bytes and a scale per
array), as the exporter chose; in memory they are ordinary numbers either
way. C<info> returns what the file says of itself and what follows from its
contents.

=head1 METHODS

=head2 load

C<< Peta::NN::Inference->load($file) >>: the model of a model file. The file
is checked in full first.

=head2 new

C<< Peta::NN::Inference->new($data) >>: a model from model data, which is
checked first.

=head2 predict

C<predict($string, @parameters)>: the answer; in list context also its
confidence.

=head2 predict_all

C<predict_all(\@strings, @parameters)>: the answers, in order.

=head2 answers

C<answers(\@strings, @parameters)>: C<[answer, confidence]> for each string.

=head2 probabilities

C<probabilities(\@windows)>: for each window of token indices the probability
of every label, in the order of C<labels>.

=head2 pool

C<pool(\@probabilities)>: what C<pooled> answers, from the probabilities of
the strings themselves.

=head2 decisions

C<decisions(\@windows)>: C<[index of the best label, its probability]> for
each window of token indices. For callers that build the windows themselves,
as L<Peta::NN::Fused> does.

=head2 distribution

C<distribution($string, @parameters)>: every answer the model considers, as
a list of C<[answer, probability]>, most probable first. For a rewrite
model, one such list per character.

=head2 pooled

C<pooled(\@strings, @parameters)>: one distribution for several strings
together, for a class model.

=head2 data

The model data the object was made from, with the weights as they were
stored.

=head2 kind

C<class>, C<edit> or C<rewrite>.

=head2 labels

The answers the model can give.

=head2 given

The names of the parameters, in their order. Empty for a model without
parameters, and for one whose parameters were given no names.

=head2 values_from

C<values_from(@arguments)>: what a caller gave after the string, as the
parameters' values in their order: taken by name where the parameters have
names, as they come where they have none.

=head2 pooled_for

C<pooled_for(\@strings, @values)>: C<pooled> with the parameters' values in
their order.

=head2 parameters

The values the model knows for each of its parameters: one sorted list per
position.

=head2 n_params

The number of weights.

=head2 info

What there is to know about the model, for a human: what the file says of
itself and what follows from its contents.

=head1 FUNCTIONS

=head2 engine

C<pdl> or C<plain>: what the arithmetic runs on.

=head2 end_window

C<end_window($config, \@chars, @tokens)>: the window of the whole-string
kinds. Used by the training leg to read a string as the inference leg does.

=head2 char_window

C<char_window($config, \@chars, $position, @tokens)>: the window around one
character, for rewrite.

=head2 param_tokens

C<param_tokens($params, @values)>: the tokens of a call's parameters.

=head2 pack_weights

C<pack_weights(\@weights, $bits)>: a weight array as a model file stores it.

=head2 read_file

C<read_file($file, $format)>: a Storable file as plain data, refused unless
it carries the format marker.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
