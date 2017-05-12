#!perl

# A short program to dump requests and responses.
# Provided by Toby Ovod-Everett.  Thanks!

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use HTTP::Request;
use POE qw(Component::Client::HTTP);

POE::Component::Client::HTTP->spawn(
  Alias     => 'ua',                  # defaults to 'weeble'
  Timeout   => 20,                    # defaults to 180 seconds
);

POE::Session->create(
  inline_states => {
    _start => sub {
      POE::Kernel->post(
        'ua',        # posts to the 'ua' alias
        'request',   # posts to ua's 'request' state
        'response',  # which of our states will receive the response
        HTTP::Request->new(GET => $ARGV[0]),    # an HTTP::Request object
      );
    },
    _stop => sub {},
    response => \&response_handler,
  },
);

POE::Kernel->run();
exit;

sub response_handler {
  my ($request_packet, $response_packet) = @_[ARG0, ARG1];
  my $request_object  = $request_packet->[0];
  my $response_object = $response_packet->[0];

  my $stream_chunk;

  if (!defined($response_object->content)) {
    $stream_chunk = $response_packet->[1];
  }

  print(
    "*" x 78, "\n",
    "*** my request:\n",
    "-" x 78, "\n",
    $request_object->as_string(),
    "*" x 78, "\n",
    "*** their response:\n",
    "-" x 78, "\n",
    $response_object->as_string(),
  );

  if (defined $stream_chunk) {
    print( "-" x 40, "\n", $stream_chunk, "\n" );
  }

  print "*" x 78, "\n";
}
