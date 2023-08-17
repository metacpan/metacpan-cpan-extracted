package POE::Component::Curl::Multi;
$POE::Component::Curl::Multi::VERSION = '1.00';
#ABSTRACT: a fast HTTP POE component

use strict;
use warnings;
use HTTP::Response;
use HTTP::Status;
use Net::Curl qw[:constants];
use Net::Curl::Easy qw[:constants];
use Net::Curl::Multi qw[:constants];
use Scalar::Util qw[refaddr];
use POE;

our %methods = (
  GET  => CURLOPT_HTTPGET,
  POST => CURLOPT_POST,
  HEAD => CURLOPT_NOBODY,
);

sub spawn {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  delete $self->{ipresolve} unless $self->{ipresolve} && $self->{ipresolve} =~ m!^[46]$!;
  delete $self->{verifypeer} unless defined $self->{verifypeer} && $self->{verifypeer} =~ m!^[01]$!;
  delete $self->{verifyhost} unless defined $self->{verifyhost} && $self->{verifyhost} =~ m!^[02]$!;
  $self->{max_concurrency} = 0 unless $self->{max_concurrency} &&
    $self->{max_concurrency} =~ m!^\d+$!;
  $self->{followredirects} = 0 unless
    $self->{followredirects} && $self->{followredirects} =~ m!^(-1|[0-9]+)$!;
  $self->{timeout} = 180 unless $self->{timeout} && $self->{timeout} =~ m!^\d+$!;
  $self->{agent} = [ $self->{agent} ] unless ref $self->{agent};
  delete $self->{agent} unless ref $self->{agent} eq 'ARRAY';
  $self->{multi} = Net::Curl::Multi->new();
  $self->{multi}->setopt( CURLMOPT_SOCKETFUNCTION, sub { return 1 });
  $self->{session_id} = POE::Session->create(
        object_states => [
           $self => { shutdown => '_shutdown', request => '_request', cancel => '_cancel', pending_requests_count => '_req_count' },
           $self => [qw(_start _stop _dequeue _perform _result _progress)],
        ],
        heap => $self,
        ( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'shutdown' );
}

sub cancel {
  my $self = shift;
  $poe_kernel->post( $self->{session_id}, 'cancel', @_ );
}

sub pending_requests_count {
  my $self = shift;
  return +( scalar @{ $self->{queue} } + scalar keys %{ $self->{state} } );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
     $kernel->alias_set( $self->{alias} );
  }
  else {
     $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{state} = { };
  $self->{queue} = [ ];
  return;
}

sub _stop {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{state};
  delete $self->{queue};
  delete $self->{multi};
  return;
}

sub _req_count {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  return $self->pending_requests_count();
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{_shutdown} = 1;
  $kernel->alarm_remove_all();
  $self->cancel( $_ ) for
    map { $_->{request} }
      ( values %{ $self->{state} }, @{ $self->{queue} } );
  $kernel->alias_remove( $_ ) for $kernel->alias_list();
  $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) unless $self->{alias};
  return;
}

sub _cancel {
  my ($kernel,$self,$req) = @_[KERNEL,OBJECT,ARG0];
  unless ( $req or $req->isa('HTTP::Request') ) {
    warn "No HTTP::Request given\n";
    return;
  }
  my $id = delete $self->{req_to_id}->{ $req };
  unless ( $id ) {
    warn "That request doesn\'t exist\n";
    return;
  }
  if ( my ($datum) = grep { $_->{id} == $id } @{ $self->{queue} } ) {
    @{ $self->{queue} } = grep { $_->{id} != $id } @{ $self->{queue} };
    my $resp = _error( 408, 'Request timed out (request canceled)' );
    $kernel->yield( '_result', $datum, $resp, { } );
    return;
  }
  if ( my $state = delete $self->{state}->{ $id } ) {
    $self->{multi}->remove_handle( $state->{easy} );
    my $resp = _error( 408, 'Request timed out (request canceled)' );
    $kernel->yield( '_result', $state, $resp, { } );
  }
  return;
}

