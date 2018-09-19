package Net::Curl::Parallel;

use strictures 2;
use Moo;
use Carp;
use Guard qw(scope_guard);
use HTTP::Response;
use HTTP::Parser::XS qw(parse_http_response HEADERS_AS_ARRAYREF);
use Net::Curl::Easy  qw(:constants);
use Net::Curl::Multi qw(:constants);
use Net::Curl::Parallel::Types -types;
use Net::Curl::Parallel::Response;

my @AVAIL_CURL_POOL;
{
  my $MAX_CURLS_IN_POOL = 50;
  sub max_curls_in_pool {
    shift;
    $MAX_CURLS_IN_POOL = $_[0] if @_;
    return $MAX_CURLS_IN_POOL;
  }
}

has agent           => (is => 'ro', default => 'Net::Curl::Parallel/v2.0');
has slots           => (is => 'ro', default => 10);
has connect_timeout => (is => 'ro', default => 50);
has request_timeout => (is => 'ro', default => 500);
has max_redirects   => (is => 'ro', default => 0);
has verify_ssl_peer => (is => 'ro', default => 1);
has keep_alive      => (is => 'ro', default => 1);
has verbose         => (is => 'rw', default => 0);
has requests        => (is => 'ro', default => sub{ [] });
has responses       => (is => 'ro', default => sub{ [] });

has curl_multi      => (is => 'ro', default => sub{ Net::Curl::Multi->new });
has avail_curl_pool => (is => 'ro', default => sub{ \@AVAIL_CURL_POOL });

sub add { shift->_queue(1, @_) }
sub try { shift->_queue(0, @_) }  ## no critic (TryTiny)

sub _queue {
  my $self = shift;
  my $die  = shift;
  my @args = ref $_[0] ? @_ : [@_];
  my @rv = map { $self->request($_, $die) } @args;

  return $rv[0] if @rv == 1;
  return @rv if wantarray;
  return [@rv];
}

sub request {
  my ($self, $request, $die) = @_;
  my ($method, $uri, $headers, $content) = @{Request->assert_coerce($request)};
  my $idx = scalar @{$self->requests};

  # HTTP Keep-alive
  push @$headers, "Connection: keep-alive"
    if $self->keep_alive
    && !grep{ $_ =~ /^Connection:/i } @$headers;

  if ($method eq 'POST') {
    # libcurl adds an 'Expect: 100-continue' header to all POST requests with a
    # body greater than 1024 bytes. This is not needed for our internal APIs,
    # so we are turning it off by default. It can be turned back on by
    # explicitly including the header in the request, and the client code will
    # need to handle the 100 response
    push @$headers, "Expect:"
      unless grep{ $_ =~ /^Expect:/i } @$headers;
  }

  push @{$self->requests}, [$method, $uri, $headers, $content, $die];
  return $idx;
}

sub setup_curl {
  my ($self, $idx) = @_;
  my ($method, $uri, $headers, $content, $die) = @{$self->requests->[$idx]};
  # Both sides of the // can never be false because Net::Curl::Easy->new
  # will always return true.
  # uncoverable condition false
  my $curl = shift(@{$self->avail_curl_pool}) // Net::Curl::Easy->new({});

  # This is okay because the first parameter to Net::Curl::Easy->new() is the
  # base object. We can put whatever we want into here.
  $curl->{private} = {
    response => Net::Curl::Parallel::Response->new,
    idx  => $idx,
    uri  => $uri,
    die  => $die,
  };

  # Basic config and tcp setup
  $curl->setopt(CURLOPT_NOPROGRESS, 1);
  $curl->setopt(CURLOPT_TCP_NODELAY, 1);

  # Set connection timeout
  $curl->setopt(CURLOPT_CONNECTTIMEOUT_MS, $self->connect_timeout)
    if $self->connect_timeout;

  # Keep idle TCP connections alive longer. Note - this option is available
  # starting in libcurl 7.25.0
  # uncoverable branch false
  $curl->setopt(CURLOPT_TCP_KEEPALIVE, 1)
    if &CURLOPT_TCP_KEEPALIVE;

  # Set verbosity
  $curl->setopt(CURLOPT_VERBOSE, 1)
    if $self->verbose;

  # HTTP
  $curl->setopt(CURLOPT_ACCEPT_ENCODING, '');
  $curl->setopt(CURLOPT_PROTOCOLS, CURLPROTO_HTTP | CURLPROTO_HTTPS);
  $curl->setopt(CURLOPT_USERAGENT, $self->agent);
  $curl->setopt(CURLOPT_URL, $uri);

  if ($method eq 'POST') {
    $curl->setopt(CURLOPT_POST, 1);
    $curl->setopt(CURLOPT_POSTFIELDS, $content);
  }

  # Configure headers
  $curl->setopt(CURLOPT_HTTPHEADER, $headers)
    if @$headers;

  $curl->setopt(CURLOPT_WRITEDATA,   $curl->{private}{response}->fh_body);
  $curl->setopt(CURLOPT_WRITEHEADER, $curl->{private}{response}->fh_head);

  # Configure redirect behavior
  $curl->setopt(CURLOPT_FOLLOWLOCATION, $self->max_redirects > 0);
  $curl->setopt(CURLOPT_MAXREDIRS,      $self->max_redirects);
  $curl->setopt(CURLOPT_AUTOREFERER,    1);

  # Allow user override of ssl certificate verification
  $curl->setopt(CURLOPT_SSL_VERIFYPEER, $self->verify_ssl_peer);

  # Set request timeout
  $curl->setopt(CURLOPT_TIMEOUT_MS, $self->request_timeout)
    if $self->request_timeout;

  # Clean up memory a little, but leave an undef at the index in the requests
  # array since we are using the index as the key.
  $self->requests->[$idx] = undef;

  return $curl;
}

