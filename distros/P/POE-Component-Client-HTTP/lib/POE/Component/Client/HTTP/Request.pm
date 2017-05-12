package POE::Component::Client::HTTP::Request;
# vim: ts=2 sw=2 expandtab
$POE::Component::Client::HTTP::Request::VERSION = '0.949';
use strict;
use warnings;

use POE;

use Carp;
use HTTP::Status;
use Errno qw(ETIMEDOUT);

BEGIN {
  local $SIG{'__DIE__'} = 'DEFAULT';
  # Allow more finely grained timeouts if Time::HiRes is available.
  # This code is also in POE::Component::Client::HTTP
  eval {
    require Time::HiRes;
    Time::HiRes->import("time");
  };
}

# Unique request ID, independent of wheel and timer IDs.
my $request_seq = 0;

use constant DEBUG => 0;

# TODO CONNECT - Add a flag to indicate whether to generate an HTTP
# CONNECT request for proxying, or to return REQ_HTTP_REQUEST.  Add a
# method to update that flag.

use constant {
  REQ_ID            =>  0,
  REQ_POSTBACK      =>  1,
  REQ_CONNECTION    =>  2,
  REQ_HTTP_REQUEST  =>  3,
  REQ_STATE         =>  4,
  REQ_RESPONSE      =>  5,
  REQ_BUFFER        =>  6,
  REQ_OCTETS_GOT    =>  8,
  REQ_TIMER         =>  9,
  REQ_PROG_POSTBACK => 10,
  REQ_USING_PROXY   => 11,
  REQ_HOST          => 12,
  REQ_PORT          => 13,
  REQ_HISTORY       => 14,
  REQ_START_TIME    => 15,
  REQ_FACTORY       => 16,
  REQ_CONN_ID       => 17,
  REQ_PEERNAME      => 18,
};

use constant {
  RS_CONNECT        => 0x01, # establishing a connection
  RS_SENDING        => 0x02, # sending request to server
  RS_IN_HEAD        => 0x04, # waiting for or receiving headers
  RS_REDIRECTED     => 0x08, # request has been redirected
  RS_IN_CONTENT     => 0x20, # waiting for or receiving content
  RS_DONE           => 0x40, # received full content
  RS_POSTED         => 0x80, # we have posted back a response
};


sub import {
  my ($class) = shift;

  my $package = caller();

  foreach my $tag (@_) {
    if ($tag eq ':fields') {
      foreach my $sub (
        qw(
          REQ_ID REQ_POSTBACK REQ_CONNECTION REQ_HTTP_REQUEST REQ_STATE
          REQ_RESPONSE REQ_BUFFER REQ_OCTETS_GOT REQ_TIMER
          REQ_PROG_POSTBACK REQ_USING_PROXY REQ_HOST REQ_PORT
          REQ_HISTORY REQ_START_TIME REQ_CONN_ID REQ_PEERNAME
        )
      ) {
        no strict 'refs';
        *{$package . "::$sub"} = \&$sub;
      }
    }

    if ($tag eq ':states') {
      foreach my $sub (
        qw(
          RS_CONNECT RS_SENDING RS_IN_HEAD RS_REDIRECTED
          RS_IN_CONTENT RS_DONE RS_POSTED
        )
      ) {
        no strict 'refs';
        *{$package . "::$sub"} = \&$sub;
      }
    }
  }
}


sub ID { return $_[0][REQ_ID] }


