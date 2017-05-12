use Test::More tests => 18;

{
  package TestPlugin;
  use strict;
  use Test::More;
  
  sub new {
    my $package = shift;
    return bless { @_ }, $package;
  }

  sub plugin_register {
    my ($self,$nntpd) = @_;
    $nntpd->plugin_register( $self, 'NNTPD', qw(all) );
    $nntpd->plugin_register( $self, 'NNTPC', qw(all) );
    pass('plugin_register');
    return 1;
  }

  sub plugin_unregister {
    pass('plugin_unregister');
    return 1;
  }

  sub NNTPD_connection {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $id = ${ $_[0] };
    pass('NNTPD_connection');
    $nntpd->send_to_client( $id, '200 localhost - poe-nntpd 1.0 ready - (posting ok).' );
    return 1;
  }

  sub NNTPD_disconnected {
    pass('NNTPD_disconnected');
    return 1;
  }

  sub NNTPC_response {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $text = ${ $_[1] };
    pass('Plugin: ' . $text);
    return 1;
  }

  sub NNTPD_cmd_xfubar {
    my ($self,$nntpd) = splice @_, 0, 2;
    my $id = ${ $_[0] };
    pass('nntpd_xfubar');
    $nntpd->send_to_client( $id, '285 Fubar to you too' );
    return 1;
  }

}

use strict;
use POE qw(Wheel::SocketFactory Component::Client::NNTP);
use Socket;

require_ok('POE::Component::Server::NNTP');

POE::Session->create(
	inline_states => { _start => \&test_start, },
	package_states => [
		'main' => [qw(_failure 
			      _config_nntpd 
			      _shutdown 
			      nntpd_plugin_add
			      nntpd_plugin_del
			      nntpd_connection
			      nntpd_disconnected
			      nntpd_cmd_xfubar
			      nntp_connected
			      nntp_200
			      nntp_285
			      nntpd_registered)],
	],
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  my $wheel = POE::Wheel::SocketFactory->new(
	BindAddress => '127.0.0.1',
	BindPort => 0,
	SuccessEvent => '_fake_success',
	FailureEvent => '_failure',
  );

  if ( $wheel ) {
	my $port = ( unpack_sockaddr_in( $wheel->getsockname ) )[0];
	$kernel->yield( '_config_nntpd' => $port );
	$wheel = undef;
	$kernel->delay( '_shutdown' => 60 );
	return;
  }
  return;
}

sub _failure {
  die "Couldn\'t allocate a listening port, giving up\n";
  return;
}

sub _shutdown {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->alarm_remove_all();
  $kernel->post( 'nntpd', 'shutdown' );
  $kernel->post( 'nntp-client', 'shutdown' );
  return;
}

sub _config_nntpd {
  my ($kernel,$heap,$port) = @_[KERNEL,HEAP,ARG0];
  my $poco = POE::Component::Server::NNTP->spawn( 
	alias => 'nntpd', 
	address => '127.0.0.1',
	port => $port,
	handle_connects => 0,
	extra_cmds => [qw(XFUBAR)],
	options => { trace => 0 },
  );
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  $heap->{port} = $port;
  return;
}

sub nntpd_registered {
  my ($kernel,$heap,$poco) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $poco, 'POE::Component::Server::NNTP' );
  isa_ok( $poco, 'POE::Component::Pluggable' );
  ok( $poco->plugin_add( 'TestPlugin', TestPlugin->new() ), 'Plugin add TestPlugin' );
  POE::Component::Client::NNTP->spawn( 'nntp-client', { NNTPServer => '127.0.0.1', Port => $heap->{port} }, trace => 0 );
  $kernel->post( 'nntp-client', 'register', 'all' );
  $kernel->post( 'nntp-client', 'connect' );
  return;
}

sub nntpd_plugin_add {
  isa_ok( $_[ARG1], 'TestPlugin' );
  return;
}

sub nntpd_plugin_del {
  isa_ok( $_[ARG1], 'TestPlugin' );
  return;
}

sub nntpd_connection {
  pass("Client connected");
  return;
}

sub nntpd_cmd_xfubar {
  pass($_[STATE]);
  return;
}
sub nntpd_disconnected {
  pass("Client disconnected");
  $poe_kernel->yield( '_shutdown' );
  return;
}

sub nntp_connected {
  pass('nntp-client connected');
  return;
}

sub nntp_200 {
  my ($kernel,$sender,$text) = @_[KERNEL,SENDER,ARG0];
  warn "# 200 $text\n";
  pass($_[STATE]);
  $kernel->post( 'nntp-client', 'send_cmd', 'xfubar' );
  return;
}

sub nntp_285 {
  pass($_[STATE]);
  $poe_kernel->yield( '_shutdown' );
  return;
}
