package OpenTracing::Protocol;

use strict;
use warnings;

our $VERSION = '1.004'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Protocol

=head1 DESCRIPTION

Currently the following protocols are known:

=over 4

=item * L<OpenTracing::Protocol::Jaeger> - provides binary Thrift encoding for the Jæger opentracing tool

=item * L<OpenTracing::Protocol::Zipkin> - JSON representation as supported by Zipkin

=back

This module provides a rôle for the encoding/decoding
functionality. Implementations are not expected to
handle any data transfer - the encoded bytes would
be sent/received by the transport layer instead.

=cut

use Role::Tiny;

requires qw(
    bytes_from_span
    span_from_bytes
);

1;

