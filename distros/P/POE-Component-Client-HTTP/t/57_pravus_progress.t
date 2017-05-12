# See rt.cpan.org ticket 36627.
# vim: filetype=perl ts=2 sw=2 expandtab

use warnings;
use strict;

use Test::More tests => 2;
use HTTP::Request::Common qw(GET);
use POE;
use POE::Component::Client::HTTP;
use Test::POE::Server::TCP;

POE::Component::Client::HTTP->spawn(
  Alias           => 'ua',
  Streaming       => 4000,
  FollowRedirects => 32,
);

POE::Session->create(
  package_states => [
    main => [
      qw(
        _start http_response http_progress _stop
        testd_registered testd_client_input idle_timeout
      )
    ],
  ],
);

POE::Kernel->run();
exit 0;

sub _start {
  $_[HEAP]{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::Stream->new(),
    address => 'localhost',
  );

  $_[HEAP]{got_response} = 0;
  $_[HEAP]{got_progress} = 0;
}

sub testd_registered {
  my $port = $_[HEAP]{testd}->port();
  $_[KERNEL]->post(
    ua => request => 'http_response',
    GET("http://localhost:$port/"), 'id', 'http_progress'
  );
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  $heap->{testd}->send_to_client(
    $id,
    "HTTP/1.0 200 OK\x0d\x0a" .
    "Content-Length: 100000\x0d\x0a" .
    "Content-Type: text/html\x0d\x0a" .
    "\x0d\x0a" .
    "!" x 100_000
  );
}

sub http_response {
  $_[HEAP]{got_response}++;
  $_[KERNEL]->delay(idle_timeout => 1);
}

sub http_progress {
  $_[HEAP]{got_progress}++;
  $_[KERNEL]->delay(idle_timeout => 1);
}

sub idle_timeout {
  $_[HEAP]{testd}->shutdown();
  $_[KERNEL]->post(ua => "shutdown");
}

sub _stop {
  ok($_[HEAP]{got_response}, "got response: $_[HEAP]{got_response}");
  ok($_[HEAP]{got_progress}, "got progress: $_[HEAP]{got_progress}");
}
