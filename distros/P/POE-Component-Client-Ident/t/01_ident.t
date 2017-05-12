use Test::More tests => 6;
use Socket;
use POE qw(Filter::Line);
use Test::POE::Server::TCP;

use_ok('POE::Component::Client::Ident');

my $self = POE::Component::Client::Ident->spawn ( 'Ident-Client' );

isa_ok( $self, 'POE::Component::Client::Ident' );

POE::Session->create
  ( inline_states =>
      { _start => \&server_start,
	_stop  => \&server_stop,
	testd_registered => \&_testd_registered,
        testd_connected => \&server_accepted,
        testd_client_input    => \&client_input,
        testd_disconnect    => \&client_error,
	close_all	=> \&close_down_server,
	ident_client_reply => \&ident_client_reply,
	ident_client_error => \&ident_client_error,
      },
    heap => { Port1 => 12345, Port2 => 123, UserID => 'bingos' },
  );

$poe_kernel->run();
exit 0;

sub server_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{testd} = Test::POE::Server::TCP->spawn( 
        address => '127.0.0.1',
        port => 0,
	filter => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
    );
    $kernel->delay ( 'close_all' => 60 );
    undef;
}

sub server_stop {
  pass("Server stop");
  undef;
}

sub close_down_server {
  $poe_kernel->call ( 'Ident-Client' => 'shutdown' );
  $_[HEAP]->{testd}->shutdown();
  undef;
}

sub _testd_registered {
  my ($kernel,$heap,$testd) = @_[KERNEL,HEAP,ARG0];
  my $port = $testd->port();
  diag("Listening on port: $port\n");
  $kernel->post( 
		'Ident-Client', 
		'query', 
		'IdentPort', $port, 
		'PeerAddr', '127.0.0.1', 
		'PeerPort', $heap->{Port1}, 
		'SockAddr', '127.0.0.1', 
		'SockPort', $heap->{Port2},
  );
  return;
}

sub server_accepted {
    pass($_[STATE]);
    undef;
}

sub client_input {
    my ( $heap, $id, $input ) = @_[ HEAP, ARG0, ARG1 ];
     
    # Quick and dirty parsing as we know it is our component connecting
    my ($port1,$port2) = split ( /\s*,\s*/, $input );
    if ( $port1 == $heap->{Port1} and $port2 == $heap->{Port2} ) {
      $heap->{testd}->send_to_client( $id, "$port1 , $port2 : USERID : UNIX : " . $heap->{UserID} );
      pass("Correct response from client");
    } 
    else {
      $heap->{testd}->send_to_client( $id, "$port1 , $port2 : ERROR : UNKNOWN-ERROR");
    }
    undef;
}

sub client_error {
    pass($_[STATE]);
    undef;
}

sub server_error {
    delete $_[HEAP]->{server};
    undef;
}

sub ident_client_reply {
  my ($kernel,$heap,$ref,$opsys,$userid) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];
  ok( $userid eq $heap->{UserID}, "USERID Test" );
  $kernel->delay( 'close_all' => undef );
  $kernel->yield( 'close_all' );
  undef;
}

sub ident_client_error {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->delay( 'close_all' => undef );
  $kernel->yield( 'close_all' );
  undef;
}