sub new {
  my $class = shift;

  croak __PACKAGE__ . "expects its arguments to be key/value pairs" if @_ & 1;
  my %params = @_;

  croak "need a Request parameter" unless (defined $params{'Request'});
  croak "Request must be a HTTP::Request object"
    unless (UNIVERSAL::isa ($params{'Request'}, "HTTP::Request"));

  croak "need a Factory parameter" unless (defined $params{'Factory'});

  my ($http_request, $postback, $progress, $factory) =
    @params{qw(Request Postback Progress Factory)};

  my $request_id = ++$request_seq;
  DEBUG and warn "REQ: creating a request ($request_id)";

  # Get the host and port from the request object.
  my ($host, $port, $scheme, $using_proxy);

  eval {
    $host   = $http_request->uri()->host();
    $port   = $http_request->uri()->port();
    $scheme = $http_request->uri()->scheme();
  };
  croak "Not a usable Request: $@" if ($@);

  # Add a host header if one isn't included.  Must do this before
  # we reset the $host for the proxy!
  unless (
    defined $http_request->header('Host') and
    length $http_request->header('Host')
  ) {
    my $error = _set_host_header($http_request);
    croak "Can't set Host header: $error" if $error;
  }

  if (defined $params{Proxy}) {
    # This request qualifies for proxying.  Replace the host and port
    # with the proxy's host and port.  This comes after the Host:
    # header is set, so it doesn't break the request object.
    ($host, $port) = @{$params{Proxy}->[rand @{$params{Proxy}}]};

    $using_proxy = 1;
  }
  else {
    $using_proxy = 0;
  }

  # Build the request.
  my $self = [
    $request_id,        # REQ_ID
    $postback,          # REQ_POSTBACK
    undef,              # REQ_CONNECTION
    $http_request,      # REQ_HTTP_REQUEST
    RS_CONNECT,         # REQ_STATE
    undef,              # REQ_RESPONSE
    '',                 # REQ_BUFFER
    undef,              # unused
    0,                  # REQ_OCTETS_GOT
    undef,              # REQ_TIMER
    $progress,          # REQ_PROG_POSTBACK
    $using_proxy,       # REQ_USING_PROXY
    $host,              # REQ_HOST
    $port,              # REQ_PORT
    undef,              # REQ_HISTORY
    time(),             # REQ_START_TIME
    $factory,           # REQ_FACTORY
    undef,              # REQ_CONN_ID
    undef,              # REQ_PEERNAME
  ];
  return bless $self, $class;
}


sub return_response {
  my ($self) = @_;

  DEBUG and warn "in return_response ", sprintf ("0x%02X", $self->[REQ_STATE]);
  return if ($self->[REQ_STATE] & RS_POSTED);
  my $response = $self->[REQ_RESPONSE];

  # If we have a cookie jar, have it frob our headers.  LWP rocks!
  $self->[REQ_FACTORY]->frob_cookies ($response);

  # If we're done, send back the HTTP::Response object, which
  # is filled with content if we aren't streaming, or empty
  # if we are. that there's no ARG1 lets the client know we're done
  # with the content in the latter case
  if ($self->[REQ_STATE] & RS_DONE) {
    DEBUG and warn "done; returning $response for ", $self->[REQ_ID];
    $self->[REQ_POSTBACK]->($self->[REQ_RESPONSE]);
    $self->[REQ_STATE] |= RS_POSTED;
    #warn "state is now ", $self->[REQ_STATE];
  }
  elsif ($self->[REQ_STATE] & RS_IN_CONTENT) {
    # If we are streaming, send the chunk back to the client session.
    # Otherwise add the new octets to the response's content.
    # This should only add up to content-length octets total!
    if ($self->[REQ_FACTORY]->is_streaming) {
      DEBUG and warn "returning partial $response";
      $self->[REQ_POSTBACK]->($self->[REQ_RESPONSE], $self->[REQ_BUFFER]);
    }
    else {
      DEBUG and warn "adding to $response";
      $self->[REQ_RESPONSE]->add_content($self->[REQ_BUFFER]);
    }
  }
  $self->[REQ_BUFFER] = '';
}


