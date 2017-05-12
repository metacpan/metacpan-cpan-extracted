package Net::Curl::Simple::Async::Select;

use strict;
use warnings;
use Net::Curl::Multi;
use base qw(Net::Curl::Multi);
BEGIN {
	no strict 'refs';
	if ( defined ${ 'Coro::VERSION' } ) {
		require Coro::Select;
		Coro::Select->import( 'select' );
	}
}

sub _rip_child($$)
{
	my ( $multi, $needle ) = @_;

	while ( my ( $msg, $easy, $result ) = $multi->info_read() ) {
		if ( $msg == Net::Curl::Multi::CURLMSG_DONE ) {
			$multi->remove_handle( $easy );
			$easy->_finish( $result );

			if ( not $needle or $needle == $easy ) {
				return $easy;
			}
		} else {
			die "I don't know what to do with message $msg.\n";
		}
	}
	return undef;
}

sub _loop($$)
{
	my ( $multi, $needle ) = @_;

	my $active = $multi->handles;

	while ( $active ) {
		my $t = $multi->timeout;
		if ( $t != 0 ) {
			$t = 10000 if $t < 0;
			my ( $r, $w, $e ) = $multi->fdset;

			select $r, $w, $e, $t / 1000;
		}

		my $ret = $multi->perform();
		if ( $active != $ret ) {
			$ret = _rip_child( $multi, $needle );
			return $ret if $ret;
			$active = $multi->handles;
		}
	};

	return;
}

sub get_one
{
	my ( $multi, $easy ) = @_;

	my $ret = _rip_child( $multi, $easy );
	return $ret if $ret;

	return _loop( $multi, $easy );
}


1;

# vim: ts=4:sw=4