sub perform {
  my $self    = shift;
  my $total   = @{$self->requests};
  my $pending = 0;
  my $idx     = 0;

  $self->{responses} = []; # clear responses state from any prior runs
  scope_guard{ $self->{requests} = [] }; # clear state for next run

  until ($idx == $total && $pending == 0) {
    # Fill empty slots
    while ($idx < $total && $pending < $self->slots) {
      $self->curl_multi->add_handle($self->setup_curl($idx));
      ++$pending;
      ++$idx;
    }

    $self->curl_multi->wait(1);
    my $running = $self->curl_multi->perform;

    # At least one request is complete
    if ($running != $pending) {
      my ($msg, $curl, $result) = $self->curl_multi->info_read;

      # A request is complete
      if ($msg) {
        scope_guard{
          --$pending;

          $self->curl_multi->remove_handle($curl);

          delete $curl->{private};
          $curl->reset;

          # Ignore max_curls while perform() is running
          push @{$self->avail_curl_pool}, $curl;
        };

        my $ridx = $curl->{private}{idx};

        # Successful result
        if ($result == 0) {
          $curl->{private}{response}->complete;
        }
        # Network error
        else {
          my $msg = join ' ', $curl->strerror($result), $curl->{private}{uri};
          croak $msg if $curl->{private}{die};
          $curl->{private}{response}->fail($msg);
        }

        $self->set_response($ridx, $curl->{private}{response});
      }
    }
  }

  # Remove extraneous curl instances
  $#{$self->avail_curl_pool} = $self->max_curls_in_pool;

  return @{$self->responses};
}

sub set_response {
  my ($self, $idx, $response) = @_;
  $self->responses->[$idx] = $response;
}

sub collect {
  my $self = shift;
  return $self->responses->[shift] if @_ == 1;  # single id
  my @results = @_
    ? map{ $self->responses->[$_] } @_          # multiple ids
    : @{$self->responses};                      # no ids
  return @results if wantarray;
  return [@results];
}

sub fetch {
  my $class = shift;
  my $fetch = ref $class ? $class : $class->new;
  my ($id) = $fetch->try(@_);
  $fetch->perform;
  my ($response) = $fetch->collect($id);
  return $response;
}

1;

=head1 NAME

Net::Curl::Parallel - perform concurrent HTTP requests using libcurl

=head1 SYNOPSIS

  use Net::Curl::Parallel;

  my $fetch = Net::Curl::Parallel->new(
    agent           => 'Net::Curl::Parallel/v0.1',
    slots           => 10,
    max_redirects   => 3,
    connect_timeout => 50,  # ms
    request_timeout => 500, # ms
  );

  # Add requests to be handled concurrently
  my ($req1) = $fetch->add(HTTP::Request->new(...));         # pass an HTTP::Request instance
  my ($req2) = $fetch->add(GET => 'http://www.example.com'); # pass HTTP::Request constructor args
  my ($req3) = $fetch->try(GET => ...);                      # like add() but don't croak on failure

  # Request the... uh, well, requests
  $fetch->perform;

  # Collect individually
  my $res1 = $fetch->collect($req1);
  my $res2 = $fetch->collect($req2);
  my $res3 = $fetch->collect($req3);

  # Collect a few
  my @responses = $fetch->collect($req1, $req2);

  # Or get the whole set
  my @responses = $fetch->collect;

  # Perform a single request
  my $response = Net::Curl::Parallel->fetch(...);

=head1 DESCRIPTION

 Stop trying to make fetch happen; it's not going to happen
   <https://www.youtube.com/watch?v=Pubd-spHN-0>
   -- author of superior module, L<ZR::Curl>, fREW "mean-girl" Schmidt