sub add_eof {
  my ($self) = @_;

  return if ($self->[REQ_STATE] & RS_POSTED);

  unless (defined $self->[REQ_RESPONSE]) {
    # XXX I don't know if this is actually used
    $self->error(400, "incomplete response a " . $self->[REQ_ID]);
    return;
  }

  # RFC 2616: "If a message is received with both a Transfer-Encoding
  # header field and a Content-Length header field, the latter MUST be
  # ignored."
  #
  # Google returns a Content-Length header with its HEAD request,
  # generating "incomplete response" errors.  Added a special case to
  # ignore content for HEAD requests.  This may thwart keep-alive,
  # however.

  if (
    $self->[REQ_HTTP_REQUEST]->method() ne "HEAD" and
    defined $self->[REQ_RESPONSE]->content_length and
    not defined $self->[REQ_RESPONSE]->header("Transfer-Encoding") and
    $self->[REQ_OCTETS_GOT] < $self->[REQ_RESPONSE]->content_length
  ) {
    DEBUG and warn(
      "got " . $self->[REQ_OCTETS_GOT] . " of " .
      $self->[REQ_RESPONSE]->content_length
    );

    $self->error(
      400,
      "incomplete response b " . $self->[REQ_ID] . ".  Wanted " .
      $self->[REQ_RESPONSE]->content_length() . " octets.  Got " .
      $self->[REQ_OCTETS_GOT] . "."
    );
  }
  else {
    $self->[REQ_STATE] |= RS_DONE;
    $self->return_response();
  }
}


sub add_content {
  my ($self, $data) = @_;

  if (ref $data) {
    $self->[REQ_STATE] = RS_DONE;
    $data->scan (sub {$self->[REQ_RESPONSE]->header (@_) });
    return 1;
  }

  $self->[REQ_BUFFER] .= $data;

  # Count how many octets we've received.  -><- This may fail on
  # perl 5.8 if the input has been identified as Unicode.  Then
  # again, the C<use bytes> in Driver::SysRW may have untainted the
  # data... or it may have just changed the semantics of length()
  # therein.  If it's done the former, then we're safe.  Otherwise
  # we also need to C<use bytes>.
  # TODO: write test(s) for this.

  my $this_chunk_length = length($self->[REQ_BUFFER]);
  $self->[REQ_OCTETS_GOT] += $this_chunk_length;

  my $max = $self->[REQ_FACTORY]->max_response_size();

  DEBUG and warn(
    "REQ: request ", $self->ID,
    " received $self->[REQ_OCTETS_GOT] bytes; maximum is $max"
  );

  # Fail if we've gone over the maximum content size to return.
  if (defined $max and $self->[REQ_OCTETS_GOT] > $max) {
    $self->error(
      406,
      "Response content is longer than specified MaxSize of $max.  " .
      "Use range requests to retrieve specific amounts of content."
    );

    $self->[REQ_STATE] |= RS_DONE;
    $self->[REQ_STATE] &= ~RS_IN_CONTENT;
    return 1;
  }

  # keep this for the progress callback (it gets cleared in return_response
  # as I say below, this needs to go away.
  my $buffer = $self->[REQ_BUFFER];

  $self->return_response;
  DEBUG and do {
    warn(
      "REQ: request ", $self->ID,
      " got $this_chunk_length octets of content..."
    );

    warn(
      "REQ: request ", $self->ID, " has $self->[REQ_OCTETS_GOT]",
      (
        $self->[REQ_RESPONSE]->content_length()
        ? ( " out of " . $self->[REQ_RESPONSE]->content_length() )
        : ""
      ),
      " octets"
    );
  };

  if ($self->[REQ_RESPONSE]->content_length) {

    # Report back progress
    $self->[REQ_PROG_POSTBACK]->(
      $self->[REQ_OCTETS_GOT],
      $self->[REQ_RESPONSE]->content_length,
      #TODO: ugh. this is stupid. Must remove/deprecate!
      $buffer,
    ) if ($self->[REQ_PROG_POSTBACK]);

    # Stop reading when we have enough content.  -><- Should never be
    # greater than our content length.
    if ($self->[REQ_OCTETS_GOT] >= $self->[REQ_RESPONSE]->content_length) {
      DEBUG and warn(
        "REQ: request ", $self->ID, " has a full response... moving to done."
      );
      $self->[REQ_STATE] |= RS_DONE;
      $self->[REQ_STATE] &= ~RS_IN_CONTENT;
      return 1;
    }
  }

  return 0;
}


### Methods to manage the request's timer.


sub timer {
  my ($self, $timer) = @_;

  # do it this way so we can set REQ_TIMER to undef
  if (@_ == 2) {
    die "overwriting timer $self->[REQ_TIMER]" if $self->[REQ_TIMER];
    $self->[REQ_TIMER] = $timer;
  }
  return $self->[REQ_TIMER];
}