sub _request {
  my ($kernel,$self,$me,$state,$sender) = @_[KERNEL,OBJECT,SESSION,STATE,SENDER];
  my $sender_id = $sender->ID();
  my $args;
  my $errsp;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
    $args = { %{ $_[ARG0] } };
  }
  elsif ( ref( $_[ARG0] ) eq 'ARRAY' ) {
    $args = { @{ $_[ARG0] } };
  }
  else {
    @{$args}{qw(response request tag progress proxy)} = @_[ARG0..$#_];
  }
  $args->{lc $_} = delete $args->{$_} for grep { !/^_/ } keys %{ $args };
  unless ( $args->{response} ) {
    warn "No 'response' specified for $state\n";
    return;
  }
  unless ( ref( $args->{request} ) eq 'HTTP::Request' ) {
    $errsp = HTTP::Response->new(
       400 => 'Bad Request', [],
       "<html>\n"
       . "<HEAD><TITLE>Error: Bad Request</TITLE></HEAD>\n"
       . "<BODY>\n"
       . "<H1>Error: Bad Request</H1>\n"
       . "Unsupported URI scheme\n"
       . "</BODY>\n"
       . "</HTML>\n"
    );
  }
  if ( $self->{_shutdown} ) {
    $errsp = HTTP::Response->new(
       408 => 'Request timed out (component shut down)', [],
       "<html>\n"
       . "<HEAD><TITLE>Error: Request timed out (component shut down)"
       . "</TITLE></HEAD>\n"
       . "<BODY>\n"
       . "<H1>Error: Request Timeout</H1>\n"
       . "Request timed out (component shut down)\n"
       . "</BODY>\n"
       . "</HTML>\n"
      );
  }
  if ( $args->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
        $sender_id = $ref->ID();
    }
    else {
        warn "Could not resolve 'session' to a valid POE session, will return to SENDER\n";
    }
  }
  delete $args->{ipresolve}
    unless $args->{ipresolve} && $args->{ipresolve} =~ m!^[46]$!;
  delete $args->{verifypeer}
    unless defined $args->{verifypeer} && $args->{verifypeer} =~ m!^[01]$!;
  delete $args->{verifyhost}
    unless defined $args->{verifyhost} && $args->{verifyhost} =~ m!^[02]$!;
  $args->{sender} = $sender_id;
  if ( $errsp ) {
    $errsp->request( $args->{request} ) unless $errsp->code() eq '400';
    my $reqpack = [ $args->{request}, $args->{tag} ];
    my $respack = [ $errsp, { } ];
    if ( ref $args->{response} eq 'POE::Session::AnonEvent' ) {
      $args->{response}->( $reqpack, $respack );
      return;
    }
    $kernel->post( $args->{sender}, $args->{response}, $reqpack, $respack );
    return;
  }
  # deal with shutdown requests 408 => 'Request timed out (component shut down)',
  # maybe deal with all error conditions the same way
  $kernel->refcount_increment( $sender_id, __PACKAGE__ )
        unless ref $args->{response} eq 'POE::Session::AnonEvent';
  {
    my $easy = Net::Curl::Easy->new;
    my $req = $args->{request};
    $easy->setopt(CURLOPT_URL, $req->uri);
    my $verifypeer;
    if ( defined $args->{verifypeer} ) {
      $verifypeer = $args->{verifypeer};
    }
    elsif ( defined $self->{verifypeer} ) {
      $verifypeer = $self->{verifypeer};
    }
    $easy->setopt(CURLOPT_SSL_VERIFYPEER, $verifypeer) if defined $verifypeer;
    my $verifyhost;
    if ( defined $args->{verifyhost} ) {
      $verifypeer = $args->{verifyhost};
    }
    elsif ( defined $self->{verifyhost} ) {
      $verifypeer = $self->{verifyhost};
    }
    $easy->setopt(CURLOPT_SSL_VERIFYHOST, $verifyhost) if defined $verifyhost;
    $easy->setopt(CURLOPT_DNS_CACHE_TIMEOUT, 0);
    my $ipresolve = $args->{ipresolve} || $self->{ipresolve};
    if ( $ipresolve ) {
      $easy->setopt(CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4) if $ipresolve eq '4';
      $easy->setopt(CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V6) if $ipresolve eq '6';
    }
    $easy->setopt(CURLOPT_ENCODING, '');
    if ( $self->{agent} ) {
      my $agent = $self->{agent}->[ rand @{ $self->{agent} } ];
      $easy->setopt(CURLOPT_USERAGENT, $agent);
    }
    {
      my $proxy = $args->{proxy} || $self->{proxy};
      $easy->setopt(CURLOPT_PROXY, $proxy) if $proxy;
    }

    my @extra_headers;
    if (my $content = $req->content) {
        $easy->setopt(CURLOPT_POSTFIELDS, $content);
        push @extra_headers, 'Expect:';
    }

    $easy->setopt(CURLOPT_TIMEOUT, $self->{timeout});
    $easy->setopt( $methods{ $req->method }, 1 );
    $easy->setopt(CURLOPT_CUSTOMREQUEST, $req->method);
    $easy->setopt(CURLOPT_HTTPHEADER,
        [ split( m!\x0D\x0A!, $req->headers_as_string("\x0D\x0A") ), @extra_headers ]);

    $easy->setopt(CURLOPT_VERBOSE, 1) if $self->{curl_debug};

    if ( $self->{followredirects} ) {
      $easy->setopt(CURLOPT_FOLLOWLOCATION, 1);
      $easy->setopt(CURLOPT_MAXREDIRS, $self->{followredirects} );
    }
    my $id = refaddr $easy;
    my ($response, $header);
    $easy->setopt(CURLOPT_WRITEDATA, \$response);
    $easy->setopt(CURLOPT_WRITEHEADER, \$header);
    #$easy->setopt(CURLOPT_PRIVATE, $id);
    $args->{id} = $id;
    $args->{easy} = $easy;
    $args->{body} = \$response;
    $args->{header} = \$header;
    push @{ $self->{queue} }, $args;
    $self->{req_to_id}->{$req} = $id;
    if ( $args->{progress} ) {
      $easy->setopt(CURLOPT_NOPROGRESS,0);
      $easy->setopt(CURLOPT_PROGRESSFUNCTION,
        $me->callback( '_progress', $args->{sender}, $args->{progress}, $req, $args->{tag} ) );
    }
  }
  $poe_kernel->yield( '_dequeue' );
  return;
}

