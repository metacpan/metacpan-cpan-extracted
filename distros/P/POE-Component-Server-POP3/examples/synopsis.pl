  # A simple POP3 Server that demonstrates functionality
  use strict;
  use Socket;
  use POE;
  use POE::Component::Server::POP3

  POE::Session->create(
	package_states => [
	  'main' => [qw(
			_start
			pop3d_registered
			pop3d_connection
			pop3d_disconnected
			pop3d_cmd_quit
			pop3d_cmd_user
			pop3d_cmd_pass
			pop3d_cmd_stat
			pop3d_cmd_list
			pop3d_cmd_noop
	  )],
	],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    $_[HEAP]->{pop3d} = POE::Component::Server::POP3->spawn(
	hostname => 'pop.foobar.com',
	port => 0,
    );
    return;
  }

  sub pop3d_registered {
    # Successfully started pop3d
    my $port = ( sockaddr_in( $_[ARG0]->getsockname() ) )[0];
    warn "Listening on port $port\n";
    return;
  }

  sub pop3d_connection {
    my ($heap,$id) = @_[HEAP,ARG0];
    $heap->{clients}->{ $id } = { auth => 0 };
    return;
  }

  sub pop3d_disconnected {
    my ($heap,$id) = @_[HEAP,ARG0];
    delete $heap->{clients}->{ $id };
    return;
  }

  sub pop3d_cmd_quit {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '+OK POP3 server signing off' );
	return;
    }
    # Process mailbox in some way
    $heap->{pop3d}->send_to_client( $id, '+OK POP3 server signing off' );
    return;
  }

  sub pop3d_cmd_user {
    my ($heap,$id) = @_[HEAP,ARG0];
    my $user = ( split /\s+/, $_[ARG1] )[0];
    unless ( $user ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Missing username argument' );
	return;
    }
    $heap->{clients}->{ $id }->{user} = $user;
    $heap->{pop3d}->send_to_client( $id, '+OK User name accepted, password please' );
    return;
  }

  sub pop3d_cmd_pass {
    my ($heap,$id) = @_[HEAP,ARG0];
    my $pass = ( split /\s+/, $_[ARG1] )[0];
    unless ( $pass ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Missing password argument' );
	return;
    }
    $heap->{clients}->{ $id }->{pass} = $pass;
    # Check the password
    $heap->{clients}->{ $id }->{auth} = 1;
    $heap->{pop3d}->send_to_client( $id, '+OK Mailbox open, 0 messages' );
    return;
  }

  sub pop3d_cmd_stat {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK 0 0' );
    return;
  }

  sub pop3d_cmd_noop {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK No-op to you too!' );
    return;
  }

  sub pop3d_cmd_list {
    my ($heap,$id) = @_[HEAP,ARG0];
    unless ( $heap->{clients}->{ $id }->{auth} ) {
	$heap->{pop3d}->send_to_client( $id, '-ERR Unknown AUTHORIZATION state command' );
	return;
    }
    $heap->{pop3d}->send_to_client( $id, '+OK Mailbox scan listing follows' );
    $heap->{pop3d}->send_to_client( $id, '.' );
    return;
  }
