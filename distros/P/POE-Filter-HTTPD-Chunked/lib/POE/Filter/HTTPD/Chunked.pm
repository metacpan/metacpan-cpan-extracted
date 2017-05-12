# POE::Filter::HTTPD::Chunked Copyright 2010 Mark Morgan <makk384@gmail.com>.
#   based on POE::Filter::HTTPD Copyright 1998 Artur Bergman <artur@vogon.se>.

package POE::Filter::HTTPD::Chunked;

use strict;
use warnings;

our $VERSION = 0.90;

use Carp qw(croak);
use HTTP::Status qw(
    status_message
    RC_BAD_REQUEST
    RC_OK
    RC_LENGTH_REQUIRED
);

use HTTP::Request ();
use HTTP::Response ();

use base qw( POE::Filter );

# set the following to get info on what the filter is doing.  This is
# *very* noisy.
use constant DEBUG  => $ENV{ POE_FILTER_HTTPD_DEBUG } || 0;

# indices into our self
use constant BUFFER                 => 0;
use constant IS_CHUNKED             => 1;
use constant CHUNK_BUFFER           => 2;
use constant FINISH                 => 3;
use constant REQUEST                => 4;
use constant STATE                  => 5;
use constant EVENT_ON_PARTIAL_CHUNK => 6;

# states for our mini-state machine
use constant STATE_REQUEST_LINE     => 'parsing request line';
use constant STATE_PARSING_HEADER   => 'parsing header';
use constant STATE_PARSING_BODY     => 'parsing body';
use constant STATE_PARSING_COMPLETE => 'parsing complete';
use constant STATE_PARSING_TRAILER  => 'parsing trailer';

# very lenient CRLF matcher, matches CRLF, LFCR, CR, LF
my $CRLF = qr/(?:\x0D\x0A?|\x0A\x0D?)/;

