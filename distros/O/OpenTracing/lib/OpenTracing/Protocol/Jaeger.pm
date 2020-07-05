package OpenTracing::Protocol::Jaeger;

use strict;
use warnings;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Protocol::Jaeger - support for Jæger binary Thrift representation of OpenTracing data

=head1 DESCRIPTION

See L<https://github.com/jaegertracing/jaeger-idl/blob/master/thrift/jaeger.thrift> for
the current format.

=cut

use Log::Any qw($log);
use Role::Tiny::With;

BEGIN {
    # We *prefer* Unicode::UTF8, but should not absolutely
    # require it here.
    *encode_utf8 = eval {
        require Unicode::UTF8
    } ? \&Unicode::UTF8::encode_utf8
      : eval {
        require Encode;
    } ? \&Encode::encode_utf8
      : die 'cannot find UTF8 encoder, try installing Unicode::UTF8';
}

with qw(OpenTracing::Protocol);

sub new { bless { @_[1..$#_] }, $_[0] }

# We're collecting binary Thrift protocol data here, likely to be sent via UDP.

=head2 encode_batch

Given an L<OpenTracing::Batch>, iterates through the process and spans,
returning a byte string containing binary Thrift data.

=cut

sub encode_batch {
    my ($self, $batch) = @_;
    $log->tracef('Will try to encode batch %s', $batch);

    $log->tracef('Batch spans: %s', $batch->spans);
    my $data = '';
    $data .= pack 'C1n1',
        12, # struct Batch
        1;  # field 1
    $data .= $self->encode_process($batch->process);
    $data .= $self->encode_span_list($batch->spans);
    $data .= pack 'C1', 0; # EOF marker for Batch
    return $data;
}

=head2 encode_tags

Given a C<$field_id> and a C<$tags> hashref, encodes the key/value
tag data as a struct with the given C<$field_id> and returns a
byte string representing that data.

=cut

sub encode_tags {
    my ($self, $field_id, $tags) = @_;
    my $data = '';
    # list Tag
    $data .= pack 'C1n1 C1N1',
        15, # list
        $field_id, # field ID is usually 2, or 10 for spans
        12, # struct
        0 + keys %$tags if %$tags;
    for my $k (sort keys %$tags) {
        $data .= pack 'C1n1N/a* C1n1N1 C1n1N/a* C1',
            11, # type = string
            1, # field ID = 1
            encode_utf8($k // ''),
            8, # type = int32 (enum)
            2, # field ID = 2
            0, # entry 0 is string
            11, # type = string
            3, # field ID = 3
            encode_utf8($tags->{$k} // ''),
            0; # EOF marker
    }
    return $data;
}

=head2 encode_process

Given an L<OpenTracing::Process> instance, encodes using the binary Thrift
protocol and returns as byte string data.

=cut

sub encode_process {
    my ($self, $process) = @_;
    my $data = '';
    # Process
    $data .= pack 'C1n1 C1n1N/a*',
        12, # struct
        1, # field id 1 = Process
    # string serviceName
        11, # string
        1, # field ID 1 = serviceName
        encode_utf8($process->name // '');

    if(my $tags = $process->tags) {
        $data .= $self->encode_tags(2, $tags);
    }
    $data .= pack 'C1', 0; # EOF marker for process
    return $data;
}

=head2 encode_span_list

Encodes a span list given in the C<$spans> arrayref, calling
L</encode_span> for each one, returning byte string data.

=cut

sub encode_span_list {
    my ($self, $spans) = @_;
    my $data = '';
    $data .= pack 'C1n1C1N1',
        15, # list
        2,  # field ID 2, spans
        12, # 12 is struct
        0 + @$spans;
    $data .= $_ for map { $self->encode_span($_) } @$spans;
    return $data;
}

=head2 encode_span

Encodes the given L<OpenTracing::Span> instance, returning byte string data.

=cut

sub encode_span {
    my ($self, $span) = @_;
    my $data = '';
    $data .= pack 'CnH16 CnH16 CnH16 CnH16 CnN/a* CnN CnQ> CnQ>',
        # trace_id_low
        10,
        1,
        substr($span->trace_id, 16, 16),
        # trace_id_high
        10,
        2,
        substr($span->trace_id, 0, 16),
        # span_id
        10,
        3,
        substr($span->id, 0, 16),
        # parent_span_id
        10,
        4,
        substr($span->parent_id, 0, 16),
        # operation_name
        11,
        5,
        encode_utf8($span->operation_name // ''),
        # references
        # flags
        8,
        7,
        $span->flags // 0,
        # start_time
        10,
        8,
        $span->start_time,
        # duration
        10,
        9,
        $span->duration;
    if(my $tags = $span->tags) {
        $data .= $self->encode_tags(10, $tags);
    }

    if(my $logs = $span->logs) {
        # list Log
        $data .= pack 'C1n1 C1N1',
            15, # list
            11, # field ID 11 for logs
            12, # struct
            0 + @$logs;
        for my $log (@$logs) {
            my $tags = $log->tags;
            $data .= pack 'C1n1Q>',
                10, # type = int64
                1, # field ID = 1
                $log->timestamp;
            $data .= $self->encode_tags(2, $tags) if $tags;
            $data .= pack 'C1', 0; # EOF for log
        }
    }

    $data .= pack 'C1', 0; # EOF for span
    return $data;
}

=head2 bytes_from_span

Generate byte string encoding for the given L<OpenTracing::Span> instance.

=cut

sub bytes_from_span {
    my ($self, $span) = @_;
    return $self->encode_span($span);
}

=head2 span_from_bytes

Converts a byte string representation into an L<OpenTracing::Span> instance.

=cut

sub span_from_bytes {
    my ($self, $data) = @_;
    ...
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

