# NAME

Net::ICAP::Client - A client implementation of the ICAP (RFC 3507) protocol

# VERSION

Version 0.08

# SYNOPSIS

    use Net::ICAP::Client;

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $request = HTTP::Request->new( 'POST' => 'https://www.example.com/path' );
    my ( $headers, $body ) = $icap->request( $request );
    if ($headers->isa('HTTP::Request') {
        # forward request to intended destination
    } elsif ($headers->isa('HTTP::Response') {
        # return response to original requestor
    }

# DESCRIPTION

This module provides a client interface to an [ICAP (RFC 3507) Server](http://tools.ietf.org/html/rfc3507).  ICAP Servers are designed to inspect and modify HTTP Request and Responses before the Request is passed to backend systems or the Response goes back to the user.

# SUBROUTINES/METHODS

## new

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $icap = Net::ICAP::Client->new('icaps://icap-proxy.example.com/', SSL_ca_path => '/path/to/ca-bundle.crt', %other_IO_SSL_Socket_options);

By default, the SSL\_verifycn\_scheme, SSL\_verifycn\_name and SSL\_verify\_mode parameters are automatically set for icaps URIs, but these parameters may be overridden.

## debug

$icap->debug() accepts an optional debug value and returns the current debug value

## allow\_204

$icap->allow\_204() accepts an optional value to set whether the client will send an [Allow: 204](https://tools.ietf.org/html/rfc3507#section-4.6) and returns the current setting

## allow\_preview

$icap->allow\_preview() accepts an optional value to set whether the client will send an [Preview](https://tools.ietf.org/html/rfc3507#section-4.5) and returns the current setting

## agent

$icap->agent() accepts an optional User Agent string and returns the current User Agent string

## server\_allows\_204

$icap->server\_allows\_204() returns true if the remote ICAP server can return a 204 (No modification needed) response.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## is\_tag

$icap->is\_tag() returns the value of the remote ICAP server's [ISTag](https://tools.ietf.org/html/rfc3507#section-4.7) header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## service

$icap->service() returns the value of the remote ICAP server's [Service](https://tools.ietf.org/html/rfc3507#section-4.10.2) header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## ttl

$icap->ttl() returns the value of the remote ICAP server's [Options-TTL](https://tools.ietf.org/html/rfc3507#section-4.10.2) header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## max\_connections

$icap->max\_connections() returns the value of the remote ICAP server's [Max-Connections](https://tools.ietf.org/html/rfc3507#section-4.10.2) header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## preview\_size

$icap->preview\_size() returns the value of the remote ICAP server's [Preview](https://tools.ietf.org/html/rfc3507#section-4.10.2) header.  This method will issue an OPTIONS call to the remote server unless another OPTIONS call has been sent in the last [ttl](#ttl) seconds.

## uri

$icap->uri() returns the current URI of the remote ICAP server as a [URI](https://metacpan.org/pod/URI) object.

## request

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $request_headers = HTTP::Headers->new();
    my $request = HTTP::Request->new( 'POST' => "https://www.example.com/path?name=value", $request_headers, "name2=value2" );
    my ( $request_or_response_headers, $filehandle_containing_possibly_updated_body ) = $icap->request( $request, $filehandle_containing_request_body );

$icap->request() expects an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object and an optional filehandle.  It will return an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) or an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object containing the request or response without the body and a filehandle containing the body.

## response

    my $icap = Net::ICAP::Client->new('icap://icap-proxy.example.com/');
    my $response = HTTP::Response->new( '200', 'OK' );
    my ( $response_headers, $filehandle_containing_possibly_updated_body ) = $icap->response( $optional_request_or_undef, $response, $filehandle_containing_response_body );

$icap->response() expects an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object (if available), an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object and an optional filehandle.  It will return an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object containing the response without the response body and a filehandle containing the response body.

# AUTHOR

David Dick, `<ddick at cpan.org>`

# DIAGNOSTICS

- `Failed to write to icap server at %s`

    Failed to write to the remote icap server.  Check network status.

- `Failed to write to STDERR`

    Failed to write to STDERR.  Check local machine settings.

- `Incorrectly formatted debug line`

    A debug call was made without being prefixed with a '>> ' or '<< '.  This is a bug in Net::ICAP::Client

- `Failed to connect to %s on port %s`

    The connection to the remote icap server failed.  Check network/SSL/TLS settings and status

- `Failed to read from %s`

    Failed to read from the remote icap server.  Check network status

- `Failed to seek to start of temporary file`

    Failed to do a disk operation.  Check disk settings for the mount point belonging to where temp files are being created

- `Failed to seek to start of content handle`

    Failed to do a disk operation.  Check disk settings for the mount point belonging to the file that are passed into the request/response method

- `ICAP Server returned a %s error`

    The remote ICAP server returned an error.  The TCP connection to the remote ICAP server will be automatically disconnected.  Capture the network traffic and enter a bug report

- `Failed to parse chunking length`

    This is a bug in Net::ICAP::Client

- `Unable to parse Encapsulated header`

    The remote ICAP server did not return an Encapsulated header that could be understood by Net::ICAP::Client.  Capture the network traffic and enter a bug report

- `Unable to parse ICAP header`

    The remote ICAP server did not return an ICAP header that could be understood by Net::ICAP::Client.  Capture the network traffic and enter a bug report

- `Failed to read from content handle`

    Failed to do a disk operation.  Check disk settings for the mount point belonging to the file that are passed into the request/response method

# CONFIGURATION AND ENVIRONMENT

Net::ICAP::Client requires no configuration files or environment variables.

# DEPENDENCIES

Net::ICAP::Client requires the following non-core modules

    HTTP::Request
    HTTP::Response
    IO::Socket::INET
    IO::Socket::SSL
    URI

# INCOMPATIBILITIES

None reported

# BUGS AND LIMITATIONS

To report a bug, or view the current list of bugs, please visit [https://github.com/david-dick/net-icap-client/issues](https://github.com/david-dick/net-icap-client/issues)

# LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
