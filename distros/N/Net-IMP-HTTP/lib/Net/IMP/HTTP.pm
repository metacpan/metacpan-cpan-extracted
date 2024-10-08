use strict;
use warnings;

package Net::IMP::HTTP;
use Net::IMP qw(:DEFAULT IMP_DATA );
use Exporter 'import';

our $VERSION = '0.524';
our @EXPORT;

# create and export NET_IMP_HTTP* constants
push @EXPORT, IMP_DATA( 'http',
    'header'     => +1,
    'body'       => -2, # message body: streaming
    'chkhdr'     => +3,
    'chktrailer' => +4,
    'data'       => -5, # encapsulated data (websocket etc): streaming
    'junk'       => -6, # junk data (leading empty lines..): streaming
);

push @EXPORT, IMP_DATA( 'httprq[http+10]',
    'header'     => +1,
    'content'    => -2, # unchunked, uncompressed content: streaming
    'data'       => -3, # encapsulated data (websocket etc): streaming
);


__END__

=head1 NAME

Net::IMP::HTTP - interface for HTTP specific L<Net::IMP> plugins

=head1 DESCRIPTION

The Net::IMP::HTTP modules make it easier to write HTTP specific IMP plugins.
We distinguish between HTTP connection specific plugins and HTTP request
specific plugins.
The differences are:

=over 4

=item *

The offset in the return values of the plugins relates for connection specific
plugins to the connection (which might contain multiple requests), while for
request specific plugins it starts anew for each request.

Similar IMP_MAXOFFSET means the end of connection for connection specific
plugins, while end of request for request specific plugins.

=item *

Connection specific plugins get info about framing, e.g. junk data and framing
of chunked encoding (chunked header and trailers). Request specific plugins
only get header and content.

=item *

Connection specific plugins see the raw bodies of the request, while request
specific plugins see the content, e.g. the body stripped from framing (chunked
encoding) and transfer encodings (this includes content-encodings for
compression, which are in reality used as transfer encodings).

Similar it is expected, that connection specific plugins fix framing or
content-length headers themself, when changing data. For request specific
plugins the caller of the plugin is expected to adjust these.

=back

The following modules are currently implemented or planned:

=over 4

=item Net::IMP::HTTP

This module provides the data type definitions for HTTP connection and request
types.

=item Net::IMP::HTTP::Connection

This module is a base class for IMP plugins working with HTTP connection types.

=item Net::IMP::HTTP::Request

This module is a base class for IMP plugins working with HTTP request types.

=item Net::IMP::Adaptor::STREAM2HTTPConn

Using this module can adapt HTTP connection specific plugins into a simple
stream interface (IMP_DATA_STREAM)

=item Net::IMP::Adaptor::STREAM2HTTPReq (planned)

Using this module can adapt HTTP request specific plugins into a simple
stream interface (IMP_DATA_STREAM).

=back

C<Net::IMP::HTTP> defines the following constants for HTTP specific data types

=over 4

=item connection specific types

  IMP_DATA_HTTP_HEADER     - request and response header
  IMP_DATA_HTTP_BODY       - request and response body chunks (stream)
  IMP_DATA_HTTP_CHKHDR     - chunk header in chunked transfer encoding
  IMP_DATA_HTTP_CHKTRAILER - chunk trailer in chunked transfer encoding
  IMP_DATA_HTTP_DATA       - arbitrary data after connection upgrades (stream)
  IMP_DATA_HTTP_JUNK       - junk data (leading new lines before header..)

=item request specific types

  IMP_DATA_HTTPRQ_HEADER  - request and response header
  IMP_DATA_HTTPRQ_CONTENT - request and response body chunks (stream)
  IMP_DATA_HTTPRQ_DATA    - arbitrary data after connection upgrades (stream)

=back

=head1 SEE ALSO

L<Net::IMP>

=head1 AUTHOR

Steffen Ullrich, <sullr@cpan.org>

=head1 COPYRIGHT

Copyright 2013 Steffen Ullrich

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