=head1 CLASS METHODS

=head2 fetch

Performs a single request and returns the response. Accepts the same parameters
as L</add> or L</try> and returns a L<Net::Curl::Parallel::Response>. Internally, this routine
uses L</try>, so failed requests do not C<die>. Instead, check the value of
L<Net::Curl::Parallel::Response/failed>.

  my $response = Net::Curl::Parallel->fetch(GET => ...);

  if ($response->failed) {
    ...
  } else {
    ...
  }

=head2 max_curls_in_pool

Please see the NOTES below about this class method.

=head1 METHODS

=head2 new

The default values for constructor arguments have been selected as sensible for
an interactive web request. Please exercise care when increasing these numbers
to ensure web service worker availability as well as to avoid bandwidth
saturation and throttling.

=over

=item agent

User agent string. Defaults to C<'Net::Curl::Parallel/v0.1'>.

=item slots

Max number of requests to process simultaneously. Defaults to 10.

=item max_redirects

Max number of times a remote server may redirect any single request. Defaults
to C<undef> (no redirects).

=item connect_timeout

Max initial connection time in milliseconds. Defaults to 50.

=item request_timeout

Max total request time in milliseconds. Defaults to 500.

=item keep_alive

Autmatically set C<Connection: keep-alive> on all HTTP requests. Defaults to
true.

If a request already has a C<Connection:> header, that header will be left alone.

=item verbose

Turn on verbose logging within curl. Defaults to false.

=back

=head2 add

Adds any number of L<HTTP::Request> objects to the download set. May also be
called with arguments to pass unchanged to the L<HTTP::Request> constructor, in
which case all arguments are consumed and a single request is added.

Any request which fails will croak, preventing the servicing of any further
requests. Completed requests result in an L<Net::Curl::Parallel::Response> object.

Returns a list of array indexes that identify the location of the responses in
the result array returned by L</perform>. The order of the returned indexes
corresponds to the order of requests passed to C<add> as parameters.

  my @ids  = $fetch->add($req1, $req2, $req3);
  my ($id) = $fetch->add(GET => ...);

  # This also works.
  my $id   = $fetch->add(GET => ...);

=head2 try

Similar to L</add>, but a failed request will result in a failed
L<HTTP::Response> with an error message rather than croaking.

  $fetch->try(HTTP::Request->new(...));

  my ($response) = $fetch->perform;

  if ($response->failed) {
    handle_errors($response->error);
  } else {
    do_stuff($response);
  }

=head2 perform

Performs all requests and returns a list of each response in the order it was
added. This method will not return until all requests have completed or an
unhandled error is encountered. Returns a list of L<Net::Curl::Parallel::Response>
objects corresponding to the index values returned by the L</add> and L</try>
methods.

The behavior of an individual request when an error is encountered (e.g. unable
to reach the remote host, timeout, etc.) is determined by whether the request
was added by L</add> or L</try>.

B<NOTE>: This means perform() could end prematurely if a request added with L</add> throws an exception, even if all the other requests were added with L</try>.

=head2 collect

When called in list context, returns a list of responses corresponding to the
list of request ids passed in. If called without arguments, the defaults to all
responses.

When called in scalar context, returns a single response corresponding to the
request id passed in. If called without arguments, returns an array ref holding
all responses.

B<NOTE>: This will B<not> block if the request is not completed with L</perform>.

=head1 NOTES

=head2 POSTs and Expect header

If you L</add> a POST request, libcurl normally adds a 'Expect: 100-continue'
header depending on the body size. This can often result in undesirable
behavior, so Net::Curl::Parallel disables that by adding a blank 'Expect:'
header by default.

You can set an 'Expect:' header and Net::Curl::Parallel will leave it alone.

=head2 Pool of curls

In order to conserve memory, there is a process-global pool of Net::Curl::Easy
objects. These are the objects that do the actual HTTP requests. You can access
them with C<< $self->curls >>.

The pool's size defaults to 50. You can set this by calling

  # Or whatever number
  Net::Curl::Parallel->max_curls_in_pool(20);

The pool will be resized the next time L</perform> completes.

Note: The pool's max size is ignored while L</perform> is running; the max is
only enforced at the end of L</perform>.

=head1 CAVEATS

=head2 Remember to call perform

  jp    [4:07 PM] ah, helps if you actually `perform` the requests
  jober [4:09 PM] Ah, good caveat. I ought to put that in the docs.
  jp    [4:09 PM] it is in there, just a little hidden

=head1 MAINTAINER

Rob Kinyon <rob.kinyon@gmail.com>

=head1 SUPPORT

Initial versions written by ZipRecruiter staff (jober and others).

Codebase and support generously provided by ZipRecruiter for opensourcing.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010-onwards by ZipRecruiter

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
