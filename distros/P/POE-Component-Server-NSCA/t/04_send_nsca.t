use Test::More;

unless ( -e 'send_nsca.tests' ) {
  plan skip_all => 'No "send_nsca" program specified';
}

plan tests => 9;

open FH, '< send_nsca.tests' or die "$!\n";
my $send_nsca = <FH>;
close FH;
chomp $send_nsca;

use_ok( 'POE::Component::Server::NSCA' );

use Socket;
use POE qw(Wheel::Run);

my $poco = POE::Component::Server::NSCA->spawn(
	address => '127.0.0.1',
	port => 0,
	time_out => 10,
	password => 'moocow',
	encryption => 1,
	options => { trace => 0 },
);

isa_ok( $poco, 'POE::Component::Server::NSCA' );

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_stop
			_alert
			_wheel_end
			_wheel_out
			_wheel_flush
			_sig_child
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $port = ( unpack_sockaddr_in $poco->getsockname() )[0];
  $kernel->call( $poco->session_id(), 'register', { event => '_alert' } );
  $heap->{wheel} = POE::Wheel::Run->new(
	Program => $send_nsca,
	ProgramArgs => [ '-H localhost', "-p $port", '-c send_nsca.cfg' ],
	CloseEvent => '_wheel_end',
	ErrorEvent => '_wheel_end',
	StdinEvent => '_wheel_flush',
	StdoutEvent => '_wheel_out',
	StderrEvent => '_wheel_out',
  );
  $kernel->sig_child( $heap->{wheel}->PID(), '_sig_child' );
  $heap->{wheel}->put( join "\t", 'bovine', 'chews', '0', 'Chewing okay' );
  return;
}

sub _sig_child {
  return $poe_kernel->sig_handled();
}

sub _wheel_flush {
  $_[HEAP]->{wheel}->shutdown_stdin();
  return;
}

sub _wheel_end {
  delete $_[HEAP]->{wheel};
  return;
}

sub _wheel_out {
  diag( $_[ARG0], "\n" );
  return;
}

sub _stop {
  pass("Everything went away");
  return;
}

sub _alert {
  my ($kernel,$result) = @_[KERNEL,ARG0];
  
  ok( $result->{'plugin_output'} eq 'Chewing okay', 'Chewing okay' );
  ok( $result->{'version'} == 3, 'Right version number' );
  ok( $result->{'return_code'} == 0, 'Return code is fine' );
  ok( $result->{'svc_description'} eq 'chews', 'svc description' );
  ok( $result->{'host_name'} eq 'bovine', 'Hostname is okay' );
  TODO: {
	  local $TODO = 'Vaguely flakey on some platforms';
          ok( $result->{'checksum'} == $result->{'crc32'}, 'Checksum was okay' );
  }
  $poco->shutdown();
  return;
}
