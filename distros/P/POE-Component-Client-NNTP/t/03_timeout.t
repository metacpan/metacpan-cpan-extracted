use strict;
use warnings;
use Test::More tests => 7;

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
	nntp_215	=> \&nntp_215,
	nntp_registered => \&nntp_registered,
	#nntp_205	=> \&server_shutdown,
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

    my $nntp = POE::Component::Client::NNTP->spawn ( 'NNTP-Client' => { NNTPServer => '127.0.0.1', Port => $our_port, TimeOut => 10 } );

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
    pass("Okay we got a terminate");
    $_[KERNEL]->delay ( 'close_all' => undef );
    $_[HEAP]->{server}->shutdown();
    $_[KERNEL]->post ( 'NNTP-Client' => 'shutdown' );
    undef;
}

sub client_input {
    my ( $heap, $id, $input ) = @_[ HEAP, ARG0, ARG1 ];
    pass("LIST cmd");
    diag("Waiting for timeout\n");
    undef;
}

sub nntp_200 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post ( 'NNTP-Client' => 'list' );
  pass("Connected");
  undef;
}