sub _dequeue {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  while ( $self->{max_concurrency} == 0 ||
          scalar keys %{ $self->{state} } < $self->{max_concurrency}) {
    my $dequeued = shift @{ $self->{queue} };
    last unless $dequeued;
    $self->{state}->{ refaddr($dequeued->{easy}) } = $dequeued;
    $self->{multi}->add_handle( $dequeued->{easy} );
  }
  $kernel->delay( '_perform', 0.5 );
  return;
}

sub _perform {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $self->{multi}->perform;

  while (my ($msg, $easy, $rv) = $self->{multi}->info_read) {
    my $id = refaddr $easy;
    if ($id) {
      my $state = delete $self->{state}->{ $id };
      my $req = $state->{request};
      my $easy = $state->{easy};
      my $stats = {
         total_time => $easy->getinfo(CURLINFO_TOTAL_TIME),
         dns_time => $easy->getinfo(CURLINFO_NAMELOOKUP_TIME),
         connect_time => $easy->getinfo(CURLINFO_CONNECT_TIME),
         start_transfer_time =>
             $easy->getinfo(CURLINFO_STARTTRANSFER_TIME),
         download_bytes =>
             $easy->getinfo(CURLINFO_SIZE_DOWNLOAD),
         upload_bytes => $easy->getinfo(CURLINFO_SIZE_UPLOAD),
      };
      if ($rv) {
         $kernel->yield( '_result', $state, [ 0+$rv, $easy->error ], $stats );
      }
      else {
         my $last_header = (split(/\r?\n\r?\n/,
                               ${$state->{header}}))[-1];
         my $response = HTTP::Response->parse($last_header .
                                              "\n\n" .
                                              ( ${ $state->{body} } || '' )
         );
         $req->uri( $easy->getinfo(CURLINFO_EFFECTIVE_URL) );
         $response->request($req);
         $kernel->yield( '_result', $state, $response, $stats );
      }
      delete $self->{state}->{ $id };
      $kernel->yield( '_dequeue' );
    }
  }
  return unless scalar keys %{ $self->{state} };
  $kernel->delay( '_perform', 0.5 );
  return;
}