# for matching an HTTP header.  Currently ignores continuation header lines...
my $HEADER_REGEX = qr/^([^()<>@,;:\\"\/\[\]?={}\s]+):\s*(.*?)$CRLF/;

# for matching chunked transfer-encoding definition, within header value
my $CHUNKED_REGEX = qr/(?:,\s*|^)chunked\s*$/;

# mapping of supported request types, and whether they support body
use constant DENY_CONTENT_BODY      => 1;       # can't have
use constant ALLOW_CONTENT_BODY     => 2;
use constant REQUIRE_CONTENT_BODY   => 3;

use constant REQUEST_TYPES      => {
    OPTIONS         => ALLOW_CONTENT_BODY,
    GET             => DENY_CONTENT_BODY,
    HEAD            => DENY_CONTENT_BODY,
    POST            => ALLOW_CONTENT_BODY,
    PUT             => ALLOW_CONTENT_BODY,
    DELETE          => DENY_CONTENT_BODY,
    TRACE           => ALLOW_CONTENT_BODY,
};

my $HTTP_0_9 = "HTTP/0.9";      # not real, just give us something to compare with
my $HTTP_1_0 = "HTTP/1.0";
my $HTTP_1_1 = "HTTP/1.1";

#------------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;

    my $self = bless [], $class;
    $self->__reset_state( 1 );

    $self->[ EVENT_ON_PARTIAL_CHUNK ] = $args{ event_on_chunk } ? 1 : 0;

    return $self;
}

#------------------------------------------------------------------------------

sub get_one_start {
    my ($self, $stream) = @_;

    # TODO TESTS FOR THIS!

    $stream = [ $stream ] unless ( ref( $stream ) );
    $self->[BUFFER] .= join( '', @$stream );
}

sub get_one {
    my ($self) = @_;
    return ( $self->[FINISH] ) ? [] : $self->get( [] );
}

sub get {
    my ($self, $stream) = @_;

    # append current stream input into buffer
    $self->[ BUFFER ] .= join '', @$stream;

    DEBUG && warn "buffer = " . $self->[ BUFFER ];

    my $initial_chunk_size = do {
        use bytes;
        length $self->[ CHUNK_BUFFER ];
    };

    # a basic state machine, to parse the request.  Flows are basically:
    #    - no request -> request -> parsed_header -> parsed_body -> done (send and reset)
    # At any point, can error out of this, at which point we reset the state machine
    while ( 1 ) {
        my $to_return;

        if ( $self->[ STATE ] eq STATE_REQUEST_LINE ) {
            $to_return = $self->_parse_request_line;
        } elsif ( $self->[ STATE ] eq STATE_PARSING_HEADER ) {
            $to_return = $self->_parse_header;
        } elsif ( $self->[ STATE ] eq STATE_PARSING_BODY ) {
            $to_return = $self->_parse_body;
        } elsif ( $self->[ STATE ] eq STATE_PARSING_TRAILER ) {
            $to_return = $self->_parse_trailer;
        } elsif ( $self->[ STATE ] eq STATE_PARSING_COMPLETE ) {
            # request is done, clean up what we have now, and return it.
            $to_return = [ $self->[ REQUEST ] ];

            DEBUG && warn "completed request: " . $self->[ REQUEST ]->as_string;

            $self->__reset_state( 0 );

            $self->[ FINISH ] = 1;
        } else {
            die "Unexpected state '$self->[ STATE ]'!!!";
        }

        if ( $to_return and not scalar @{ $to_return } ) {
            if ( $self->[ EVENT_ON_PARTIAL_CHUNK ] ) {
                # if we are still in body parsing state, and have more chunk data
                # than when we first ran through this loop, then return a marker
                # response, to indicate that we've received partial chunk data.
                # This is intended to allow the wheel/component to reset any
                # timeouts or the like.
                use bytes;

                my $current_chunk_size = length $self->[ CHUNK_BUFFER ];

                if ( $current_chunk_size > $initial_chunk_size ) {
                    my $chunked = HTTP::Request::Chunked->new;

                    # set headers to indicate the offset and size of
                    # the chunk, and the content to the current chunk

                    my $chunk_size = $current_chunk_size - $initial_chunk_size;

                    $chunked->header( 'x-chunk-offset' => $initial_chunk_size );
                    $chunked->header( 'x-chunk-size' => $chunk_size );

                    $chunked->content( substr( $self->[ CHUNK_BUFFER ], $initial_chunk_size, $chunk_size ) );

                    DEBUG && warn "got partial chunk of size $chunk_size at offset $initial_chunk_size\n";

                    push @{ $to_return }, $chunked;
                }
            }
        }

        $to_return && return $to_return;
    }
}

#------------------------------------------------------------------------------

sub put {
  my ($self, $responses) = @_;
  my @raw;

  # HTTP::Response's as_string method returns the header lines
  # terminated by "\n", which does not do the right thing if we want
  # to send it to a client.  Here I've stolen HTTP::Response's
  # as_string's code and altered it to use network newlines so picky
  # browsers like lynx get what they expect.

  foreach (@$responses) {
    my $code           = $_->code;
    my $status_message = status_message($code) || "Unknown Error";
    my $message        = $_->message  || "";
    my $proto          = $_->protocol || 'HTTP/1.0';

    my $status_line = "$proto $code";
    $status_line   .= " ($status_message)"  if $status_message ne $message;
    $status_line   .= " $message" if length($message);

    # Use network newlines, and be sure not to mangle newlines in the
    # response's content.

    my @headers;
    push @headers, $status_line;
    push @headers, $_->headers_as_string("\x0D\x0A");

    push @raw, join("\x0D\x0A", @headers, "") . $_->content;
  }

  # Allow next request after we're done sending the response.
  $self->[FINISH] = 0;

  \@raw;
}

sub clone {
    # implement our own clone, as we want to reset the state completely,
    # and ensure that we honour the current 'event_on_chunk' option
    my ( $self ) = @_;

    my $class = ref $self;

    return $class->new( event_on_chunk => $self->[ EVENT_ON_PARTIAL_CHUNK ] );
}
#------------------------------------------------------------------------------

sub get_pending {
  my $self = shift;
  croak ref($self)." does not support the get_pending() method\n";
  return;
}

#------------------------------------------------------------------------------
# Functions specific to HTTPD;
#------------------------------------------------------------------------------

# Build a basic response, given a status, a content type, and some
# content.

sub _build_basic_response {
  my ($self, $content, $content_type, $status) = @_;

  # Need to check lengths in octets, not characters.
  use bytes;

  $content_type ||= 'text/html';
  $status       ||= RC_OK;

  my $response = HTTP::Response->new($status);

  my $length = do { use bytes; length $content };

  $response->push_header( 'Content-Type', $content_type );
  $response->push_header( 'Content-Length', $length );
  $response->content($content);

  return $response;
}

sub _default_values {
    return {
        STATE()             => STATE_REQUEST_LINE,
        IS_CHUNKED()        => 0,
        BUFFER()            => '',
        FINISH()            => 0,
        REQUEST()           => undef,
        CHUNK_BUFFER()      => '',
    };
}

sub __reset_state {
    my ( $self, $clean_buffer ) = @_;

    my @fields = ( STATE, FINISH, REQUEST, IS_CHUNKED );

    if ( $clean_buffer ) {
        push( @fields, BUFFER, CHUNK_BUFFER );
    }

    foreach my $field ( @fields ) {
        $self->[ $field ] = $self->_default_values->{ $field };
    }
}


sub _build_error {
  my($self, $status, $details) = @_;

  # when we want to return an error, this object is pretty much dead.
  # Clear out the state, including the buffers.

  $self->__reset_state( 1 );

  $status  ||= RC_BAD_REQUEST;
  $details ||= '';
  my $message = status_message($status) || "Unknown Error";

  return $self->_build_basic_response(
    ( "<html>" .
      "<head>" .
      "<title>Error $status: $message</title>" .
      "</head>" .
      "<body>" .
      "<h1>Error $status: $message</h1>" .
      "<p>$details</p>" .
      "</body>" .
      "</html>"
    ),
    "text/html",
    $status
  );
}

sub _parse_request_line {
    my ( $self ) = @_;

    DEBUG && warn "attempting to parse request line\n";

    # return no packets, if we haven't seen the end of line
    if ( not $self->[ BUFFER ] =~ /$CRLF/s ) {
        return [];
    }

    # get the request line, or return an error
    if ( $self->[ BUFFER ] =~ s/^\s*(\w+)[ \t]+(\S+)(?:[ \t]+(HTTP\/\d+\.\d+))?$CRLF// ) {
        my ( $method, $uri, $version ) = ( $1, $2, $3 );

        $version ||= $HTTP_0_9;

        DEBUG && warn "got request of method = $method, uri = $uri, version = $version\n";

        my $request = HTTP::Request->new;

        $request->method( $method );
        $request->uri( $uri );
        $request->protocol( $version );

        $self->[ REQUEST ] = $request;
        $self->[ STATE ] = STATE_PARSING_HEADER;
    } elsif ( $self->[ BUFFER ] =~ /^.*?$CRLF/s ) {
        DEBUG && warn "error in parsing request line\n";

        return [
            $self->_build_error(RC_BAD_REQUEST, "Request line parse failure."),
        ];
    } else {
        return [];
    }

    return;
}

sub _parse_header {
    my ( $self ) = @_;

    DEBUG && warn "attempting to parse headers\n";

    while ( $self->[ BUFFER ] =~ s/$HEADER_REGEX// ) {
        my ( $header, $value ) = ( $1, $2 );

        DEBUG && warn "got header line '$header' => '$value'\n";

        # pulled a header off the buffer
        $self->[ REQUEST ]->header( $header => $value );
    }

    # blank line to end the headers
    if ( $self->[ BUFFER ] =~ s/^$CRLF// ) {
        DEBUG && warn "end of headers\n";

        # set IS_CHUNKED, if a transfer-encoding headers exists, and has
        # 'chunked' as the last (or only) value.  Adjust the header value
        # in this case.
        if ( my $te_header = $self->[ REQUEST ]->header( 'transfer-encoding' ) ) {
            if ( $te_header =~ s/$CHUNKED_REGEX// ) {
                DEBUG && warn "request is chunked\n";

                $self->[ IS_CHUNKED ] = 1;

                # set or clear the header, as appropriate
                if ( $te_header =~ /\S/ ) {
                    $self->[ REQUEST ]->header( 'transfer-encoding' => $te_header );
                } else {
                    $self->[ REQUEST ]->remove_header( 'transfer-encoding' );
                }
                DEBUG && warn "new header = $te_header\n";
            }
        }
        
        $self->[ STATE ] = STATE_PARSING_BODY;

        # have enough information now, to determine whether we have met the
        # allowance/requirement for body, for the given request type

        my $request_type = $self->[ REQUEST ]->method;

        my $requirement = REQUEST_TYPES->{ uc $request_type };
        if ( defined $requirement ) {
            # rfc-defined method; check whether body allowed or required

            my $has_body = $self->[ REQUEST ]->header( 'content-length' ) ? 1 : 0;

            my $error;
            if ( $requirement == DENY_CONTENT_BODY and $has_body ) {
                DEBUG && warn "for request type $request_type, can't have a body\n";

                $error = $self->_build_error(
                    RC_BAD_REQUEST,
                    'request type does not allow a body'
                );
            } elsif ( $requirement == REQUIRE_CONTENT_BODY and not $has_body ) {
                DEBUG && warn "for request type $request_type, must have a body\n";

                $error = $self->_build_error(
                    RC_LENGTH_REQUIRED,
                    'request type requires body'
                );
            } else {
                # noop, ALLOW_CONTENT_BODY can have or not
            }

            if ( $error ) {
                return [ $error ];
            }
        } else {
            return [
                $self->_build_error( RC_BAD_REQUEST, "invalid request type '$request_type'" )
            ];
        }
    } else {
        # still haven't got full data, return empty array ref to
        # cause return
        return []
    }
}

sub _parse_body {
    my ( $self ) = @_;

    my $is_chunked = $self->[ IS_CHUNKED ];

    my $content_length = $self->[ REQUEST ]->content_length;

    if ( defined $content_length and $content_length and $is_chunked ) {
        # can't have both content_length and transfer_encoding of chunked set
        return [
            $self->_build_error(
                RC_BAD_REQUEST,
                'Both content-length and transfer-encoding cannot be set in headers'
            )
        ];
    } elsif ( $is_chunked and $self->[ REQUEST ]->protocol eq 'HTTP/1.0' ) {
        # chunked encoding isn't valid for HTTP/1.0
        return [
            $self->_build_error(
                RC_BAD_REQUEST,
                "Can't use chunked encoding with HTTP/1.0"
            )
        ];
    }

    DEBUG && warn "attempting to parse body, chunked = $is_chunked\n";

    if ( $content_length ) {
        DEBUG && warn "looking for $content_length bytes\n";

        # if we have enough bytes in the buffer, then pull them off and complete the request.
        use bytes;

        if ( length $self->[ BUFFER ] >= $content_length ) {
            my $content = substr( $self->[ BUFFER ], 0, $content_length, '' );

            DEBUG && warn "got content of '$content'\n";

            $self->[ REQUEST ]->content( $content );

            $self->[ STATE ] = STATE_PARSING_COMPLETE;
        } else {
            return [];
        }
    } elsif ( $is_chunked ) {
        DEBUG && warn "looking for chunk portion\n";

        # first line of each chunk will be the chunk size (in hex),
        # followed by that number of bytes of chunk data.  Keep
        # dechunking, till we get a chunk size of 0.
        use bytes;

        my $processed_data = 0;
        while ( $self->[ BUFFER ] =~ /^((.*?)$CRLF)/s ) {
            DEBUG && warn "found a complete line\n";

            $processed_data = 1;

            my ( $line, $chunk_hex ) = ( $1, $2 );

            if ( $chunk_hex =~ /^([0-9a-f]+)(;.*)?$/i ) {
                $chunk_hex = $1; # ignore semicolon, and everything after
            } else {
                # got an invalid chunk size, return an error
                return [
                    $self->_build_error(
                        RC_BAD_REQUEST,
                        "invalid chunk size '$chunk_hex'"
                    )
                ];
            }

            my ( $line_size, $chunk_size ) = ( length( $line ), hex( $chunk_hex ) );

            if ( $chunk_size == 0 ) {
                DEBUG && warn "got a chunk size of 0, done with chunking\n";

                if ( $self->[ BUFFER ] =~ s/(?:.{$line_size})//s ) {
                    # signify that trailers still need handling
                    $self->[ STATE ] = STATE_PARSING_TRAILER;
                    return;
                }
            } elsif ( $self->[ BUFFER ] =~ s/^(?:.{$line_size})(.{$chunk_size})$CRLF//s ) {
                my ( $chunk ) = ( $1 );
                DEBUG && warn "got a complete chunk of length $chunk_size\n";

                $self->[ CHUNK_BUFFER ] .= $chunk;
            } else {
                # not enough data for a whole chunk, end current run through
                return [];
            }
        }

        $processed_data || return [];
    } else {        # no content_length
        DEBUG && warn "finished body parsing\n";

        $self->[ STATE ] = STATE_PARSING_COMPLETE;
    }

    return;
}

sub _parse_trailer {
    my ( $self ) = @_;

    DEBUG && warn "looking for trailer\n";

    my $done = 0;

    # read up to a blank line, and pull off headers^Her, trailers.
    if ( $self->[ BUFFER ] =~ s/^$CRLF// ) {
        # no trailers, just mark that we're done
        $done = 1;
    } elsif ( $self->[ BUFFER ] =~ s/^(.*?($CRLF)\2)//s ) {
        my $trailer = $1;

        while ( $trailer =~ s/$HEADER_REGEX//s ) {
            my ( $header, $value ) = ( $1, $2 );

            DEBUG && warn "got trailer line '$header' => '$value'\n";

            # can't have trailers of 'content-length', 'transfer-encoding'
            # or 'trailers'
            if ( $header =~ /^(content-length|transfer-encoding|trailer)$/i ) {
                return [
                    $self->_build_error(
                        RC_BAD_REQUEST,
                        "Trailer of '$header' not allowed"
                    )
                ]
            }

            $self->[ REQUEST ]->header( $header => $value );
        }
        $done = 1;
    } else {
        return [];
    }

    if ( $done ) {
        # rewrite the headers and advance our state
        $self->[ STATE ] = STATE_PARSING_COMPLETE;

        # rewrite the headers, as appropriate
        my $request = $self->[ REQUEST ];

        $request->content( $self->[ CHUNK_BUFFER ] );
        $request->content_length( length $self->[ CHUNK_BUFFER ] );
        $request->remove_header( 'trailer' );
        $self->[ CHUNK_BUFFER ] = '';
    }

    return;
}

1;

package HTTP::Request::Chunked;

use base qw( HTTP::Request );

1;

__END__

=head1 NAME

POE::Filter::HTTPD::Chunked - Drop-in replacement for POE::Filter::HTTPD that also support HTTP1.1 chunked transfer-encoding.

=head1 SYNOPSIS

  #!perl

  use warnings;
  use strict;

  use POE qw(Component::Server::TCP Filter::HTTPD::Chunked);
  use HTTP::Response;

  POE::Component::Server::TCP->new(
    Port         => 8088,
    ClientFilter => 'POE::Filter::HTTPD::Chunked',

    ClientInput => sub {
      my $request = $_[ARG0];

      # It's a response for the client if there was a problem.
      if ($request->isa("HTTP::Response")) {
        $_[HEAP]{client}->put($request);
        $_[KERNEL]->yield("shutdown");
        return;
      }

      my $request_fields = '';
      $request->headers()->scan(
        sub {
          my ($header, $value) = @_;
          $request_fields .= (
            "<tr><td>$header</td><td>$value</td></tr>"
          );
        }
      );

      my $response = HTTP::Response->new(200);
      $response->push_header( 'Content-type', 'text/html' );
      $response->content(
        "<html><head><title>Your Request</title></head>" .
        "<body>Details about your request:" .
        "<table border='1'>$request_fields</table>" .
        "<tr><td>Body</td><td>" . $request->content . "</td>" .
        "</body></html>"
      );

      $_[HEAP]{client}->put($response);
      $_[KERNEL]->yield("shutdown");
    }
  );

  print "Aim your browser at port 8088 of this host.\n";
  POE::Kernel->run();
  exit;

For detail and an example of handling partial chunks, see
L<Handling of partial chunked data> below.

=head1 DESCRIPTION

POE::Filter::HTTPD::Chunked interprets input streams as HTTP requests.  It
returns a L<HTTP::Request> object upon successfully parsing a request.
On failure, it returns an L<HTTP::Response> object describing the failure.
The intention is that application code will notice the HTTP::Response and
send it back without further processing.  This is illustrated in
the SYNOPSIS.

For output, this module accepts L<HTTP::Response> objects and
returns their corresponding streams.

Please see L<HTTP::Request> and L<HTTP::Response> for details about
how to use these objects.

The following are the major differences between this module and the core POE
L<POE::Filter::HTTPD>:

=over 4

=item handling of incoming chunked data

POE::Filter::HTTPD has no support for handling 'chunked' requests
(part of HTTP1.1 spec), and would return an error (in the form of an
HTTP::Response object returned to the POE session).  For many applications,
this may not be a problem, as they can put an HTTP1.1 proxy in front of
the application, that will de-chunk the request, and return the normal HTTP/1.0
content-length.  This method, however, causes issues with applications that
either a/ want to handle partial content for a request as it comes in,
b/ don't want to have to artificially adjust request timeouts whilst waiting
for the proxy to get the full request or c/ don't want the additional
system complexity of having to use a proxy to dechunk.

=item support for any request type

L<POE::Filter::HTTPD> didn't handle all request types (ie,
DELETE).  This restriction has been removed in this module.

