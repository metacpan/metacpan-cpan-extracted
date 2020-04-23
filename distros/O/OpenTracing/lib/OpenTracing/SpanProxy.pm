package OpenTracing::SpanProxy;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

=encoding utf8

=head1 NAME

OpenTracing::SpanProxy - wrapper around an L<OpenTracing::Span>

=head1 DESCRIPTION

This is the wrapper class that user code would normally receive when working
with spans. It allows the creation of nested subspans, and will automatically
mark the span as complete when the proxy object is discarded.

=cut

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

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
sub duration { shift->span->duration(@_) }
sub finish { shift->span->finish(@_) }

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
    $parent->tracer->span($name => %args);
}

=head2 DESTROY

Called on destruction, will mark completion on the span by calling
L<OpenTracing::Span/finish>.

=cut

sub DESTROY {
    my ($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $self->span->finish;
    delete $self->{span};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

