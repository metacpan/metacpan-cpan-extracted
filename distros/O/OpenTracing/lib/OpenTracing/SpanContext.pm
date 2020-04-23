package OpenTracing::SpanContext;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

use parent qw(OpenTracing::Common);

=encoding utf8

=head1 NAME

OpenTracing::SpanContext - tracks IDs and baggage for spans

=head1 DESCRIPTION

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

sub log { shift->span->log(@_) }

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
    $parent->tracer->new_span($name => %args);
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

