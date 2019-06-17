package OpenTracing::Batch;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent qw(OpenTracing::Common);

=encoding utf8

=head1 NAME

OpenTracing::Batch - represents a group of zero or more spans

=head1 DESCRIPTION

A batch of spans is used for submitting results to an opentracing endpoint.

Once you've created a batch, take a look at L</new_span> and the L<OpenTracing::SpanProxy>
class.

=cut

use Time::HiRes;
use Scalar::Util ();

=head1 METHODS

=head2 process

Returns the L<OpenTracing::Process> that this batch applies to. Each batch is
submitted from a single process.

=cut

sub process { shift->{process} //= OpenTracing::Process->new }

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

=head2 new_span

Creates a new L<OpenTracing::Span>, adds it to this batch, and returns an
L<OpenTracing::SpanProxy> instance (which will automatically mark the end
of the span when it's destroyed).

This is most likely to be the method you'll want for working with spans
in user code.

=cut

sub new_span {
    my ($self, $name, %args) = @_;
    $args{operation_name} = $name;
    $args{start_time} //= Time::HiRes::time() * 1_000_000;
    $self->add_span(my $span = OpenTracing::Span->new(batch => $self, %args));
    OpenTracing::SpanProxy->new(span => $span)
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