sub create_timer {
  my ($self, $timeout) = @_;

  # remove old timeout first
  my $kernel = $POE::Kernel::poe_kernel;

  my $seconds = $timeout - (time() - $self->[REQ_START_TIME]);
  $self->[REQ_TIMER] = $kernel->delay_set(
    got_timeout => $seconds, $self->ID
  );
  DEBUG and warn(
    "TKO: request ", $self->ID,
    " has timer $self->[REQ_TIMER] going off in $seconds seconds\n"
  );
}


sub remove_timeout {
  my ($self) = @_;

  my $alarm_id = $self->[REQ_TIMER];
  if (defined $alarm_id) {
    my $kernel = $POE::Kernel::poe_kernel;
    DEBUG and warn "REQ: Removing timer $alarm_id";
    $kernel->alarm_remove($alarm_id);
    $self->[REQ_TIMER] = undef;
  }
}


sub postback {
  my ($self, $postback) = @_;

  if (defined $postback) {
    DEBUG and warn "REQ: modifying postback";
    $self->[REQ_POSTBACK] = $postback;
  }
  return $self->[REQ_POSTBACK];
}


sub _set_host_header {
  my ($request) = @_;
  my $uri = $request->uri;

  my ($new_host, $new_port);
  eval {
    $new_host = $uri->host();
    $new_port = $uri->port();
    # Only include the port if it's nonstandard.
    if ($new_port == 80 || $new_port == 443) {
      $request->header( Host => $new_host );
    }
    else {
      $request->header( Host => "$new_host:$new_port" );
    }
  };

  # Return Boolean state of the eval.
  return $@;
}


sub does_redirect {
  my ($self, $last) = @_;

  if (defined $last) {
    $self->[REQ_HISTORY] = $last;
    # delete OLD timeout
    #my $alarm_id = $last->[REQ_TIMEOUT];
    #DEBUG and warn "RED: Removing old timeout $alarm_id\n";
    #$POE::Kernel::poe_kernel->alarm_remove ($alarm_id);
  }

  return defined $self->[REQ_HISTORY];
}


sub check_redirect {
  my ($self) = @_;

  my $max = $self->[REQ_FACTORY]->max_redirect_count;

  if (defined $self->[REQ_HISTORY]) {
    $self->[REQ_RESPONSE]->previous($self->[REQ_HISTORY]->[REQ_RESPONSE]);
  }

  return undef unless ($self->[REQ_RESPONSE]->is_redirect);

  # Make sure to frob any cookies set.  Redirect cookies are cookies, too!
  $self->[REQ_FACTORY]->frob_cookies($self->[REQ_RESPONSE]);

  my $location_uri = $self->[REQ_RESPONSE]->header('Location');

  DEBUG and warn "REQ: Preparing redirect to $location_uri";
  my $base = $self->[REQ_RESPONSE]->base();
  $location_uri = URI->new($location_uri, $base)->abs($base);
  DEBUG and warn "RED: Actual redirect uri is $location_uri";

  my $prev = $self;
  my $history = 0;
  while ($prev = $prev->[REQ_HISTORY]) {
    last if ++$history > $max;
  }

  if ($history >= $max) {
    #$self->[REQ_STATE] |= RS_DONE;
    DEBUG and warn "RED: Too much redirection";
  }
  else { # All fine, yield new request and mark this disabled.
    my $newrequest = $self->[REQ_HTTP_REQUEST]->clone();

    # Sanitize new request per rt #30400.
    # TODO - What other headers are security risks?
    $newrequest->remove_header('Cookie');

    DEBUG and warn "RED: new request $newrequest";
    $newrequest->uri($location_uri);

    # Don't change the Host header on a relative redirect.  This
    # allows the HTTP::Request's Host to remain intact, per
    # rt.cpan.org #63990.
    if (defined $location_uri->scheme()) {
      DEBUG and warn "RED: redirecting to absolute location $location_uri";
      _set_host_header($newrequest);
    }
    else {
      DEBUG and warn "RED: no new Host for relative redirect to $location_uri";
    }

    $self->[REQ_STATE] = RS_REDIRECTED;
    DEBUG and warn "RED: new request $newrequest";
    return $newrequest;
  }
  return undef;
}