sub _result {
  my ($kernel,$self,$state,$response,$stats) = @_[KERNEL,OBJECT,ARG0..$#_];
  delete $self->{req_to_id}->{ $state->{request} };
  delete $state->{easy};
  unless ( ref $response eq 'HTTP::Response' ) {
    my $code = $response->[0] eq '28' ? '408' : '500';
    $response = _error( $code, $response->[1] );
  }
  my $reqpack = [ $state->{request}, $state->{tag} ];
  my $respack = [ $response, $stats ];
  if ( ref $state->{response} eq 'POE::Session::AnonEvent' ) {
    $state->{response}->( $reqpack, $respack );
    return;
  }
  $kernel->post( $state->{sender}, $state->{response}, $reqpack, $respack );
  $kernel->refcount_decrement( $state->{sender}, __PACKAGE__ );
  return;
}

sub _progress {
  my ($kernel,$self,$ours,$theirs) = @_[KERNEL,OBJECT,ARG0,ARG1];
  my $sender = shift @{ $ours };
  my $event  = shift @{ $ours };
  $kernel->post( $sender, $event, $ours, [ @{ $theirs }[2,1] ] );
  return 0; # important
}

sub _error {
  my ($code, $message) = @_;

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
  return $r;
}
qq'MPD so good to me. And me';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Curl::Multi - a fast HTTP POE component

=head1 VERSION

version 1.00

=head1 SYNOPSIS

  use strict;
  use warnings;
  use HTTP::Request::Common qw[GET];
  use POE qw[Component::Curl::Multi];

  $!=1;

  my @urls = ( 'https://api.github.com/repos/git/git/tags',
               'http://this.is.made.up.stuff/',
               'http://www.cpan.org/',
               'http://www.google.com/', );

  my $curl = POE::Component::Curl::Multi->spawn(
    Alias => 'curl',
    FollowRedirects => 5,
    Max_Concurrency => 10,
  );

  POE::Session->create(
    package_states => [
      main => [qw(_start _response)],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    $poe_kernel->post( 'curl', 'request', '_response', GET($_) ) for @urls;
    return;
  }

  sub _response {
    my ($request_packet, $response_packet) = @_[ARG0, ARG1];
    use Data::Dumper;
    local $Data::Dumper::Indent=1;
    warn Dumper( $response_packet->[0] );
    return;
  }

=head1 DESCRIPTION

POE::Component::Curl::Multi is an HTTP user-agent for L<POE>.  It lets
other sessions run while HTTP transactions are being processed, and it
lets several HTTP transactions be processed in parallel.

It uses L<Net::Curl> internally to provide access to C<libcurl> for fast
performance. It strives to be API compatible(ish) with
L<POE::Component::Client::HTTP>.

It is inspired by L<AnyEvent::Curl::Multi>.

Versions of this module prior to 0.23 did not verify the peer's certificate
when performing SSL/TLS. As of 0.23 peer verification is the default behaviour.
If this is a problem for you then see the C<verifypeer> ( and optionally the
C<verifyhost> ) options to C<spawn> and C<request>.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Starts an instance of the component. Takes a number of options:

=over 2

=item C<alias>

Set an alias for this instance of the component. There is no default.

=item C<timeout>

Specifies a timeout, in seconds, for each request, defaults to C<180>.

=item C<followredirects>

Specifies how many redirects (e.g. 302 Moved) to
follow.  If not specified defaults to C<0>, and thus no redirection is
followed.

=item C<agent>

Can either be a string or an C<ARRAYREF> of strings. This will be
used as C<UserAgent> header in requests. If an C<ARRAYREF> is provided
one of them will be picked randomly to send.

See L<http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTUSERAGENT>

=item C<proxy>

Specify a proxy to use.

See L<http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPROXY>

=item C<max_concurrency>

Specify the maximum number of concurrent requests, a value of C<0> means
no limit will be imposed. The default is C<0>.

=item C<ipresolve>

Specify what kind of IP addresses to use when hostnames resolve to more than
one version of IP.

Specify C<4> for IPv4 only or C<6> for IPv6 only.

The default is C<curl>'s default which is C<whatever>, which will use all
IP versions.

See L<https://curl.se/libcurl/c/CURLOPT_IPRESOLVE.html>

=item C<verifypeer>

Relevant to SSL/TLS, specify whether the authenticity of the peer's certificate should be
verified. Set to C<1> for verification or C<0> to live dangerously.

Curl defaults to C<1> if you don't specify this.

See L<https://curl.se/libcurl/c/CURLOPT_SSL_VERIFYPEER.html> for the full details.

=item C<verifyhost>

Again relevant to SSL/TLS, specify whether the hostname on the certificate is for
the server it is known as.

Set to C<2> to verify that the hostname (either in the Common Name field or a Subject
Alternative Name field) matches the hostname in the URL.

Set to C<0> to disable this verification and live with the consequences.

Curl defaults to C<2> if you don't specify this.

See L<https://curl.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html> for the full details.

=item C<curl_debug>

Enable C<libcurl>'s verbosity.

See L<http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTVERBOSE>

=back

Returns an object that accepts some methods as documented below.

=back

=head2 AVAILABLE METHODS

=over

=item C<session_id>

Takes no arguments. Returns the ID of the component's session.

=item C<shutdown>

Responds to all pending requests with 408 (request timeout), and then
shuts down the component and all subcomponents.

=item C<pending_requests_count>

Returns the number of requests currently being processed.

=item C<cancel>

Cancel a specific HTTP request. Requires a reference to the original request (blessed or stringified)
so it knows which one to cancel.

=back

=head1 ACCEPTED EVENTS

Sessions communicate asynchronously with the component.  They
post requests to it, and it posts responses back.

=head2 C<request>

Requests are posted to the component's C<request> state.  They include
an L<HTTP::Request> object which defines the request.  For example:

  $kernel->post(
    'ua', 'request',            # http session alias & state
    'response',                 # my state to receive responses
    GET('http://poe.perl.org'), # a simple HTTP request
    'unique id',                # a tag to identify the request
    'progress',                 # an event to indicate progress
    'http://1.2.3.4:80/'        # proxy to use for this request
  );

This invocation is compatible with L<POE::Component::Client::HTTP>.

You may also send either an C<arrayref> or C<hashref> to the C<request> state
with the following parameters:

=over 2

=item C<request>

A L<HTTP::Request> object which defines the request.

=item C<response>

Either a string specifying the state in the sender session to receive responses or,
alternatively, a L<POE::Session> C<postback> that will be invoked with responses.

=item C<tag>

A tag to identify the request.

=item C<progress>

An optional handler, if specified the component will provide progress metrics
(see sample handler below).

=item C<proxy>

Specify a proxy to use. This overrides the C<proxy> set with C<spawn>, if
applicable.

See L<http://curl.haxx.se/libcurl/c/curl_easy_setopt.html#CURLOPTPROXY>

=item C<ipresolve>

Specify what kind of IP addresses to use when hostnames resolve to more than
one version of IP.

Specify C<4> for IPv4 only or C<6> for IPv6 only.

The default is C<curl>'s default which is C<whatever>, which will use all
IP versions.

See L<https://curl.se/libcurl/c/CURLOPT_IPRESOLVE.html>

=item C<verifypeer>

Relevant to SSL/TLS, specify whether the authenticity of the peer's certificate should be
verified. Set to C<1> for verification or C<0> to live dangerously.

Curl defaults to C<1> if you don't specify this.

See L<https://curl.se/libcurl/c/CURLOPT_SSL_VERIFYPEER.html> for the full details.

=item C<verifyhost>

Again relevant to SSL/TLS, specify whether the hostname on the certificate is for
the server it is known as.

Set to C<2> to verify that the hostname (either in the Common Name field or a Subject
Alternative Name field) matches the hostname in the URL.

Set to C<0> to disable this verification and live with the consequences.

Curl defaults to C<2> if you don't specify this.

See L<https://curl.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html> for the full details.

=item C<session>

Specify a POE::Session object, ID or alias to send responses to instead of the
sending session. If a C<postback> is used for C<response>, this option will be
ignored.

=back

=head2 C<pending_requests_count>

Returns the number of requests currently being processed.  To receive the return value, it
must be invoked with $kernel->call().

  my $count = $kernel->call('ua' => 'pending_requests_count');

This is also available as a method on the object returned by C<spawn>

  my $count = $curl->pending_requests_count();

=head2 C<shutdown>

Responds to all pending requests with 408 (request timeout), and then
shuts down the component and all subcomponents.

=head1 SENT EVENTS

=head2 response handler

In addition to all the usual POE parameters, HTTP responses come with
two list references:

  my ($request_packet, $response_packet) = @_[ARG0, ARG1];

C<$request_packet> contains a reference to the original HTTP::Request
object.  This is useful for matching responses back to the requests
that generated them.

  my $http_request_object = $request_packet->[0];
  my $http_request_tag    = $request_packet->[1]; # from the 'request' post

C<$response_packet> contains a reference to the resulting
HTTP::Response object.

  my $http_response_object = $response_packet->[0];

Please see the HTTP::Request and HTTP::Response manpages for more
information.

=head2 progress handler

The example progress handler shows how to calculate a percentage of
download completion.

  sub progress_handler {
    my $gen_args  = $_[ARG0];    # args passed to all calls
    my $call_args = $_[ARG1];    # args specific to the call

    my $req = $gen_args->[0];    # HTTP::Request object being serviced
    my $tag = $gen_args->[1];    # Request ID tag from.
    my $got = $call_args->[0];   # Number of bytes retrieved so far.
    my $tot = $call_args->[1];   # Total bytes to be retrieved.

    my $percent = $got / $tot * 100;

    printf(
      "-- %.0f%% [%d/%d]: %s\n", $percent, $got, $tot, $req->uri()
    );

    return;
  }

=head1 STREAMING

This component does not (yet) support L<POE::Component::Client::HTTP>'s streaming options.

=head1 CLIENT HEADERS

POE::Component::Curl::Multi sets its own response headers with
additional information.  All of its headers begin with "X-PCCH".

=head2 X-PCCH-Errmsg

POE::Component::Curl::Multi may fail because of an internal client
error rather than an HTTP protocol error.  X-PCCH-Errmsg will contain a
human readable reason for client failures, should they occur.

The text of X-PCCH-Errmsg may also be repeated in the response's
content.

=head2 X-PCCH-Peer

This response header is not yet supported.

=head1 ATTRIBUTION

POE::Component::Curl::Multi is based on both

L<POE::Component::Client::HTTP> by Rocco Caputo, Rob Bloodgood and Martijn van Beers

and

L<AnyEvent::Curl::Multi> by Michael S. Fischer

=head1 SEE ALSO

L<Net::Curl>

L<AnyEvent::Curl::Multi>

L<POE::Component::Client::HTTP>

=head1 AUTHOR

Chris Williams

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams, Michael S. Fischer, Rocco Caputo, Rob Bloodgood and Martijn van Beers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
