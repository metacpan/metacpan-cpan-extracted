package Peta::NN::Pipeline;
# ABSTRACT: models in series, and routed by a classifier

# Models put together: in series, where each step's answer is the next step's
# input (Apfel -> Äpfel -> Äpfeln), and with routing, where a classifying
# step's answer decides which model a later step uses.
#
# The models stay what they are: each does its one limited transformation and
# knows nothing of the others, or of what its parameters mean. What a chain
# means is written here, in the pipeline's steps, by whoever builds it.
#
# This is part of the inference leg: it needs Peta::NN::Inference and the
# model files, nothing of the training leg.

use v5.36;

use Peta::NN::Inference;

our $VERSION = '0.2610090';

my $ANY = '*';      # in a routing table: the model for every answer not listed

# models   { name => model }: a model file's path, or an object that answers
#          (Peta::NN::Inference, or the training leg's Peta::NN::Model)
# steps    the steps, in order; each is a table with
#   model    the name of a model, or a routing table
#            { step => { answer => model name, ... } }: the model is chosen by
#            the answer of the earlier step called `step`; '*' stands for any
#            answer not listed
#   params   the step's parameters, each one of
#              'text'              that value, always
#              \N                  the Nth argument of the call (0 is the first)
#              { answer => step }  the answer of the earlier step called `step`
#   name     a name for the step, so that later steps can refer to its answer
#   classify true if the step only looks: its answer is recorded under its
#            name, and the string goes on to the next step unchanged
#   pool     true if a classifying step answers once for all strings of a
#            text together (run_texts): every word is evidence, and the
#            text gets the one answer they point to
sub new ($class, %arg) {
    my $models = $arg{models} // die "models => { name => model, ... } is required\n";
    my $steps  = $arg{steps}  // die "steps => [ ... ] is required\n";
    die "a pipeline needs at least one step\n" if !@$steps;

    my %model = map {
        my $model = $models->{$_};
        $_ => !ref $model               ? Peta::NN::Inference->load($model)
            : $model->can('inference')  ? $model->inference
            :                             $model
    } keys %$models;

    my (%named, $arguments);
    my $self = bless { model => \%model, steps => [] }, $class;
    for my $n (0 .. $#$steps) {
        my %step  = %{ $steps->[$n] };
        my $where = 'step ' . ($n + 1);
        my $spec  = $step{model} // die "$where names no model\n";

        # Every model a step may use must exist, and a routing step must
        # route by a step that came before it.
        my @used = $spec;
        if (ref $spec eq 'HASH') {
            my ($by, @more) = keys %$spec;
            die "$where routes by more than one step\n" if @more;
            die "$where routes by '$by', which is not an earlier step\n" if !$named{$by};
            @used = values %{ $spec->{$by} };
        }
        defined $model{$_} or die "$where uses the model '$_', which the pipeline does not have\n" for @used;

        for my $param (@{ $step{params} // [] }) {
            if (ref $param eq 'HASH') {
                my $from = $param->{answer} // die "$where has a parameter that is a table without `answer`\n";
                die "$where takes a parameter from '$from', which is not an earlier step\n" if !$named{$from};
            }
            elsif (ref $param eq 'SCALAR') {
                die "$where has an argument number that is not a whole number\n" if $$param !~ /\A[0-9]+\z/;
                $arguments = $$param + 1 if $$param + 1 > ($arguments // 0);
            }
            elsif (ref $param) { die "$where has a parameter that is neither text, \\N nor { answer => step }\n" }
        }
        die "$where only classifies, so it needs a name for its answer\n" if $step{classify} && !defined $step{name};
        die "$where pools, which is for a step that classifies\n" if $step{pool} && !$step{classify};
        for my $model (grep { $_->can('kind') } @model{@used}) {
            die "$where pools, which is for class models\n" if $step{pool} && $model->kind ne 'class';
        }
        $named{ $step{name} } = 1 if defined $step{name};
        push @{ $self->{steps} }, \%step;
    }
    $self->{arguments} = $arguments // 0;
    return $self;
}

# How many arguments a call takes after the string.
sub arguments ($self) { return $self->{arguments} }

# Run many strings through the steps. Returns one record per string:
#   { text, confidence, answers => { step name => answer }, trace => [ ... ] }
# with a trace entry [model name, parameters, input, output, confidence] per
# step. Strings that reach a step with the same model and parameters go
# through it in one pass.
sub run ($self, $texts, @arguments) { return $self->_run($texts, [ 0 .. $#$texts ], @arguments) }

# Run many texts, each a list of strings (its words, say). Returns for each
# text the records of its strings. What differs from run() is a pooling
# step: it answers once per text.
sub run_texts ($self, $texts, @arguments) {
    my @of     = map { my $n = $_; ($n) x @{ $texts->[$n] } } 0 .. $#$texts;
    my $states = $self->_run([ map { @$_ } @$texts ], \@of, @arguments);
    my @result = map { [] } @$texts;
    push @{ $result[ $of[$_] ] }, $states->[$_] for 0 .. $#of;
    return \@result;
}

# $of says for each string which text it belongs to.
sub _run ($self, $texts, $of, @arguments) {
    die sprintf "this pipeline takes %d argument%s after the string, not %d\n",
        $self->{arguments}, $self->{arguments} == 1 ? '' : 's', scalar @arguments if @arguments != $self->{arguments};

    my @state = map { { text => $texts->[$_], of => $of->[$_], confidence => 1, answers => {}, trace => [] } } 0 .. $#$texts;
    for my $step (@{ $self->{steps} }) {
        my %batch;      # "model, parameters" => the states that take this step that way
        for my $state (@state) {
            my $spec = $step->{model};
            my $name = $spec;
            if (ref $spec) {
                my ($by)   = keys %$spec;
                my $answer = $state->{answers}{$by};
                $name = $spec->{$by}{$answer} // $spec->{$by}{$ANY}
                    // die "no model for the answer '$answer' of step '$by'\n";
            }
            my @values = map { ref eq 'HASH' ? $state->{answers}{ $_->{answer} } : ref eq 'SCALAR' ? $arguments[$$_] : $_ }
                         @{ $step->{params} // [] };
            push @{ $batch{ join "\x{1f}", $name, @values }{states} }, $state;
            $batch{ join "\x{1f}", $name, @values }{call} //= [ $name, @values ];
        }
        for my $group (values %batch) {
            my ($name, @values) = @{ $group->{call} };
            my @states  = @{ $group->{states} };
            if ($step->{pool}) {
                my %text;
                push @{ $text{ $_->{of} } }, $_ for @states;
                for my $members (values %text) {
                    my ($answer, $share) = @{ $self->{model}{$name}->pooled_for([ map { $_->{text} } @$members ], @values)->[0] };
                    for my $state (@$members) {
                        push @{ $state->{trace} }, [ $name, \@values, $state->{text}, $answer, $share ];
                        $state->{confidence} *= $share;
                        $state->{answers}{ $step->{name} } = $answer;
                    }
                }
                next;
            }
            my $answers = $self->{model}{$name}->answers([ map { $_->{text} } @states ], @values);
            for my $n (0 .. $#states) {
                my ($state, $answer, $confidence) = ($states[$n], @{ $answers->[$n] });
                push @{ $state->{trace} }, [ $name, \@values, $state->{text}, $answer, $confidence ];
                $state->{confidence} *= $confidence;
                $state->{answers}{ $step->{name} } = $answer if defined $step->{name};
                $state->{text} = $answer if !$step->{classify};
            }
        }
    }
    return \@state;
}

# The pipeline's answer for a string; in list context also its confidence,
# the product of the steps' confidences: a chain is as sure as all its links
# together.
sub predict ($self, $text, @arguments) {
    my ($state) = @{ $self->run([$text], @arguments) };
    return wantarray ? @$state{qw(text confidence)} : $state->{text};
}

# The answers for many strings at once, in their order.
sub predict_all ($self, $texts, @arguments) {
    return map { $_->{text} } @{ $self->run($texts, @arguments) };
}

# The same steps as one fused model (Peta::NN::Fused): the models as they
# are, and what happens here between two steps inside it. Options as for
# Peta::NN::Fused->new (engine, meta). Only steps in series fuse.
sub fuse ($self, %arg) {
    require Peta::NN::Fused;
    return Peta::NN::Fused->new(models => $self->{model}, steps => $self->{steps}, %arg);
}

# What each step did with one string: a list of
# [model name, parameters, input, output, confidence].
sub trace ($self, $text, @arguments) {
    my ($state) = @{ $self->run([$text], @arguments) };
    return @{ $state->{trace} };
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Pipeline - models in series, and routed by a classifier

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Pipeline;

    # In series: Apfel -> Äpfel -> Äpfeln. The case is the call's argument.
    my $decline = Peta::NN::Pipeline->new(
        models => { number => 'deu-noun-number.model', case => 'deu-noun-case.model' },
        steps  => [
            { model => 'number', params => ['plural'] },
            { model => 'case',   params => [ \0 ] },
        ],
    );
    print scalar $decline->predict('Apfel', 'dative');          # Äpfeln

    # Routed: a classifier names the word class, and that picks the model.
    my $inflect = Peta::NN::Pipeline->new(
        models => { class => 'ces-wordclass.model', noun => 'ces-noun.model', adjective => 'ces-adjective.model' },
        steps  => [
            { name => 'class', model => 'class', classify => 1 },
            { model => { class => { noun => 'noun', adjective => 'adjective' } }, params => [ \0 ] },
        ],
    );

    my ($answer, $confidence) = $inflect->predict($word, 'genitive');
    printf "%-10s %s -> %s (%.2f)\n", @$_[ 0, 2, 3, 4 ] for $inflect->trace($word, 'genitive');

=head1 DESCRIPTION

A step's parameters are given as text (always that value), as C<\N> (the
call's Nth argument, counting from 0), or as C<< { answer => 'step' } >>
(what an earlier, named step answered).

A step with C<classify> only looks: its answer is kept under its name and
the string passes on unchanged. With C<pool> as well it looks at a
whole text at once (C<run_texts>) and gives all its strings one answer. A later step can use that answer as a
parameter, or to choose its model through a routing table; C<'*'> in the
table stands for any answer not listed.

The confidence of a pipeline's answer is the product of its steps'. Errors
multiply along a chain, and so does doubt.

=head1 METHODS

=head2 new

C<< Peta::NN::Pipeline->new(models => { name => model }, steps => [...]) >>.
A model is a model file's path or an object that answers. A step is a table
with C<model> (a name, or a routing table C<< { step => { answer => model } } >>),
C<params>, C<name> and C<classify>.

=head2 predict

C<predict($string, @arguments)>: the pipeline's answer; in list context also
its confidence.

=head2 predict_all

C<predict_all(\@strings, @arguments)>: the answers, in order.

=head2 trace

C<trace($string, @arguments)>: what each step did, as a list of
C<[model name, parameters, input, output, confidence]>.

=head2 run

C<run(\@strings, @arguments)>: one record per string,
C<< { text, confidence, answers, trace } >>.

=head2 run_texts

C<run_texts(\@texts, @arguments)>: the same for texts, each a list of
strings (its words, say); returns the records per text. A step with C<pool>
answers once per text: every string of the text is evidence, each gets the
one answer they point to together, and its confidence.

=head2 arguments

How many arguments a call takes after the string.

=head2 fuse

C<fuse(%options)>: the same steps as one L<Peta::NN::Fused> model, which
answers what the pipeline answers without coming back to Perl between the
steps. Options are those of C<< Peta::NN::Fused->new >>.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
