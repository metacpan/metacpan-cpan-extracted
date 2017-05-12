use strict;
use Test::More tests => 4;
use Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);

use_ok('POE::Component::Client::Whois');

POE::Session->create(
  package_states => [
	'main' => [qw(_start _stop _whois)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::Client::Whois->whois( 
        query => 'bingosnet.ao', 
        event => '_whois',
        _arbitary => [ qw(moo moo moo) ] 
  );
  return;
}

sub _stop {
  pass('Everything went away');
  return;
}

sub _whois {
  my ($heap,$data) = @_[HEAP,ARG0];
  ok( $data->{error}, 'We got a reply' );
  is( $data->{error}, 'This TLD has no whois server.', 'This TLD has no whois server.' );
  return;
}