=back

=head1 PUBLIC FILTER METHODS

POE::Filter::HTTPD::Chunked implements the basic POE::Filter interface.

=head1 Handling of partial chunked data.

In order to allow for partial handling of data, if an optional constructor
argument of 'event_on_chunk' is passed in with a true value, and a
partial chunked request has been received since the last time the wheel
causes a 'get' call to be emitted, the partial chunked data is returned back.
This is wrapped in a class of HTTP::Request::Chunked, which is just a marker
sub-class of HTTP::Request, with the following detail set:

=over 4

=item content

Will be set to the partial content that has been received, since the last
HTTP::Request::Chunked packet was returned.

=item x-chunk-offset header

The offset (in bytes) as to where the current partial content starts.

=item x-chunk-offset-size header

The number of bytes in this partial chunk.

=back

Note that the final chunk will never be returned as an HTTP::Request::Chunked
object.  Instead, the full request will be returned as an HTTP::Request object
instead.

An example usage of how partial chunks is as-follows:

 my $filter = POE::Filter::HTTPD::Chunked->new( event_on_chunk => 1 );

 sub input_event {
     my ( $kernel, $heap, $request ) = @_[ KERNEL, HEAP, ARG0 ];

     if ( $request->isa( 'HTTP::Response' ) ) {
         # if we get an HTTP::Response object in, this was due to an error
         # in parsing the request.  Just return to client.

         $heap->{ wheel }->put( $request );
     } elsif ( $request->isa( 'HTTP::Request::Chunked' ) ) {
         # more data has come in for the given request.  Can just be used
         # to reset timeout, or to deal with the data within it.

         $kernel->alarm( 'reset_timer' => time() + 30 );

         printf(
            "got partial data of '%s' from byte offset %i, with size of %i",
            $request->content,
            $request->header( 'x-chunk-offset' ),
            $request->header( 'x-chunk-offset-size' ),
        );
     } else {
         # got a completed request.  This will be an HTTP::Request object,
         # populated with all data from the original request, converted to
         # non-chunked format.  If any body was included in the request, be
         # it chunked or not, a content-length header will be set, giving
         # the number of bytes in the body.

         printf(
            "got complete request of '%s', with size of '%i'",
            $request->content,
            $request->header( 'content-length' )
        );
     }
 }

=head1 BUGS

Many aspects of HTTP 1.0 and higher are not supported, such as
keep-alive.  A simple I/O filter can't support keep-alive, for
example.  A number of more feature-rich POE HTTP servers are on the
CPAN.  See
L<http://search.cpan.org/search?query=POE+http+server&mode=dist>

=head1 SEE ALSO

POE::Filter::HTTPD - Original basis for this class.  Note that much of
the original POE::Filter::HTTPD code is redone for this class, due to different
requirements.  Assume that any errors that occour in POE::Filter::HTTPD::Chunked
are mine, and not based on this module. 

POE::Filter - Superclass, for general Filter API.

The SEE ALSO section in POE contains a table of contents covering the
entire POE distribution.

HTTP::Request and HTTP::Response explain all the wonderful things you can
do with these classes.

=head1 AUTHORS AND LICENSE

Mark Morgan <makk384@gmail.com>

Tom Clark <tom@woot.co.uk>

This modules is bassed off of L<POE::Filter::HTTPD> module, contributed by
Arthur Bergman, with documentation provided by Rocco Caputo.

Thanks to trutap (www.trutap.com) for paying us whilst developing this code,
and allowing it to be released.

Copyright (c) 2008-2010 Mark Morgan. All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

