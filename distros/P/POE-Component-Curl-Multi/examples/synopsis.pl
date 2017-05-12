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
