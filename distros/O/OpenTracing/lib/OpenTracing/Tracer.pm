package OpenTracing::Tracer;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Tracer - application tracing

=head1 DESCRIPTION

This provides the interface between the OpenTracing API and the tracing service(s)
for an application.

Typically a single process would have one tracer instance.

=cut

use OpenTracing::Process;
use OpenTracing::Span;
use OpenTracing::SpanProxy;
use OpenTracing::Reference;

use List::Util qw(min);
use Scalar::Util qw(refaddr);
use Time::HiRes ();

use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
    my ($class, %args) = @_;
    $args{span_completion_callbacks} ||= [];
    $args{current_span} ||= [];
    bless \%args, $class
}

=head2 process

Returns the current L<OpenTracing::Process>.

=cut

sub process {
    my ($self) = @_;

    # Handle forks
    if($self->{process} and $self->{process}->pid != $$) {
        delete $self->{process};
    }

    $self->{process} //= do {
        require Net::Address::IP::Local;
        OpenTracing::Process->new(
            tags => {
                pid              => $$,
                ip               => Net::Address::IP::Local->public_ipv4,
                # When running from the repository, we won't have a ->VERSION, so
                # we'll default to the main package but indicate with -dev that
                # we may have differences from the "official" version
                'tracer.version' => 'perl-OpenTracing-' . (__PACKAGE__->VERSION // ((OpenTracing->VERSION // "unknown") . "-dev")),
            }
        );
    }
}

=head2 is_enabled

Returns true if this tracer is currently enabled.

=cut

sub is_enabled { shift->{is_enabled} //= 0 }

=head2 enable

Enable the current tracer.

=cut

sub enable { shift->{is_enabled} = 1 }

=head2 disable

Disable the current tracer.

=cut

sub disable { shift->{is_enabled} = 0 }

=head2 spans

Returns an arrayref of L<OpenTracing::Span> instances.

=cut

sub spans {
    shift->{spans}
}

=head2 span_list

Returns a list of L<OpenTracing::Span> instances.

=cut

sub span_list {
    (shift->{spans} //= [])->@*
}

=head2 add_span

Adds a new L<OpenTracing::Span> instance to the pending list, if
we're currently enabled.

=cut

sub add_span {
    my ($self, $span) = @_;
    return $span unless $self->is_enabled;
    push $self->{spans}->@*, $span;
    Scalar::Util::weaken($span->{batch});
    $span
}

sub span {
    my ($self, %args) = @_;
    $args{operation_name} //= (caller 1)[3];

    # We want to figure out what parent to
    # use, following as precedence order:
    # - Parent args
    # - First CHILD_OF reference
    # - First FOLLOW_FROM reference
    # - Current trace span
    my $parent = $args{parent};
    unless ($parent)
    {
        my @reference_queue = ();

        # Default to current span if any
        if (my $current_span = $self->{current_span}->[-1])
        {
            push @reference_queue, {
                id => $current_span->id,
                trace_id => $current_span->trace_id
            };
        }

        if(my $references = $args{references}) {
            foreach my $reference (@$references) {
                next unless $reference; # skip empty references if any

                push @reference_queue, {
                    id => $reference->context->id,
                    trace_id => $reference->context->trace_id
                };

                # Stop the loop if CHILD_OF is found
                last if $reference->ref_type == OpenTracing::Reference::CHILD_OF;

                # Otherwise loop over FOLLOWS_FROM just in case we find a CHILD_OF later
            }
        }

        # Take the first found reference (either CHILD_OF or FOLLOWS_FROM) or PARENT)
        $parent = shift @reference_queue;
    }

    $self->add_span(
        my $span = OpenTracing::Span->new(
            tracer => $self,
            parent => $parent,
            %args
        )
    );
    push @{ $self->{current_span} }, $span;
    return OpenTracing::SpanProxy->new(span => $span);
}

sub current_span { shift->{current_span}->[-1] }

sub finish_span {
    my ($self, $span) = @_;
    $log->tracef('Finishing span %s', $span);

    @{ $self->{current_span} }  = grep { refaddr($_) != refaddr($span)} @{ $self->{current_span} };

    push @{$self->{finished_spans} //= []}, $span;
    return $span unless $self->is_enabled;

    $_->($span) for $self->span_completion_callbacks;
    return $span;
}

sub add_span_completion_callback {
    my ($self, $code) = @_;
    push $self->{span_completion_callbacks}->@*, $code;
    return $self;
}

sub remove_span_completion_callback {
    my ($self, $code) = @_;
    my $addr = Scalar::Util::refaddr($code);
    my $data = $self->{span_completion_callbacks};
    # Essentially extract_by from List::UtilsBy
    for(my $idx = 0; ; ++$idx) {
        last if $idx > $#$data;
        next unless Scalar::Util::refaddr($data->[$idx]) == $addr;
        splice @$data, $idx, 1, ();
        # Skip the $idx change
        redo;
    }
    return $self;
}

sub span_completion_callbacks {
    shift->{span_completion_callbacks}->@*
}

sub inject {
    my ($self, $span, %args) = @_;
    $args{format} //= 'text_map';
    if($args{format} eq 'text_map') {
        return {
            map {; $_ => $span->$_ } qw(id trace_id parent_id operation_name start_time finish_time),
        }
    } else {
        die 'unknown format ' . $args{format}
    }
}

sub span_for_future {
    my ($self, $f, %args) = @_;
    my $span = $self->span(
        operation_name => $f->label,
        %args,
    );
    $f->on_ready(sub {
        $span->tag(
            'future.state' => $f->state
        );
        $span->finish;
        undef $f;
        undef $span
    });
    return $span;
}

sub extract {
    my ($self, $data, %args) = @_;
    $args{format} //= 'text_map';
    if($args{format} eq 'text_map') {
        @$data{tracer} = $self;
        return OpenTracing::Span->new(%$data);
    } else {
        die 'unknown format ' . $args{format}
    }
}

sub extract_finished_spans {
    my ($self, $count) = @_;
    if(!defined($count)) {
        $count = 10;
    } elsif(!$count) {
        $count = @{$self->{finished_spans}};
    }
    return splice @{$self->{finished_spans}}, 0, min(0 + @{$self->{finished_spans}}, $count);
}

sub child_of {
    my ($self, $context) = @_;
    die "Can't create a child_of reference without a valid context" unless $context;
    return OpenTracing::Reference->new(
        ref_type => OpenTracing::Reference::CHILD_OF,
        context => $context);
}

sub follows_from {
    my ($self, $context) = @_;
    die "Can't create a follow_from reference without a valid context" unless $context;
    return OpenTracing::Reference->new(
        ref_type => OpenTracing::Reference::FOLLOWS_FROM,
        context => $context);
}

=head2 DESTROY

Triggers callbacks when the batch is discarded. Normally used by the transport
mechanism to ensure that the batch is sent over to the tracing endpoint.

=cut

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    my $on_destroy = delete $self->{on_destroy}
        or return;
    $self->$on_destroy;
    return;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

