package OpenTracing::Tracer;

use strict;
use warnings;

our $VERSION = '1.003'; # VERSION
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

use List::Util qw(min);
use Scalar::Util qw(refaddr);
use Time::HiRes ();

use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
    my ($class, %args) = @_;
    $args{span_completion_callbacks} ||= [];
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
            pid              => $$,
            ip               => Net::Address::IP::Local->public_ipv4,
            'tracer.version' => 'perl-OpenTracing-' . __PACKAGE__->VERSION,
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
    $self->add_span(
        my $span = OpenTracing::Span->new(
            tracer => $self,
            parent => $self->{current_span},
            %args
        )
    );
    $self->{current_span} = $span;
    return OpenTracing::SpanProxy->new(span => $span);
}

sub current_span { shift->{current_span} }

sub finish_span {
    my ($self, $span) = @_;
    $log->tracef('Finishing span %s', $span);
    undef $self->{current_span} if $self->{current_span} and refaddr($self->{current_span}) == refaddr($span);

    return $span unless $self->is_enabled;
    push @{$self->{finished_spans} //= []}, $span;
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
            map {; $_ => $span->$_ } qw(id parent_id operation_name start_time finish_time),
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

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

