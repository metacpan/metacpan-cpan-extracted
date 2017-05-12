use strict;
use Test::More tests => 5;
use Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Line);
use Data::Dumper;

use_ok('POE::Component::Client::Whois');

my @response;

while(<DATA>) {
  chomp;
  push @response, $_;
}

POE::Session->create(
  package_states => [
	'main' => [qw(_start _stop _whois _accept _oops _input _error _flush)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{sockfactory} = POE::Wheel::SocketFactory->new(
	BindAddress => '127.0.0.1',
	BindPort => 0,
	SuccessEvent => '_accept',
	FailureEvent => '_oops',
  );
  my $port;
  ($port, undef) = unpack_sockaddr_in( $heap->{sockfactory}->getsockname );
  POE::Component::Client::Whois->whois( 
	host => '127.0.0.1', 
	port => $port,
        query => '192.168.0.0', 
        event => '_whois',
        _arbitary => [ qw(moo moo moo) ] 
  );
  return;
}

sub _stop {
  pass('Everything went away');
  return;
}

sub _oops {
  delete $_[HEAP]->{sockfactory};
  return;
}

sub _accept {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  pass('Whois connect');
  my $wheel = POE::Wheel::ReadWrite->new(
        Handle => $socket,
        InputEvent => '_input',
        ErrorEvent => '_error',
	FlushedEvent => '_flush',
        Filter => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
  );
  $heap->{client}->{ $wheel->ID() } = $wheel;
  return;
}

sub _input {
  my ( $heap, $input, $wheel_id ) = @_[ HEAP, ARG0, ARG1 ];
  ok( $input eq '192.168.0.0', $input );
  my $data = shift @response;
  $heap->{client}->{ $wheel_id }->put( $data );
  return;
}

sub _flush {
  my ($heap,$wheel_id) = @_[HEAP,ARG0];
  my $data = shift @response;
  if ( defined $data ) {
    $heap->{client}->{ $wheel_id }->put( $data );
  }
  else {
    delete $heap->{client}->{ $wheel_id };
  }
  return;
}

sub _error {
  my ( $heap, $wheel_id ) = @_[ HEAP, ARG3 ];
  delete $heap->{client}->{$wheel_id}; 
  delete $heap->{sockfactory};
  return;
}

sub _whois {
  my ($heap,$data) = @_[HEAP,ARG0];
  ok( $data->{reply}, 'We got a reply' );
  delete $heap->{sockfactory};
  return;
}

__DATA__
OrgName:    Internet Assigned Numbers Authority 
OrgID:      IANA
Address:    4676 Admiralty Way, Suite 330
City:       Marina del Rey
StateProv:  CA
PostalCode: 90292-6695
Country:    US

NetRange:   192.168.0.0 - 192.168.255.255 
CIDR:       192.168.0.0/16 
NetName:    IANA-CBLK1
NetHandle:  NET-192-168-0-0-1
Parent:     NET-192-0-0-0-0
NetType:    IANA Special Use
NameServer: BLACKHOLE-1.IANA.ORG
NameServer: BLACKHOLE-2.IANA.ORG
Comment:    This block is reserved for special purposes.
Comment:    Please see RFC 1918 for additional information.
Comment:    http://www.arin.net/reference/rfc/rfc1918.txt
RegDate:    1994-03-15
Updated:    2007-11-27

OrgAbuseHandle: IANA-IP-ARIN
OrgAbuseName:   Internet Corporation for Assigned Names and Number 
OrgAbusePhone:  +1-310-301-5820
OrgAbuseEmail:  abuse@iana.org

OrgTechHandle: IANA-IP-ARIN
OrgTechName:   Internet Corporation for Assigned Names and Number 
OrgTechPhone:  +1-310-301-5820
OrgTechEmail:  abuse@iana.org

# ARIN WHOIS database, last updated 2008-01-15 19:07
# Enter ? for additional hints on searching ARIN's WHOIS database.
