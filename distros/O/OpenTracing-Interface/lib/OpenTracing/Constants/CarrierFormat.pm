package OpenTracing::Constants::CarrierFormat;
use strict;
use warnings;
use parent 'Exporter';
use Package::Constants;

our $VERSION = 'v0.204.0';

use constant {
    OPENTRACING_CARRIER_FORMAT_HTTP_HEADERS => 'HTTP_HEADERS',
    OPENTRACING_CARRIER_FORMAT_BINARY       => 'BINARY',
    OPENTRACING_CARRIER_FORMAT_TEXT         => 'TEXT_MAP',
};

our @EXPORT_OK   = Package::Constants->list(__PACKAGE__);
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

1;

__END__

=pod

=head1 NAME

OpenTracing::Constants::CarrierFormat - constants for carrier formats

=head1 SYNOPSIS

    use OpenTracing::Constants::CarrierFormat ':ALL';

or just the ones you need:

    use OpenTracing::Constants::CarrierFormat
        qw/OPENTRACING_CARRIER_FORMAT_HTTP_HEADERS/;

=head1 CONSTANTS

This package doesn't export anything by default, you can use the C<:ALL>
tag to get all provided constants or ask for specific ones.
The following constants are provided:

=head2 OPENTRACING_CARRIER_FORMAT_TEXT

This format represents a SpanContext as hash with string values,
with no restrictions for keys and value contents
(unlike OPENTRACING_CARRIER_FORMAT_HTTP_HEADERS).

=head2 OPENTRACING_CARRIER_FORMAT_HTTP_HEADERS

This format represents a SpanContext as key-value pairs,
similarly to L<OPENTRACING_CARRIER_FORMAT_TEXT>.
However, both keys and values must be suitable for use as
HTTP headers (without modification or further escaping).

=head2 OPENTRACING_CARRIER_FORMAT_BINARY

This format represents a SpanContext as an opaque binary structure.

=cut
