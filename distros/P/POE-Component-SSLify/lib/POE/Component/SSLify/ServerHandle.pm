#
# This file is part of POE-Component-SSLify
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::SSLify::ServerHandle;
$POE::Component::SSLify::ServerHandle::VERSION = '1.012';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Server-side handle for SSLify

# Import the SSL death routines
use Net::SSLeay 1.36 qw( die_now die_if_ssl_error ERROR_WANT_READ ERROR_WANT_WRITE );

# Ties the socket
sub TIEHANDLE {
	my ( $class, $socket, $ctx, $connref ) = @_;

	my $ssl = Net::SSLeay::new( $ctx ) or die_now( "Failed to create SSL $!" );

	my $fileno = fileno( $socket );

	Net::SSLeay::set_fd( $ssl, $fileno );

	# Socket is in non-blocking mode, so accept() will return immediately.
	# die_if_ssl_error won't die on non-blocking errors. We don't need to call accept()
	# again, because OpenSSL I/O functions (read, write, ...) can handle that entirely
	# by self (it's needed to accept() once to determine connection type).
	my $res = Net::SSLeay::accept( $ssl ) and die_if_ssl_error( 'ssl accept' );

	my $self = bless {
		'ssl'		=> $ssl,
		'ctx'		=> $ctx,
		'socket'	=> $socket,
		'fileno'	=> $fileno,
		'status'	=> $res,
		'on_connect'	=> $connref,
		'ssl_started'	=> 0,
	}, $class;

	return $self;
}

# TODO should we make a convenience function to convert retval to string equivalents for easier debugging?
# From OpenSSL 1.0.0d
#define SSL_ERROR_NONE			0
#define SSL_ERROR_SSL			1
#define SSL_ERROR_WANT_READ		2
#define SSL_ERROR_WANT_WRITE		3
#define SSL_ERROR_WANT_X509_LOOKUP	4
#define SSL_ERROR_SYSCALL		5 /* look at error stack/return value/errno */
#define SSL_ERROR_ZERO_RETURN		6
#define SSL_ERROR_WANT_CONNECT		7
#define SSL_ERROR_WANT_ACCEPT		8

sub _check_status {
	my $self = shift;

	# Okay, is negotiation done?
	# http://www.openssl.org/docs/ssl/SSL_connect.html#RETURN_VALUES
	if ( exists $self->{'client'} ) {
		$self->{'status'} = Net::SSLeay::connect( $self->{'ssl'} );
	} else {
		$self->{'status'} = Net::SSLeay::accept( $self->{'ssl'} );
	}

	if ( $self->{'status'} <= 0 ) {
		# http://www.openssl.org/docs/ssl/SSL_get_error.html
		my $errval = Net::SSLeay::get_error( $self->{'ssl'}, $self->{'status'} );

		# Handle the case of ERROR_WANT_READ and ERROR_WANT_WRITE
		# TODO should we skip ERROR_WANT_ACCEPT and ERROR_WANT_CONNECT ?
		# also, ERROR_WANT_ACCEPT isn't exported by Net::SSLeay, huh?
		if ( $errval == ERROR_WANT_READ or $errval == ERROR_WANT_WRITE ) {
			# continue reading/writing from the socket until we connect or not...
			return 1;
		} else {
			# call the hook function for error connect
			if ( defined $self->{'on_connect'} ) {
				$self->{'on_connect'}->( $self->{'orig_socket'}, 0, $errval );
			}

			# don't try to read/write from the socket anymore!
			return 0;
		}
	} elsif ( $self->{'status'} == 1 ) {
		# SSL handshake is done!
		$self->{'ssl_started'} = 1;

		# call the hook function for successful connect
		if ( defined $self->{'on_connect'} ) {
			$self->{'on_connect'}->( $self->{'orig_socket'}, 1 );
		}

		# we can now read/write from the socket!
		return 1;
	}
}

# Read something from the socket
sub READ {
	# Get ourself!
	my $self = shift;

	# Get the pointers to buffer, length, and the offset
	my( $buf, $len, $offset ) = \( @_ );

	# Check the status of the SSL handshake
	if ( ! $self->{'ssl_started'} ) {
		return if $self->_check_status == 0;
	}

	# If we have no offset, replace the buffer with some input
	if ( ! defined $$offset ) {
		$$buf = Net::SSLeay::read( $self->{'ssl'}, $$len );

		# Are we done?
		if ( defined $$buf ) {
			# TODO do we need the same "flush is success" logic in WRITE?

			return length( $$buf );
		} else {
			# Nah, clear the buffer too...
			$$buf = "";
			return;
		}
	}

	# Now, actually read the data
	defined( my $read = Net::SSLeay::read( $self->{'ssl'}, $$len ) ) or return;

	# TODO do we need the same "flush is success" logic in WRITE?

	# Figure out the buffer and offset
	my $buf_len = length( $$buf );

	# If our offset is bigger, pad the buffer
	if ( $$offset > $buf_len ) {
		$$buf .= chr( 0 ) x ( $$offset - $buf_len );
	}

	# Insert what we just read into the buffer
	substr( $$buf, $$offset, 1, $read );

	# All done!
	return length( $read );
}