sub send_to_wheel {
  my ($self) = @_;

  $self->[REQ_STATE] = RS_SENDING;

  my $http_request = $self->[REQ_HTTP_REQUEST];

  # MEXNIX 2002-06-01: Check for proxy.  Request query is a bit
  # different...

  my $request_uri;
  if ($self->[REQ_USING_PROXY]) {
    $request_uri = $http_request->uri()->canonical();
  }
  else {
    $request_uri = $http_request->uri()->canonical()->path_query();
  }

  my $request_string = (
    $http_request->method() . ' ' .
    $request_uri . ' ' .
    $http_request->protocol() . "\x0D\x0A" .
    $http_request->headers_as_string("\x0D\x0A") . "\x0D\x0A"
  );
 
  if ( !ref $http_request->content() ) {
    $request_string .= $http_request->content(); # . "\x0D\x0A"
  }

  DEBUG and do {
    my $formatted_request_string = $request_string;
    $formatted_request_string =~ s/([^\n])$/$1\n/;
    $formatted_request_string =~ s/^/| /mg;
    warn ",----- SENDING REQUEST ", '-' x 56, "\n";
    warn $formatted_request_string;
    warn "`", '-' x 78, "\n";
  };

  $self->[REQ_CONNECTION]->wheel->put ($request_string);
}


sub wheel {
  my ($self) = @_;

  # FIXME - We don't support older versions of POE.  Remove this chunk
  # of code when we're not fixing something else.
  #
  #if (defined $new_wheel) {
  #   Switch wheels.  This is cumbersome, but it works around a bug in
  #   older versions of POE.
  #  $self->[REQ_WHEEL] = undef;
  #  $self->[REQ_WHEEL] = $new_wheel;
  #}

  return unless $self->[REQ_CONNECTION];
  return $self->[REQ_CONNECTION]->wheel;
}


sub error {
  my ($self, $code, $message) = @_;

  my $nl = "\n";

  my $http_msg = status_message($code);
  my $r = HTTP::Response->new($code, $http_msg, [ 'X-PCCH-Errmsg', $message ]);
  my $m = (
    "<html>$nl"
    . "<HEAD><TITLE>Error: $http_msg</TITLE></HEAD>$nl"
    . "<BODY>$nl"
    . "<H1>Error: $http_msg</H1>$nl"
    . "$message$nl"
    . "<small>This is a client error, not a server error.</small>$nl"
    . "</BODY>$nl"
    . "</HTML>$nl"
  );

  $r->content($m);
  $r->request($self->[REQ_HTTP_REQUEST]);
  $self->[REQ_POSTBACK]->($r);
  $self->[REQ_STATE] |= RS_POSTED;
}


sub connect_error {
  my ($self, $operation, $errnum, $errstr) = @_;

  my $host = $self->[REQ_HOST];
  my $port = $self->[REQ_PORT];

  if ($operation eq "connect" and $errnum == ETIMEDOUT) {
    $self->error(408, "Connection to $host:$port failed: timeout");
  }
  else {
    $self->error(
      RC_INTERNAL_SERVER_ERROR,
      "Connection to $host:$port failed: $operation error $errnum: $errstr"
    );
  }

  return;
}


sub host { $_[0][REQ_HOST] }


sub port { $_[0][REQ_PORT] }


sub close_connection {
  my ($self) = @_;
  return unless defined $self->[REQ_CONNECTION];
  $self->[REQ_CONNECTION]->close();
  $self->[REQ_CONNECTION] = undef;
}


sub scheme {
  my $self = shift;

  $self->[REQ_USING_PROXY] ? 'http' : $self->[REQ_HTTP_REQUEST]->uri->scheme;
}


sub DESTROY {
  my ($self) = @_;

  delete $self->[REQ_CONNECTION];
  delete $self->[REQ_FACTORY];
}

1;

__END__

=head1 NAME

POE::Component::Client::HTTP::Request - an HTTP request class

=head1 VERSION

version 0.949

