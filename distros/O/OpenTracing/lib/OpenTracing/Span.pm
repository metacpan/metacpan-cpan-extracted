package OpenTracing::Span;

use strict;
use warnings;

our $VERSION = '1.004'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(OpenTracing::Common);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Span - represents an operation or parent operation

=head1 DESCRIPTION

The reference definition for a span is a good starting point for understanding these:

L<https://opentracing.io/docs/overview/spans/>

=cut

use Time::HiRes ();
use Bytes::Random::Secure qw(random_bytes_hex);

=head2 new

Instantiates a new span. Rarely called directly - you'd want to let the L<OpenTracing::Tracer> take
care of this for you.

Takes the following named parameters:

=over 4

=item * C<parent> - an L<OpenTracing::Span> for a parent instance (optional)

=item * C<parent_id> - the span ID for the parent (optional)

=item * C<trace_id> - the current trace ID (optional)

=item * C<operation_name> - what to use for this span name

=back

=cut

sub new {
    my ($class, %args) = @_;
    $args{operation_name} //= (caller 1)[3];
    if(my $parent = $args{parent}) {
        $args{parent_id} = $parent->{id};
        $args{trace_id} = $parent->{trace_id};
    }

    # Alternatively reduce { $a * 1_000_000 + $b } Time::HiRes::gettimeofday(),
    # but the time() version benchmarks to ~3x faster
    $args{start_time} //= int(Time::HiRes::time() * 1_000_000);
    bless \%args, $class
}

=head2 trace_id

The trace ID for this span. Multiple spans are grouped under a single trace.

=cut

sub trace_id { shift->{trace_id} //= random_bytes_hex(16) }

=head2 id

The span ID. This should be unique.

=cut

sub id { shift->{id} //= random_bytes_hex(8) }

=head2 parent_id

Parent span ID. 0 if there isn't one.

=cut

sub parent_id { shift->{parent_id} //= '0' x 8; }

=head2 flags

Any flags relating to this span.

=cut

sub flags { shift->{flags} // 0 }

=head2 start_time

Exact time this span started, in microseconds.

=cut

sub start_time { shift->{start_time} //= int(Time::HiRes::time() * 1_000_000) }

=head2 start_time

Exact time this span finished, in microseconds.

Returns C<undef> if the span is not yet finished.

=cut

sub finish_time { shift->{finish_time} }

=head2 duration

Total duration of this span, including any nested spans.

=cut

sub duration {
    my ($self) = @_;
    return undef unless defined $self->{finish_time};
    $self->{duration} //= $self->finish_time - $self->start_time;
}

=head2 operation_name

The operation that this span represents.

=cut

sub operation_name { shift->{operation_name} }

=head2 tags

The tags relating to this span.

=cut

sub tags { shift->{tags} }

=head2 tag_list

A list of tags as L<OpenTracing::Tag> instances.

=cut

sub tag_list {
    my $tags = shift->{tags} //= {};
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
    my $timestamp = delete($args{timestamp}) // int(Time::HiRes::time() * 1_000_000);
    push +($self->{logs} //= [])->@*, my $log = OpenTracing::Log->new(
        tags => \%args,
        timestamp => $timestamp
    );
    $log;
}

=head2 tag

Applies key/value tags to this span.

The L<semantic conventions|https://github.com/opentracing/specification/blob/master/semantic_conventions.md>
may be of interest here.

Example usage:

 $span->tag(
  'http.status_code' => 200,
  'http.url' => 'https://localhost/xxx',
  'http.method' => 'GET'
 );

=cut

sub tag : method {
    my ($self, %args) = @_;
    @{$self->{tags}}{keys %args} = values %args;
    return $self;
}

=head2 references

The references relating to this span.

=cut

sub references { shift->{references} }

=head2 reference_list

A list of reference entries for this span, as L<OpenTracing::Reference> instances.

=cut

sub reference_list {
    (shift->{references} //= [])->@*
}


=head2 reference

Records a reference.

=cut

sub reference : method {
    my ($self, %args) = @_;
    push +($self->{references} //= [])->@*, my $reference = OpenTracing::Reference->new(%args);
    $reference;
}

=head2 tracer

Returns the L<OpenTracing::Tracer> for this span.

=cut

sub tracer { shift->{tracer} }

=head2 is_finished

Returns true if this span is finished (has a L</finish_time>), otherwise false.

=cut

sub is_finished { defined shift->{finish_time} }

=head2 finish

Mark this span as finished (populating the L</finish_time> field).

=cut

sub finish {
    my ($self, $ts) = @_;
    unless($self->is_finished) {
        $ts //= int(Time::HiRes::time * 1_000_000);
        $self->{finish_time} = $ts;
        $self->tracer->finish_span($self);
    }
    $self
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

