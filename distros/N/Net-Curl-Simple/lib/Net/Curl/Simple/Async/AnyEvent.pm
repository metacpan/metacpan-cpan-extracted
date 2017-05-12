package Net::Curl::Simple::Async::AnyEvent;

use strict;
use warnings;
use AnyEvent;
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

	return $multi;
}


sub _cb_socket
{
	my ( $multi, $easy, $socket, $poll ) = @_;

	# deregister old io events
	delete $multi->{ "r$socket" };
	delete $multi->{ "w$socket" };

	# register read event
	if ( $poll == CURL_POLL_IN or $poll == CURL_POLL_INOUT ) {
		$multi->{ "r$socket" } = AE::io $socket, 0, sub {
			socket_action( $multi, $socket, CURL_CSELECT_IN );
		};
	}

	# register write event
	if ( $poll == CURL_POLL_OUT or $poll == CURL_POLL_INOUT ) {
		$multi->{ "w$socket" } = AE::io $socket, 1, sub {
			socket_action( $multi, $socket, CURL_CSELECT_OUT );
		};
	}

	return 1;
}


sub _cb_timer
{
	my ( $multi, $timeout_ms ) = @_;

	# deregister old timer
	delete $multi->{timer};

	my $cb = sub {
		$multi->socket_action(
			Net::Curl::Multi::CURL_SOCKET_TIMEOUT
		);
	};

	if ( $timeout_ms < 0 ) {
		if ( $multi->handles ) {
			$multi->{timer} = AE::timer 1, 1, $cb;
		}
	} else {
		# This will trigger timeouts if there are any.
		$multi->{timer} = AE::timer $timeout_ms / 1000, 0, $cb;
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
			my $ecv = delete $easy->{cv};
			my $mcv = delete $multi->{cv};

			$multi->remove_handle( $easy );
			$easy->_finish( $result );

			$ecv->send( $easy ) if $ecv;
			$mcv->send( $easy ) if $mcv;
		} else {
			die "I don't know what to do with message $msg.\n";
		}
	}
}

# perform and call any callbacks that have finished
sub socket_action
{
	my $multi = shift;

	my $active = $multi->SUPER::socket_action( @_ );
	return if $multi->{active} == $active;

	$multi->{active} = $active;

	_rip_child( $multi );
}

sub get_one
{
	my ( $multi, $easy ) = @_;

	my $cv = AE::cv;
	if ( $easy ) {
		$easy->{cv} = $cv;
	} else {
		return undef unless $multi->handles;
		$multi->{cv} = $cv;
	}

	# _rip_child( $multi );
	return $cv->recv;
}

1;
