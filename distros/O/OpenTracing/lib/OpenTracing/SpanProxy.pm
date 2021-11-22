package OpenTracing::SpanProxy;

use strict;
use warnings;

our $VERSION = '1.004'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(OpenTracing::Common);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::SpanProxy - wrapper around an L<OpenTracing::Span>

=head1 DESCRIPTION

This is the wrapper class that user code would normally receive when working
with spans. It allows the creation of nested subspans, and will automatically
mark the span as complete when the proxy object is discarded.

For methods available here, see L<OpenTracing::Span>.

=cut

=head2 span

Returns the L<OpenTracing::Span> instance that this wraps.

=cut

sub span { shift->{span} }

=head2 log

Writes a log entry to the L<OpenTracing::Span>.

=cut

sub id { shift->span->id }

sub trace_id { shift->span->trace_id }

sub parent_id { shift->span->parent_id }

sub log { shift->span->log(@_) }

sub logs { shift->span->logs }

sub tags { shift->span->tags }

sub tag { shift->span->tag(@_) }

sub reference { shift->span->reference(@_) }

sub references { shift->span->references }

sub start_time { shift->span->start_time }

sub finish_time { shift->span->finish_time }

sub duration { shift->span->duration(@_) }

sub finish { shift->span->finish(@_) }

sub is_finished { shift->span->is_finished }

sub operation_name { shift->span->operation_name }

sub flags { shift->span->flags }

=head2 new_span

Creates a new sub-span under this L<OpenTracing::Span> instance.

=cut

sub new_span {
    my ($self, $name, %args) = @_;
    my $parent = $self->span;
    @args{qw(trace_id parent_id)} = (
        $parent->trace_id,
        $parent->id,
    );
    $parent->tracer->span(
        operation_name => $name,
        %args
    );
}

=head2 DESTROY

Called on destruction, will mark completion on the span by calling
L<OpenTracing::Span/finish>.

=cut

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $self->span->finish unless $self->span->is_finished;
    delete $self->{span};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

