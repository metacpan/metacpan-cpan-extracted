package Net::Curl::Simple::Async::CoroEV;

use strict;
use warnings;
use Coro::EV;
use Coro::Signal;
use Net::Curl::Multi qw(/^CURL_POLL_/ /^CURL_CSELECT_/);
use base qw(Net::Curl::Multi);

BEGIN {
	if ( not Net::Curl::Multi->can( 'CURLMOPT_TIMERFUNCTION' ) ) {
		die "Net::Curl::Multi is missing timer callback,\n" .
			"rebuild Net::Curl with libcurl 7.16.0 or newer\n";
	}

	# make sure those constants match, so we won't have to do any conversions
	if ( EV::READ != CURL_CSELECT_IN or EV::WRITE != CURL_CSELECT_OUT
			or CURL_CSELECT_IN != CURL_POLL_IN
			or CURL_CSELECT_OUT != CURL_POLL_OUT
			or ( CURL_CSELECT_IN | CURL_CSELECT_OUT ) != CURL_POLL_INOUT
			) {
		die "Expected EV::READ == CURL_CSELECT_IN and " .
			"EV::WRITE == CURL_CSELECT_OUT\n";
	}
}

use constant {
	CONDVAR => 0,
	ACTIVE => 1,
	TIMER => 2,
	LAST_EASY => 3,
};

sub new
{
	my $class = shift;

	my $multi = $class->SUPER::new( [ undef, -1, undef ] );

	$multi->setopt( Net::Curl::Multi::CURLMOPT_SOCKETFUNCTION,
		\&_cb_socket );
	$multi->setopt( Net::Curl::Multi::CURLMOPT_TIMERFUNCTION,
		\&_cb_timer );

	return $multi;
}


sub _cb_socket
{
	my ( $multi, $easy, $socket, $poll, $watcher ) = @_;

	if ( $poll == CURL_POLL_REMOVE ) {
		# delete the watcher
		$multi->assign( $socket )
			if $watcher;
	} else {
		if ( $watcher ) {
			$watcher->events( $poll );
		} else {
			$watcher = EV::io $socket, $poll, sub {
				socket_action( $multi, $socket, $_[1] );
			};
			$multi->assign( $socket, $watcher );
		}
	}

	return 1;
}


sub _cb_timer
{
	my ( $multi, $timeout_ms ) = @_;

	my $t = $multi->[ TIMER ] ||= EV::timer 10, 10, sub {
		socket_action( $multi );
	};

	if ( $timeout_ms < 0 ) {
		if ( $multi->handles ) {
			$t->set( 10, 10 );
		} else {
			$multi->[ TIMER ] = undef;
		}
	} else {
		# This will trigger timeouts if there are any.
		$t->set( $timeout_ms / 1000, 10 );
	}

	return 1;
}

sub add_handle($$)
{
	my $multi = shift;
	my $easy = shift;

	$multi->[ ACTIVE ] = -1;
	$multi->SUPER::add_handle( $easy );
}

sub _rip_child
{
	my $multi = shift;

	while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {
		if ( $msg == Net::Curl::Multi::CURLMSG_DONE ) {
			my $ecv = delete $easy->{cv};
			my $mcv = $multi->[ CONDVAR ];
			$multi->[ CONDVAR ] = undef;

			$multi->remove_handle( $easy );
			$easy->_finish( $result );

			$ecv->broadcast if $ecv;
			if ( $mcv ) {
				$multi->[ LAST_EASY ] = $easy;
				$mcv->broadcast;
			}
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
	return if $multi->[ ACTIVE ] == $active;

	$multi->[ ACTIVE ] = $active;

	_rip_child( $multi );

	$multi->[ TIMER ] = undef
		unless $multi->[ ACTIVE ];
}

sub get_one
{
	my ( $multi, $easy ) = @_;

	my $cv = Coro::Signal->new;
	if ( $easy ) {
		$easy->{cv} = $cv;
		_rip_child( $multi );
		$cv->wait;
		return $easy;
	} else {
		return undef unless $multi->handles;
		$multi->[ CONDVAR ] = $cv;
		_rip_child( $multi );
		$cv->wait;
		$easy = $multi->[ LAST_EASY ];
		$multi->[ LAST_EASY ] = undef;
		return $easy;
	}
}

1;
