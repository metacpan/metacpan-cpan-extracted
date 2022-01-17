package OpenTracing::Protocol::Zipkin;

use strict;
use warnings;

our $VERSION = '1.006'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use utf8;
no indirect;

=head1 NAME

OpenTracing::Protocol::Zipkin - support for Zipkin v2 JSON representation of OpenTracing data

=head1 DESCRIPTION

See L<https://zipkin.io/zipkin-api/#/default/post_spans> for details on
the current format.

=cut

use JSON::MaybeUTF8 qw(:v1);
use JSON::MaybeXS qw(JSON);

use Role::Tiny::With;

with qw(OpenTracing::Protocol);

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 bytes_from_span

Returns the given data structure as a bytestream containing
a JSON UTF-8 representation, as defined by Zipkin, Datadog and
other providers.

The resulting JSON will have at most the following keys:

=over 4

=item * C<id> - the span ID

=item * C<traceId> - the trace ID

=item * C<parentId> - this trace's parent ID

=item * C<localEndpoint> - where this span was running

=item * C<remoteEndpoint> - the remote connection that this span was involved with

=item * C<annotations> - any timestamp annotations relating to this span

=item * C<tags> - any key/value pairs relating to this span

=back

=cut

sub bytes_from_span {
    my ($self, $data) = @_;

    # We'd like to be quite careful about types here. This incurs some performance
    # overhead, but the JSON encoding still dominates.
    my %copy = (
        id      => '' . $data->{id},
        traceId => '' . $data->{trace_id},
    );
    $copy{debug}     = JSON()->true if $data->{debug};
    $copy{shared}    = JSON()->true if $data->{shared};
    $copy{name}      = '' . $data->{name} if defined $data->{name};
    $copy{parentId}  = '' . $data->{parent_id} if defined $data->{parent_id};
    $copy{kind}      = '' . $data->{kind} if defined $data->{kind};
    $copy{timestamp} = 0 + $data->{timestamp} if defined $data->{timestamp};
    $copy{duration}  = 0 + $data->{duration} if defined $data->{duration};

    if(my $endpoint = $data->{local_endpoint}) {
        $copy{localEndpoint}   = my $target                                                           = { };
        $target->{serviceName} = '' . $endpoint->{service_name} if defined $endpoint->{service_name};
        $target->{ipv4}        = '' . $endpoint->{ipv4} if defined $endpoint->{ipv4};
        $target->{ipv6}        = '' . $endpoint->{ipv6} if defined $endpoint->{ipv6};
        $target->{port}        = 0 + $endpoint->{port} if defined $endpoint->{port};
    }

    if(my $endpoint = $data->{remote_endpoint}) {
        $copy{remoteEndpoint}  = my $target                                                      = { };
        $target->{serviceName} = $endpoint->{service_name} if defined $endpoint->{service_name};
        $target->{ipv4}        = '' . $endpoint->{ipv4} if defined $endpoint->{ipv4};
        $target->{ipv6}        = '' . $endpoint->{ipv6} if defined $endpoint->{ipv6};
        $target->{port}        = 0 + $endpoint->{port} if defined $endpoint->{port};
    }

    for my $annotation (@{$data->{annotations}}) {
        push @{$copy{annotations} //= []}, {
            timestamp => 0 + $annotation->{timestamp},
            value     => '' . $annotation->{value},
        }
    }
    @{$copy{tags}}{keys %{$data->{tags}}} = map { "$_" } values %{$data->{tags}} if $data->{tags};

    return encode_json_utf8(
        \%copy
    );
}

=head2 span_from_bytes

Takes a bytestring containing UTF-8-encoded JSON data, and returns a
Perl hashref representing a span.

=cut

sub span_from_bytes {
    my ($self, $data) = @_;
    my $decoded = decode_json_utf8($data);
    for (grep /[A-Z]/, keys %$decoded) {
        $decoded->{ s{([A-Z])}{_\L$1}gr } = delete $decoded->{$_}
    }
    return $decoded;
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

1;