=head1 SYNOPSIS

  # Used internally by POE::Component::Client::HTTP

=head1 DESCRIPTION

POE::Component::Client::HTTP::Request encapsulates the state of
requests POE::Component::Client::HTTP requests throughout their life
cycles.  There turns out to be a lot of state to manage.

=head1 CONSTRUCTOR

=head2 new NAMED_PARAMETERS

Create a POE::Component::Client::HTTP object to manage a request.  The
constructor takes several named parameters:

=over 2

=item Request => HTTP_REQUEST

A POE::Component::Client::HTTP::Request object encapsulates a plain
HTTP::Request.  Required.

=item Factory => POE_COMPONENT_CLIENT_HTTP_REQUESTFACTORY

The request may create additional requests during its lifetime, for
example when following redirects.  The Factory parameter specifies the
POE::Component::Client::HTTP::RequestFactory that may be used to
create them.  Required.

=item Postback => RESPONSE_POSTBACK

POE::Component::Client::HTTP creates a postback that will be used to
send responses to the requesting session.  Required.

=item Progress => PROGRESS_POSTBACK

Sets the progress notification if the user has requested progress
events.  Optional.

=item Proxy

Sets the proxy used for this request, if requested by the user.
Optional.

=back

=head1 METHODS

=head2 ID

Return the request's unique ID.

=head2 return_response

Sends a response back to the user's session.  Called by
POE::Component::Client::HTTP when a complete response has arrived.

=head2 add_eof

Called by POE::Component::Client::HTTP to indicate EOF has arrived.

=head2 add_content PARSED_DATA

Called by POE::Component::Client::HTTP to add content data to an
incrementally built response.  If PARSED_DATA is an object, it is
treated like an HTTP::Headers object and its headers are assimilated
into the response being built by the request.  Otherwise the
PARSED_DATA is appended to the response's content.

=head2 timer TIMER

Accessor to manipulate the request's timeout timer.  Sets the
request's timer if TIMER is specified, otherwise merely fetches the
one currently associated with the request.

=head2 create_timer TIMEOUT

Creates and sets a timer for this request.  TIMEOUT is the number of
seconds this request may live.

=head2 remove_timeout

Turn off the timer associated with this request, and discard it.

=head2 postback POSTBACK

Accessor to manipulate the postback associated with this request.
Sets the postback if POSTBACK is defined, otherwise merely fetches it.

=head2 does_redirect SOMETHING

FIXME - Not sure what this accessor does.

=head2 check_redirect

Check whether the last response is a redirect, the request is
permitted to follow redirects, and the maximum number of redirects has
not been met.  Initiate a redirect if all conditions are favorable.

=head2 close_connection

Each active request object contains an internal connection.  This
method closes it.

=head2 send_to_wheel

Transmit the request to the socket associated with this request.

=head2 wheel

An accessor to return the wheel associated with this request.

=head2 error ERROR_CODE, ERROR_MESSAGE

Generate an error response, and post it back to the user's session.

=head2 connect_error CONNECT_FAILURE_MESSAGE

Generate a connection error response, and post it back to the user's
session.

=head2 host

Return the host this request is attempting to work with.

=head2 port

Return the port this request is attempting to work with.

=head2 scheme

Return the scheme for this request.

=head1 SEE ALSO

L<POE::Component::Client::HTTP>
L<POE>

=head1 BUGS

None are currently known.

=head1 AUTHOR & COPYRIGHTS

POE::Component::Client::HTTP::Request is

=over 2

=item

Copyright 2004-2005 Martijn van Beers

=item

Copyright 2006 Rocco Caputo

=back

All rights are reserved.  POE::Component::Client::HTTP::Request is
free software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=head1 CONTRIBUTORS

Your name could be here.

=head1 CONTACT

Rocco may be contacted by e-mail via L<mailto:rcaputo@cpan.org>, and
Martijn may be contacted by email via L<mailto:martijn@cpan.org>.

The preferred way to report bugs or requests is through RT though.
See L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-HTTP>
or mail L<mailto:bug-POE-Component-Client-HTTP@rt.cpan.org>

For questions, try the L<POE> mailing list (poe@perl.org)

=cut
