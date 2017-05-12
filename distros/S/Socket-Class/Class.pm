package Socket::Class;
# =============================================================================
# Socket::Class - A class to communicate with sockets
# Use "perldoc Socket::Class" for documenation
# =============================================================================

# enable for debugging
#use strict;
#use warnings;
#no warnings 'uninitialized';

our( $VERSION );

BEGIN {
	$VERSION = '2.258';
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	*say = \&writeline;
	*sleep = \&wait;
	*fileno = \&handle;
	*remote_name = \&get_hostname;
}

1; # return

sub import {
	my $pkg = shift;
	my $callpkg = caller;
	@_ or return;
	$Socket::Class::Const::VERSION
		or require Socket::Class::Const;
	&Socket::Class::Const::export( $callpkg, @_ );
}

sub printf {
	if( @_ < 2 ) {
		require Carp unless $Carp::VERSION;
		&Carp::croak( 'Usage: Socket::Class::printf(this,fmt,...)' );
	}
	my( $sock, $fmt ) = ( shift, shift );
	return $sock->write( sprintf( $fmt, @_ ) );
}

sub reconnect {
	if( @_ < 1 || @_ > 2 ) {
		require Carp unless $Carp::VERSION;
		&Carp::croak( 'Usage: Socket::Class::reconnect(this,wait=0)' );
	}
	my $this = shift;
	$this->close() or return undef;
	$this->wait( $_[0] ) if $_[0];
	$this->connect() or return undef;
	return 1;
}

sub include_path {
	return substr( __FILE__, 0, -16 ) . '/auto/Socket/Class';
}

__END__

