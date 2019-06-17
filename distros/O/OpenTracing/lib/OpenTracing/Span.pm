package OpenTracing::Span;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent qw(OpenTracing::Common);

=encoding utf8

=head1 NAME

OpenTracing::Span - represents an operation or parent operation

=head1 DESCRIPTION

The reference definition for a span is a good starting point for understanding these:

L<https://opentracing.io/docs/overview/spans/>

=cut

use Time::HiRes ();
use Math::Random::Secure ();

=head2 trace_id

The trace ID for this span. Multiple spans are grouped under a single trace.

=cut

sub trace_id { shift->{trace_id} //= Math::Random::Secure::irand(2**63) }

=head2 id

The span ID. This should be unique.

=cut

sub id { shift->{id} //= Math::Random::Secure::irand(2**63) }

=head2 parent_id

Parent span ID. 0 if there isn't one.

=cut

sub parent_id { shift->{parent_id} // 0 }

=head2 flags

Any flags relating to this span.

=cut

sub flags { shift->{flags} // 0 }

=head2 start_time

Exact time this span started, in microseconds.

=cut

sub start_time { shift->{start_time} //= (Time::HiRes::time() * 1_000_000) }

=head2 duration

Total duration of this span, including any nested spans.

=cut

sub duration { shift->{duration} }

=head2 operation_name

The operation that this span represents.

=cut

sub operation_name { shift->{operation_name} }

=head2 tags

The tags relating to this span.

=cut

sub tags { shift->{tags} }

=head2 batch

The L<OpenTracing::Batch> instance that this span belongs to.

=cut

sub batch { shift->{batch} }

=head2 tag_list

A list of tags as L<OpenTracing::Tag> instances.

=cut

sub tag_list {
    my $tags = shift->{tags} //= [];
    map { OpenTracing::Tag->new(key => $_, value => $tags->{$_}) } sort keys %$tags;
}

=head2 logs

The arrayref of log entries for this span, as L<OpenTracing::Log> instances.

=cut

sub logs { shift->{logs} }

=head2 log_list

A list of log entries for this span, as L<OpenTracing::Log> instances.

=cut

sub log_list {
    (shift->{logs} //= [])->@*
}

=head2 log

Records a single log message.

=cut

sub log : method {
    my ($self, $message, %args) = @_;
    $args{message} = $message;
    my $timestamp = delete($args{timestamp}) // Time::HiRes::time() * 1_000_000;
    push +($self->{logs} //= [])->@*, my $log = OpenTracing::Log->new(
        tags => {
            message => $message,
        },
        timestamp => $timestamp
    );
    $log;
}

=head2 finish

Mark this span as finished (populating the L</duration> field).

=cut

sub finish {
    my ($self) = @_;
    $self->{duration} = (Time::HiRes::time * 1_000_000) - $self->start_time;
    $self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

