use strict;
use Net::Radius::Dictionary;
use POE qw(Component::Client::RADIUS);

my $username = 'bingos';
my $password = 'moocow';
my $secret = 'bogoff';

my $server = '192.168.1.1';

my $dictionary = '/etc/radius/dictionary';

my $dict = Net::Radius::Dictionary->new( $dictionary );

die "No dictionary found\n" unless $dict;

my $radius = POE::Component::Client::RADIUS->spawn( dict => $dict );

POE::Session->create(
  package_states => [
	'main' => [qw(_start _auth)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->post( 
	$radius->session_id(), 
	'authenticate',
	event => '_auth',
	username => $username,
	password => $password,
	server => $server,
	secret => $secret,
  );
  return;
}

sub _auth {
  my ($kernel,$sender,$data) = @_[KERNEL,SENDER,ARG0];

  # Something went wrong
  if ( $data->{error} ) {
	warn $data->{error}, "\n";
	$kernel->post( $sender, 'shutdown' );
	return;
  }

  # There was a timeout getting a response back from the RADIUS server
  if ( $data->{timeout} ) {
	warn $data->{timeout}, "\n";
	$kernel->post( $sender, 'shutdown' );
	return;
  }

  # Okay we got a response
  if ( $data->{response}->{Code} eq 'Access-Accept' ) {
	print "Yay, we were authenticated\n";
  }
  elsif ( $data->{response}->{Code} eq 'Access-Reject' ) {
	print "Boo, the server didn't like us\n";
  }
  else {
	print $data->{response}->{Code}, "\n";
  }

  print join ' ', $_, $data->{response}->{$_}, "\n" for keys %{ $data->{response} };

  return;
}
