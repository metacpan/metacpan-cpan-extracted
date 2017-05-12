use Test::More tests => 12;

use Socket;
use POE qw(Filter::Line);
use Test::POE::Server::TCP;
use_ok('POE::Component::Client::NNTP');

POE::Session->create
  ( inline_states =>
      { _start => \&server_start,
	_stop  => \&server_stop,
	testd_registered      => \&testd_registered,
	testd_connected	      => \&testd_connected,
        testd_client_input    => \&client_input,
	close_all	=> \&server_shutdown,
	nntp_200	=> \&nntp_200,
	nntp_211	=> \&nntp_211,
	nntp_registered => \&nntp_registered,
	nntp_disconnected	=> \&server_shutdown,
      },
      options => { trace => 0 },
  );

POE::Kernel->run();
exit 0;

sub server_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    $heap->{server} = Test::POE::Server::TCP->spawn
      (
	address => '127.0.0.1',
      );
     return;
}

sub testd_registered {
    my ($kernel,$testd) = @_[KERNEL,ARG0];

    my $our_port = $testd->port();

    diag("Listening on port: $our_port\n");

    my $nntp = POE::Component::Client::NNTP->spawn ( 'NNTP-Client' => { NNTPServer => '127.0.0.1', Port => $our_port } );

    isa_ok( $nntp, 'POE::Component::Client::NNTP' );

    $kernel->delay ( 'close_all' => 60 );
    undef;
}

sub nntp_registered {
  my ($kernel,$sender,$nntp) = @_[KERNEL,SENDER,ARG0];
  isa_ok( $nntp, 'POE::Component::Client::NNTP' );
  $kernel->post( $sender, 'connect' );
  undef;
}

sub server_stop {
   pass("Everything went away");
   undef;
}

sub testd_connected {
   my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
   $heap->{server}->send_to_client( $id, "200 server ready - posting allowed" );
   return;
}

sub server_shutdown {
    $_[KERNEL]->delay ( 'close_all' => undef );
    $_[HEAP]->{server}->shutdown();
    $_[KERNEL]->post ( 'NNTP-Client' => 'shutdown' );
    undef;
}

sub client_input {
    my ( $heap, $id, $input ) = @_[ HEAP, ARG0, ARG1 ];

    diag("$input\n");

    # Quick and dirty parsing as we know it is our component connecting
    SWITCH: {
      if ( $input =~ /^GROUP/i ) {
	      $heap->{server}->send_to_client( $id, '211 2000 3000234 3002322 perl.poe' );
	      pass("GROUP cmd");
        last SWITCH;
      }
      if ( $input =~ /^LISTGROUP/i ) {
        $heap->{server}->send_to_client( $id,
          [ '211 2000 3000234 3002322 perl.poe list follows', qw(3000234 3000237 3000328 3000329 3002322), '.' ] );
	      pass("LISTGROUP cmd");
	      last SWITCH;
      }
      if ( $input =~ /^QUIT/i ) {
	$heap->{server}->disconnect( $id );
	$heap->{server}->send_to_client( $id, '205 closing connection - goodbye!' );
	pass("QUIT cmd");
	last SWITCH;
      }
    }
    undef;
}

sub nntp_200 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post ( 'NNTP-Client' => 'group' => 'perl.poe');
  $heap->{cmd} = 'GROUP';
  pass("Connected");
  undef;
}

sub nntp_211 {
  my ($kernel,$heap,$text,$list) = @_[KERNEL,HEAP,ARG0,ARG1];
  if ( $heap->{cmd} eq 'GROUP' ) {
    ok( !defined $list, 'ARG1 is not defined for GROUP' );
    $kernel->post ( 'NNTP-Client' => 'listgroup' => 'perl.poe' );
    $heap->{cmd} = 'LISTGROUP';
    return;
  }
  if ( $heap->{cmd} eq 'LISTGROUP' ) {
    ok( defined $list, 'ARG1 is defined' );
    is( ref $list, 'ARRAY', 'ARG1 is an arrayref' );
    is( scalar @$list, 5, 'ARG1 contains 5 items' );
    $kernel->post ( 'NNTP-Client' => 'quit' );
    return;
  }
  undef;
}
