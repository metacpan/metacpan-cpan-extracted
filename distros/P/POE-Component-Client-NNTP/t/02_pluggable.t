use Test::More tests => 18;

{
  package TestPlugin;
  use Test::More;
  use POE::Component::Client::NNTP::Constants qw(:ALL);

  sub new {
    return bless { }, shift;
  }

  sub plugin_register {
    my ($self,$nntp) = @_;
    ok( $nntp->plugin_register( $self, 'NNTPSERVER', qw(all) ), 'plugin_register' );
    ok( $nntp->plugin_register( $self, 'NNTPCMD', qw(all) ), 'plugin_register' );
    return 1;
  }

  sub plugin_unregister {
    pass('plugin_unregister');
    return 1;
  }

  sub NNTPSERVER_200 {
    pass('NNTPSERVER_200');
    return NNTP_EAT_NONE;
  }

  sub NNTPSERVER_215 {
    pass('NNTPSERVER_215');
    return NNTP_EAT_NONE;
  }

  sub NNTPSERVER_205 {
    pass('NNTPSERVER_205');
    return NNTP_EAT_NONE;
  }

  sub NNTPCMD_quit {
    pass('NNTPCMD_quit');
    return NNTP_EAT_NONE;
  }
  sub NNTPCMD_list {
    pass('NNTPCMD_list');
    return NNTP_EAT_NONE;
  }

}

use Socket;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite);

require_ok('POE::Component::Client::NNTP');

POE::Session->create
  ( inline_states =>
      { _start => \&server_start,
	_stop  => \&server_stop,
        server_accepted => \&server_accepted,
        server_error    => \&server_error,
        client_input    => \&client_input,
        client_error    => \&client_error,
	client_flush    => \&client_flushed,
	close_all	=> \&server_shutdown,
	nntp_200	=> \&nntp_200,
	nntp_215	=> \&nntp_215,
	nntp_registered => \&nntp_registered,
	nntp_plugin_add => \&nntp_plugin_add,
	nntp_plugin_del => \&nntp_plugin_del,
	#nntp_205	=> \&server_shutdown,
	nntp_disconnected	=> \&server_shutdown,
      },
      options => { trace => 0 },
  );

POE::Kernel->run();
exit 0;

sub server_start {
    my ($our_port);

    $_[HEAP]->{server} = POE::Wheel::SocketFactory->new
      (
	BindAddress => '127.0.0.1',
        SuccessEvent => "server_accepted",
        FailureEvent => "server_error",
      );

    ($our_port, undef) = unpack_sockaddr_in( $_[HEAP]->{server}->getsockname );

    my $nntp = POE::Component::Client::NNTP->spawn ( 'NNTP-Client' => { NNTPServer => 'localhost', Port => $our_port }, trace => 0 );

    isa_ok( $nntp, 'POE::Component::Client::NNTP' );

    $_[KERNEL]->post( 'NNTP-Client', 'register', 'all' );
    $_[KERNEL]->post( 'NNTP-Client', 'connect' );

    $_[KERNEL]->delay ( 'close_all' => 60 );
    undef;
}

sub nntp_registered {
  my ($kernel,$sender,$nntp) = @_[KERNEL,SENDER,ARG0];
  isa_ok( $nntp, 'POE::Component::Client::NNTP' );
  $nntp->plugin_add( 'TestPlugin', TestPlugin->new() );
  undef;
}

sub nntp_plugin_add {
  my ($kernel,$sender,$plugin) = @_[KERNEL,SENDER,ARG1];
  isa_ok( $plugin, 'TestPlugin' );
  return;
}

sub nntp_plugin_del {
  my ($kernel,$sender,$plugin) = @_[KERNEL,SENDER,ARG1];
  isa_ok( $plugin, 'TestPlugin' );
  return;
}

sub server_stop {
   undef;
}

sub server_accepted {
    my $client_socket = $_[ARG0];

    my $wheel = POE::Wheel::ReadWrite->new
      ( Handle => $client_socket,
        InputEvent => "client_input",
        ErrorEvent => "client_error",
	FlushedEvent => "client_flush",
	Filter => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
      );
    $_[HEAP]->{client}->{ $wheel->ID() } = $wheel;

    $wheel->put("200 server ready - posting allowed");
    undef;
}

sub server_error {
    delete $_[HEAP]->{server};
}

sub server_shutdown {
    $_[KERNEL]->delay ( 'close_all' => undef );
    delete $_[HEAP]->{server};
    $_[KERNEL]->post ( 'NNTP-Client' => 'shutdown' );
    undef;
}

sub client_input {
    my ( $heap, $input, $wheel_id ) = @_[ HEAP, ARG0, ARG1 ];

    # Quick and dirty parsing as we know it is our component connecting
    SWITCH: {
      if ( $input =~ /^LIST/i ) {
	$heap->{client}->{$wheel_id}->put("215 list of newsgroups follows");
	$heap->{client}->{$wheel_id}->put("perl.poe 0 1 y");
	$heap->{client}->{$wheel_id}->put(".");
	pass("LIST cmd");
	last SWITCH;
      }
      if ( $input =~ /^QUIT/i ) {
	$heap->{client}->{$wheel_id}->put("205 closing connection - goodbye!");
	$heap->{quiting}->{$wheel_id} = 1;
	pass("QUIT cmd");
	last SWITCH;
      }
    }
    undef;
}

sub client_error {
    my ( $heap, $wheel_id ) = @_[ HEAP, ARG3 ];
    delete $heap->{client}->{$wheel_id};
    undef;
}

sub client_flushed {
    my ( $heap, $wheel_id ) = @_[ HEAP, ARG0 ];

    if ( $heap->{quiting}->{$wheel_id} ) {
	delete $heap->{quiting}->{$wheel_id};
    	delete $heap->{client}->{$wheel_id};
    }
    undef;
}

sub nntp_200 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post ( 'NNTP-Client' => 'list' );
  pass("Connected");
  undef;
}

sub nntp_215 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post ( 'NNTP-Client' => 'quit' );
  pass("Got a list back");
  undef;
}
