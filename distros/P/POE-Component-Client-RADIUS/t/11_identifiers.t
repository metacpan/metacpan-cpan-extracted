use strict;
use warnings;
use Test::More q[no_plan];
BEGIN { use_ok('POE::Component::Client::RADIUS') };

use Socket;
use POE;
use Net::Radius::Dictionary;
use Net::Radius::Packet;


my $dict = new Net::Radius::Dictionary 'dictionary'
	or die "Couldn't read dictionary: $!";

POE::Session->create(
 inline_states => { _start => \&_setup_test, _test_start => \&test_start, _stop => \&test_stop, },
 package_states => [
   'main' => [qw(_get_datagram _response)],
 ],
);

$poe_kernel->run();
exit 0;

sub _setup_test {
  $poe_kernel->yield('_test_start');
  return;
}

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{tests}++;
  my $proto = getprotobyname('udp');
  my $paddr = sockaddr_in( 0, inet_aton('127.0.0.1') );
  socket( my $socket, PF_INET, SOCK_DGRAM, $proto)   || die "socket: $!";
  bind( $socket, $paddr)                          || die "bind: $!";
  my ($port,$addr) = sockaddr_in( getsockname $socket );
  $kernel->select_read( $socket, '_get_datagram' );
  my $self = POE::Component::Client::RADIUS->authenticate(
        dict => $dict,
        username => 'bingos',
        password => 'moocow',
        attributes => { },
        event => '_response',
        server => '127.0.0.1',
        port => $port,
        secret => 'bogoff',
        options => { trace => 0 },
  );
  isa_ok ( $self, 'POE::Component::Client::RADIUS' );
  undef;
}

sub test_stop {
  pass('Everything stopped');
  return;
}

sub _get_datagram {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $remote_address = recv( $socket, my $message = '', 4096, 0 );
  die "$!\n" unless defined $remote_address;
  my $p = Net::Radius::Packet->new( $dict, $message );
  ok( $p->code eq 'Access-Request', $p->code );
  ok( $p->attr('User-Name') eq 'bingos', 'User-Name' );
  ok( $p->password('bogoff') eq 'moocow', 'Password' );
  my $rp = new Net::Radius::Packet $dict;
  $rp->set_identifier($p->identifier);
  $rp->set_authenticator($p->authenticator);
  $rp->set_code('Access-Accept');
  my $reply = auth_resp($rp->pack, 'bogoff');
  send( $socket, $reply, 0, $remote_address ) == length($reply) or
	die "Woah $!\n";
  $kernel->select_read( $socket );
  $kernel->yield('_test_start') unless $heap->{tests} > 257;
  return;
}

sub _response {
  my ($kernel,$data) = @_[KERNEL,ARG0];
  ok( $data->{response}, 'Got a response' );
  ok( $data->{response}->{Code} eq 'Access-Accept', 'Access-Accept' );
  return;
}
