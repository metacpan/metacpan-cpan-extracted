#
# This file is part of POE-Component-SSLify
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::SSLify::ClientHandle;
$POE::Component::SSLify::ClientHandle::VERSION = '1.012';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Client-side handle for SSLify

# Import the SSL death routines
use Net::SSLeay 1.36 qw( die_now die_if_ssl_error );

# We inherit from ServerHandle
use parent 'POE::Component::SSLify::ServerHandle';

# Override TIEHANDLE because we create a CTX
sub TIEHANDLE {
	my ( $class, $socket, $version, $options, $ctx, $connref ) = @_;

	# create a context, if necessary
	if ( ! defined $ctx ) {
		$ctx = POE::Component::SSLify::_createSSLcontext( undef, undef, $version, $options );
	}

	my $ssl = Net::SSLeay::new( $ctx ) or die_now( "Failed to create SSL $!" );

	my $fileno = fileno( $socket );

	Net::SSLeay::set_fd( $ssl, $fileno );   # Must use fileno

	# Socket is in non-blocking mode, so connect() will return immediately.
	# die_if_ssl_error won't die on non-blocking errors. We don't need to call connect()
	# again, because OpenSSL I/O functions (read, write, ...) can handle that entirely
	# by self (it's needed to connect() once to determine connection type).
	my $res = Net::SSLeay::connect( $ssl ) or die_if_ssl_error( 'ssl connect' );

	my $self = bless {
		'ssl'		=> $ssl,
		'ctx'		=> $ctx,
		'socket'	=> $socket,
		'fileno'	=> $fileno,
		'client'	=> 1,
		'status'	=> $res,
		'on_connect'	=> $connref,
	}, $class;

	return $self;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=head1 NAME

POE::Component::SSLify::ClientHandle - Client-side handle for SSLify

=head1 VERSION

  This document describes v1.012 of POE::Component::SSLify::ClientHandle - released November 14, 2014 as part of POE-Component-SSLify.

=head1 DESCRIPTION

	This is a subclass of ServerHandle to accomodate clients setting custom context objects.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::SSLify|POE::Component::SSLify>

=item *

L<POE::Component::SSLify::ServerHandle|POE::Component::SSLify::ServerHandle>

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