# Write some stuff to the socket
sub WRITE {
	# Get ourself + buffer + length + offset to write
	my( $self, $len, $offset ) = ( $_[0], $_[2], $_[3] );
	my $buf = \$_[1]; # don't copy!

	# Check the status of the SSL handshake
	if ( ! $self->{'ssl_started'} ) {
		# The normal syswrite() POE uses expects 0 here.
		return 0 if $self->_check_status == 0;
	}

	# If we have nothing to offset, then start from the beginning
	if ( ! defined $offset ) {
		$offset = 0;
	}

	# Thanks to RT#95071 and RT#58243 we need to clamp the length to the TLS 16K limit
	# seems like the same thing happened to https://www.mail-archive.com/openssl-users@openssl.org/msg28151.html
	$len = 16_384 if $len > 16_384;

	# don't trigger substr's magic as it is SLOOOOOOOOW!
	# see http://www.perlmonks.org/?node_id=732873
	my $wrote_len = Net::SSLeay::write( $self->{'ssl'}, scalar substr( $$buf, $offset, $len ) );

	# Did we get an error or number of bytes written?
	# Net::SSLeay::write() returns the number of bytes written, or 0 on unsuccessful
	# operation (probably connection closed), or -1 on error.
	if ( $wrote_len < 0 ) {
		# The normal syswrite() POE uses expects 0 here.
		return 0;
	} else {
		# We flushed some data, which means we finished the handshake!
		# This is IMPORTANT, as MIRE found out!
		# Otherwise openssl will zonk out and give us SSL_ERROR_SSL and things randomly break :(
		# this is because we tried to connect() or accept() and the handshake was done... or something like that hah
		if ( ! $self->{'ssl_started'} ) {
			$self->{'ssl_started'} = 1;
			$self->{'status'} = 1;

			# call the hook function for successful connect
			if ( defined $self->{'on_connect'} ) {
				$self->{'on_connect'}->( $self->{'orig_socket'}, 1 );
			}
		}

		# All done!
		return $wrote_len;
	}
}

# Sets binmode on the socket
# Thanks to RT #27117
sub BINMODE {
	my $self = shift;
	if (@_) {
		my $mode = shift;
		binmode $self->{'socket'}, $mode;
	} else {
		binmode $self->{'socket'};
	}

	return;
}

# Closes the socket
sub CLOSE {
	my $self = shift;
	if ( defined $self->{'socket'} ) {
		Net::SSLeay::free( $self->{'ssl'} );

		# TODO we ignore any close errors because there's no way to sanely propagate it up the stack...
		close( $self->{'socket'} ); ## no critic ( InputOutput::RequireCheckedClose )
		undef $self->{'socket'};

		# do we need to do CTX_free?
		if ( exists $self->{'client'} ) {
			Net::SSLeay::CTX_free( $self->{'ctx'} );
		}
	}

	return 1;
}

# Add DESTROY handler
sub DESTROY {
	my $self = shift;

	# Did we already CLOSE?
	if ( defined $self->{'socket'} ) {
		# Guess not...
		$self->CLOSE();
	}

	return;
}

sub FILENO {
	my $self = shift;
	return $self->{'fileno'};
}

# Not implemented TIE's
sub READLINE {
	die 'Not Implemented';
}

sub PRINT {
	die 'Not Implemented';
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=head1 NAME

POE::Component::SSLify::ServerHandle - Server-side handle for SSLify

=head1 VERSION

  This document describes v1.012 of POE::Component::SSLify::ServerHandle - released November 14, 2014 as part of POE-Component-SSLify.

=head1 DESCRIPTION

	This is a subclass of Net::SSLeay::Handle because their read() and sysread()
	does not cooperate well with POE. They block until length bytes are read from the
	socket, and that is BAD in the world of POE...

	This subclass behaves exactly the same, except that it doesn't block :)

=head2 DIFFERENCES

	This subclass doesn't know what to do with PRINT/READLINE, as they usually are not used in POE::Wheel operations...

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::SSLify|POE::Component::SSLify>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
