use Test::More tests => 15;

BEGIN {	use_ok( 'POE::Component::Client::NSCA' ) };

use Socket;
use POE qw(Wheel::SocketFactory Filter::Stream);
use Data::Dumper;

my $encryption = 0;

my $message = {
                host_name => 'bovine',
                return_code => 0,
                plugin_output => 'The cow went moo',
};

POE::Session->create(
  package_states => [
	'main' => [qw(
			_start 
			_stop
			_server_error 
			_server_accepted 
			_response 
			_client_error 
			_client_input
			_client_flush
	)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{factory} = POE::Wheel::SocketFactory->new(
	BindAddress => '127.0.0.1',
        SuccessEvent => '_server_accepted',
        FailureEvent => '_server_error',
  );
  my $port = ( unpack_sockaddr_in $heap->{factory}->getsockname() )[0];

  my $check = POE::Component::Client::NSCA->send_nsca( 
	host  => '127.0.0.1',
        port  => $port,
        event => '_response',
        password => 'cow',
        encryption => $encryption,
        context => { thing => 'moo' },
        message => $message,

  );

  isa_ok( $check, 'POE::Component::Client::NSCA' );

  return;
}

sub _stop {
  pass('Everything stopped okay');
  return;
}

sub _response {
  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  delete $heap->{factory};
  ok( $res->{success}, 'Success!' );
  ok( ( $res->{message} and ref $res->{message} eq 'HASH' ), 'Message was okay' );
  ok( $res->{context}, 'Got the context' );
  ok( $res->{host}, 'Got host back' );
  return;
}

sub _server_error {
  die "Shit happened\n";
}

sub _server_accepted {
  my ($kernel,$heap,$socket) = @_[KERNEL,HEAP,ARG0];
  my $wheel = POE::Wheel::ReadWrite->new(
	Handle => $socket,
	Filter => POE::Filter::Stream->new(),
	InputEvent => '_client_input',
        ErrorEvent => '_client_error',
	FlushedEvent => '_client_flush',
  );
  $heap->{clients}->{ $wheel->ID() } = $wheel;
  pass('Connection from client');
  my $init_packet;
  $heap->{ts} = time();
  srand( $heap->{ts} );
  $init_packet .= int rand(10) for 0 .. 127;
  $init_packet .= pack 'N', $heap->{ts};
  $wheel->put( $init_packet );
  return;
}

sub _client_flush {
  my ($heap,$wheel_id) = @_[HEAP,ARG0];
  return;
}

sub _client_error {
  my ( $heap, $wheel_id ) = @_[ HEAP, ARG3 ];
  delete $heap->{clients}->{$wheel_id};
  return;
}

sub _client_input {
  my ($kernel,$heap,$input,$wheel_id) = @_[KERNEL,HEAP,ARG0,ARG1];
  my $version = unpack 'n', substr $input, 0, 4;
  my $crc32 = unpack 'N', substr $input, 4, 4;
  my $ts = unpack 'N', substr $input, 8, 4;
  my $rc = unpack 'n', substr $input, 12, 2;
  my $firstbit = substr $input, 0, 4;
  my $secondbit = substr $input, 8;
  my $checksum = _calculate_crc32( $firstbit . pack('N', 0) . $secondbit );
  TODO: {
	local $TODO = 'Vaguely flakey on some platforms';
        ok( $checksum == $crc32, 'Checksum matches' ) 
		or diag("Expected '$checksum', but got '$crc32' instead\n");
  }
  ok( $version == 3, 'Version okay' );
  ok( $ts == $heap->{ts}, 'Timestamp okay' );
  ok( $rc == $message->{return_code}, 'Return code fine' );
  my @data = unpack 'a[64]a[128]a[512]', substr $input, 12;
  s/\000//g for @data;
  my ($host,$svc,$output) = @data;
  ok( $host eq $message->{host_name}, 'Hostname' ) or diag("Expected '" . $message->{host_name} . "' but got '$host'");
  ok( $svc eq '', 'Service Description' );
  ok( $output eq $message->{plugin_output}, 'Plugin Output' );
  return;
}

#/* calculates the CRC 32 value for a buffer */
sub _calculate_crc32 {
        my $string = shift;

        my $crc32_table = _generate_crc32_table();
        my $crc = 0xFFFFFFFF;

        foreach my $tchar (split(//, $string)) {
                my $char = ord($tchar);
                $crc = (($crc >> 8) & 0x00FFFFFF) ^ $crc32_table->[($crc ^ $char) & 0xFF];
        }

        return ($crc ^ 0xFFFFFFFF);
}

#/* build the crc table - must be called before calculating the crc value */
sub _generate_crc32_table {
        my $crc32_table = [];
        my $poly = 0xEDB88320;

        for (my $i = 0; $i < 256; $i++){
                my $crc = $i;
                for (my $j = 8; $j > 0; $j--) {
                        if ($crc & 1) {
                                $crc = ($crc >> 1) ^ $poly;
                        } else {
                                $crc = ($crc >> 1);
                        }
                }
                $crc32_table->[$i] = $crc;
        }
        return $crc32_table;
}
