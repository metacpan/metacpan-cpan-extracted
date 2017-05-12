package Net::Curl::Simple::Async::POE;

use strict;
use warnings;
use POE;
use Net::Curl::Multi qw(/^CURL_POLL_/ /^CURL_CSELECT_/);
use base qw(Net::Curl::Multi);

BEGIN {
	if ( not Net::Curl::Multi->can( 'CURLMOPT_TIMERFUNCTION' ) ) {
		die "Net::Curl::Multi is missing timer callback,\n" .
			"rebuild Net::Curl with libcurl 7.16.0 or newer\n";
	}
}

sub new
{
	my $class = shift;

	my $multi = $class->SUPER::new();

	$multi->setopt( Net::Curl::Multi::CURLMOPT_SOCKETFUNCTION,
		\&_cb_socket );
	$multi->setopt( Net::Curl::Multi::CURLMOPT_TIMERFUNCTION,
		\&_cb_timer );

	$multi->{active} = -1;

	$multi->{session} = POE::Session->create( inline_states => {
		_start => sub {
			$_[KERNEL]->delay( timeout => 600 );
		},
		update => sub {
			$_[KERNEL]->delay( timeout => $_[ARG0] );
		},
		timeout => sub {
			$multi->socket_action(
				Net::Curl::Multi::CURL_SOCKET_TIMEOUT
			);
		},
		stop => sub {
			$_[KERNEL]->alarm_remove_all;
		},
	} );

	return $multi;
}


sub _cb_socket
{
	my ( $multi, $easy, $socket, $poll ) = @_;

	# deregister old io events
	if ( my $s = delete $multi->{ "r$socket" } ) {
		POE::Kernel->call( $s, "stop" );
	}
	if ( my $s = delete $multi->{ "w$socket" } ) {
		POE::Kernel->call( $s, "stop" );
	}

	# register read event
	if ( $poll == CURL_POLL_IN or $poll == CURL_POLL_INOUT ) {
   		open my $fh, '<&', $socket;
		$multi->{ "r$socket" } = POE::Session->create( inline_states => {
			_start => sub {
				$_[KERNEL]->select_read( $fh => "ready" )
			},
			ready  => sub {
				$multi->socket_action( $socket, CURL_CSELECT_IN )
			},
			stop   => sub {
				$_[KERNEL]->select_read( $fh )
			},
		} );
	}

	# register write event
	if ( $poll == CURL_POLL_OUT or $poll == CURL_POLL_INOUT ) {
   		open my $fh, '>&', $socket;
		$multi->{ "w$socket" } = POE::Session->create( inline_states => {
			_start => sub {
				$_[KERNEL]->select_write( $fh => "ready" )
			},
			ready  => sub {
				$multi->socket_action( $socket, CURL_CSELECT_OUT )
			},
			stop   => sub {
				$_[KERNEL]->select_write( $fh )
			},
		} );
	}

	return 1;
}


sub _cb_timer
{
	my ( $multi, $timeout_ms ) = @_;

	my $timer = $multi->{session};

	# deregister old timer
	if ( $timeout_ms < 0 ) {
		if ( $multi->handles ) {
			POE::Kernel->call( $timer, "update", 10 );
		} else {
			POE::Kernel->call( $timer, "stop" );
		}
	} else {
		# This will trigger timeouts if there are any.
		POE::Kernel->call( $timer, "update", $timeout_ms / 1000 );
	}

	return 1;
}

sub add_handle($$)
{
	my $multi = shift;
	my $easy = shift;

	$multi->{active} = -1;
	$multi->SUPER::add_handle( $easy );
}

sub _rip_child
{
	my $multi = shift;

	while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {
		if ( $msg == Net::Curl::Multi::CURLMSG_DONE ) {
			$multi->remove_handle( $easy );
			$easy->_finish( $result );

			if ( not $multi->{needle} or $easy == $multi->{needle} ) {
				$multi->{last_easy} = $easy;
			}
		} else {
			die "I don't know what to do with message $msg.\n";
		}
	}
}

sub socket_action
{
	my $multi = shift;

	my $active = $multi->SUPER::socket_action( @_ );
	return if $multi->{active} == $active;

	$multi->{active} = $active;

	_rip_child( $multi );

	if ( $multi->{active} == 0 ) {
		POE::Kernel->call( $multi->{session}, "stop" );
	}
}

sub get_one
{
	my ( $multi, $easy ) = @_;

	$multi->{needle} = $easy;
	delete $multi->{last_easy};
	_rip_child( $multi );

	if ( my $found = delete $multi->{last_easy} ) {
		delete $multi->{needle};
		return $found;
	}

	return undef unless $multi->handles;

	do {
		POE::Kernel->loop_do_timeslice;
	} until ( $multi->{last_easy} );

	delete $multi->{needle};
	return delete $multi->{last_easy};
}

1;
