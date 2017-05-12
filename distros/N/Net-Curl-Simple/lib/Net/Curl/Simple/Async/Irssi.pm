package Net::Curl::Simple::Async::Irssi;

use strict;
use Irssi ();

our @ISA;

sub _init {
   my $pkg = caller;

   push @ISA, $pkg;

   local $/;
   eval "package $pkg; " . <DATA>;
   print __PACKAGE__ . " compilation error: $@" if $@;

   close DATA;
}

Irssi::command( "/script exec -permanent " . __PACKAGE__ . "::_init()" );

1;

__DATA__

use strict;
use Irssi ();
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
	if ( exists $multi->{ "io$socket" } ) {
		Irssi::input_remove( delete $multi->{ "io$socket" } );
	}

	my $cond = 0;
	my $action = 0;
	if ( $poll == CURL_POLL_IN ) {
		$cond = Irssi::INPUT_READ();
		$action = CURL_CSELECT_IN;
	} elsif ( $poll == CURL_POLL_OUT ) {
		$cond = Irssi::INPUT_WRITE();
		$action = CURL_CSELECT_OUT;
	} elsif ( $poll == CURL_POLL_INOUT ) {
		$cond = Irssi::INPUT_READ() | Irssi::INPUT_WRITE();
		# we don't know whether it can read or write,
		# so let libcurl figure it out
		$action = 0;
	} else {
		return 1;
	}

	$multi->{ "io$socket" } = Irssi::input_add( $socket, $cond,
		sub { $multi->socket_action( $socket, $action ); },
		'' );

	return 1;
}


sub _cb_timer
{
	my ( $multi, $timeout_ms ) = @_;

	# deregister old timer
	if ( exists $multi->{timer} ) {
		Irssi::timeout_remove( delete $multi->{timer} );
	}

	my $cb = sub {
		$multi->socket_action(
			Net::Curl::Multi::CURL_SOCKET_TIMEOUT
		);
	};

	if ( $timeout_ms < 0 ) {
		if ( $multi->handles ) {
			# we don't know what the timeout is
			$multi->{timer} = Irssi::timeout_add( 10000, $cb, '' );
		}
	} else {
		# Irssi won't allow smaller timeouts
		$timeout_ms = 10 if $timeout_ms < 10;
		$multi->{timer} = Irssi::timeout_add_once(
			$timeout_ms, $cb, ''
		);
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

# perform and call any callbacks that have finished
sub socket_action
{
	my $multi = shift;

	my $active = $multi->SUPER::socket_action( @_ );
	return if $multi->{active} == $active;

	$multi->{active} = $active;

	while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {
		if ( $msg == Net::Curl::Multi::CURLMSG_DONE ) {
			$multi->remove_handle( $easy );
			$easy->_finish( $result );
		} else {
			die "I don't know what to do with message $msg.\n";
		}
	}
}

sub get_one
{
	warn __PACKAGE__ . " does not support blocking\n";
	return;
}

1;
