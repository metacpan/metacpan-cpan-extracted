use strict;
use Net::Radius::Dictionary;
use POE qw(Component::Server::RADIUS);

# Lets define some users who we'll allow access if they can provide the password
my %users = (
        aj => '0fGbqzu0cfA',
        clippy => 'D)z5gcjex1fB',
        cobb => '3ctPbe,cyl8K',
        crudpuppy => '0"bchMltV7dz',
        cthulhu => 'pn}Vbe0Dwr5z',
        matt => 'dyQ4sZ^x0eta',
        mike => 'iRr3auKbv8l>',
        mrcola => 'ynj4H?jec1Ol',
        tanya => 'korvS2~Rip4f',
        tux => 'Io2obo2kT%xq',
);

# We need a Net::Radius::Dictionary object to pass to the poco
my $dict = Net::Radius::Dictionary->new( 'dictionary' );

my $radiusd = POE::Component::Server::RADIUS->spawn( dict => $dict );

# Add some NAS devices to the poco
$radiusd->add_client( name => 'creosote', address => '192.168.1.73', secret => 'Po9hpbN^nz6n' );
$radiusd->add_client( name => 'dunmanifestin', address => '192.168.1.17', secret => '9g~dorQuos5E' );
$radiusd->add_client( name => 'genua', address => '192.168.1.71', secret => 'Qj8zmmr3hZb,' );
$radiusd->add_client( name => 'ladysybilramkin', address => '192.168.1.217', secret => 'j8yTuBfl)t2s' );
$radiusd->add_client( name => 'mort', address => '192.168.1.229', secret => '8oEhfKm(krr0' );
$radiusd->add_client( name => 'ysabell', address => '192.168.1.84', secret => 'i8quDld_2suH' );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _authenticate _accounting)],
   ],
   heap => { users => \%users, },
);

$poe_kernel->run();
exit 0;

sub _start {
  # We need to register with the poco to receive events
  $poe_kernel->post( $radiusd->session_id(), 'register', authevent => '_authenticate', acctevent => '_accounting' );
  return;
}

sub _authenticate {
  my ($kernel,$sender,$heap,$client,$data,$req_id) = @_[KERNEL,SENDER,HEAP,ARG0,ARG1,ARG2];
  # Lets ignore dodgy requests
  return unless $data->{'User-Name'} and $data->{'User-Password'};
  # Send a reject if the username doesn't exist
  unless ( $heap->{users}->{ $data->{'User-Name'} } ) {
     $kernel->call( $sender, 'reject', $req_id );
     return;
  }
  # Does the password match? If not send a reject
  unless ( $heap->{users}->{ $data->{'User-Name'} } eq $data->{'User-Password'} ) {
     $kernel->call( $sender, 'reject', $req_id );
     return;
  }
  # Okay everything is cool. 
  $kernel->call( $sender, 'accept', $req_id );
  return;
}

sub _accounting {
  my ($kernel,$sender,$heap,$client,$data) = @_[KERNEL,SENDER,HEAP,ARG0,ARG1];
  # Do something with the data provided, like log to a database or a file
  return;
}

