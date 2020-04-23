package OpenTracing::Tracer;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

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

use Time::HiRes ();

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

=head2 process

Returns the current L<OpenTracing::Process>.

=cut

sub process {
    shift->{process} //= OpenTracing::Process->new(
        pid => $$
    )
}

sub is_enabled { shift->{is_enabled} }

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

Adds a new L<OpenTracing::Span> instance to this batch.

=cut

sub add_span {
    my ($self, $span) = @_;
    push $self->{spans}->@*, $span;
    Scalar::Util::weaken($span->{batch});
    $span
}

sub span {
    my ($self, $name, %args) = @_;
    $args{operation_name} = $name // (caller 1)[3];
    $args{start_time} //= Time::HiRes::time() * 1_000_000;
    $self->add_span(
        my $span = OpenTracing::Span->new(
            tracer => $self,
            %args
        )
    );
    return OpenTracing::SpanProxy->new(span => $span);
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

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

