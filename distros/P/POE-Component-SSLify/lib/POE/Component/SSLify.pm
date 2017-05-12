#
# This file is part of POE-Component-SSLify
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::SSLify;
# git description: release-1.011-1-g57b6383
$POE::Component::SSLify::VERSION = '1.012';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Makes using SSL in the world of POE easy!

BEGIN {
	# should fix netbsd smoke failures, thanks BinGOs!
	# <BinGOs> Apocal: okay cores with a 0.9.7d I've built myself from source. Doesn't if I comment out engine lines.
	# BinGOs did an awesome job building various versions of openssl to try and track down the problem, it seems like
	# newer versions of openssl worked fine on netbsd, but I don't want to do crazy stuff like probing openssl versions
	# as it's fragile - best to let the user figure it out :)
	#
	# see http://www.cpantesters.org/cpan/report/1a660280-6eb1-11e0-a462-e9956c33433b
	# http://www.cpantesters.org/cpan/report/49a9f2aa-6df2-11e0-a462-e9956c33433b
	# http://www.cpantesters.org/cpan/report/78d9a234-6df5-11e0-a462-e9956c33433b
	# and many other reports :(
	#
	#(gdb) bt
	##0  0xbd9d3e7e in engine_table_select () from /usr/lib/libcrypto.so.2
	##1  0xbd9b3bed in ENGINE_get_default_RSA () from /usr/lib/libcrypto.so.2
	##2  0xbd9b1f6d in RSA_new_method () from /usr/lib/libcrypto.so.2
	##3  0xbd9b1cf6 in RSA_new () from /usr/lib/libcrypto.so.2
	##4  0xbd9cf8a1 in RSAPrivateKey_asn1_meth () from /usr/lib/libcrypto.so.2
	##5  0xbd9da64b in ASN1_item_ex_new () from /usr/lib/libcrypto.so.2
	##6  0xbd9da567 in ASN1_item_ex_new () from /usr/lib/libcrypto.so.2
	##7  0xbd9d88cc in ASN1_item_ex_d2i () from /usr/lib/libcrypto.so.2
	##8  0xbd9d8437 in ASN1_item_d2i () from /usr/lib/libcrypto.so.2
	##9  0xbd9cf8d5 in d2i_RSAPrivateKey () from /usr/lib/libcrypto.so.2
	##10 0xbd9ad546 in d2i_PrivateKey () from /usr/lib/libcrypto.so.2
	##11 0xbd995e63 in PEM_read_bio_PrivateKey () from /usr/lib/libcrypto.so.2
	##12 0xbd980430 in PEM_read_bio_RSAPrivateKey () from /usr/lib/libcrypto.so.2
	##13 0xbda2e9dc in SSL_CTX_use_RSAPrivateKey_file () from /usr/lib/libssl.so.3
	##14 0xbda5aabe in XS_Net__SSLeay_CTX_use_RSAPrivateKey_file (cv=0x8682c80)
	#    at SSLeay.c:1716
	##15 0x08115401 in Perl_pp_entersub () at pp_hot.c:2885
	##16 0x080e0ab7 in Perl_runops_debug () at dump.c:2049
	##17 0x08078624 in S_run_body (oldscope=1) at perl.c:2308
	##18 0x08077ef2 in perl_run (my_perl=0x823f030) at perl.c:2233
	##19 0x0805e321 in main (argc=3, argv=0xbfbfe6a0, env=0xbfbfe6b0)
	#    at perlmain.c:117
	##20 0x0805e0c6 in ___start ()
	#(gdb)
	if ( ! defined &LOAD_SSL_ENGINES ) { *LOAD_SSL_ENGINES = sub () { 0 } }
}

# We need Net::SSLeay or all's a failure!
BEGIN {
	# We need >= 1.36 because it contains a lot of important fixes
	eval "use Net::SSLeay 1.36 qw( die_now die_if_ssl_error FILETYPE_PEM )";

	# Check for errors...
	if ( $@ ) {
		# Oh boy!
		die $@;
	} else {
		# Finally, load our subclasses :)
		# ClientHandle isa ServerHandle so it will get loaded automatically
		require POE::Component::SSLify::ClientHandle;

		# Initialize Net::SSLeay
		# Taken from http://search.cpan.org/~flora/Net-SSLeay-1.36/lib/Net/SSLeay.pm#Low_level_API
		Net::SSLeay::load_error_strings();
		Net::SSLeay::SSLeay_add_ssl_algorithms();
		if ( LOAD_SSL_ENGINES ) {
			Net::SSLeay::ENGINE_load_builtin_engines();
			Net::SSLeay::ENGINE_register_all_complete();
		}
		Net::SSLeay::randomize();
	}
}

# Do the exporting magic...
use parent 'Exporter';
our @EXPORT_OK = qw(
	Client_SSLify Server_SSLify
	SSLify_Options SSLify_GetCTX SSLify_GetCipher SSLify_GetSocket SSLify_GetSSL SSLify_ContextCreate SSLify_GetStatus
);

# Bring in some socket-related stuff
use Symbol qw( gensym );

# we need IO 1.24 for it's win32 fixes but it includes IO::Handle 1.27_02 which is dev...
# unfortunately we have to jump to IO 1.25 which includes IO::Handle 1.28... argh!
use IO::Handle 1.28;

# Use Scalar::Util's weaken() for the connref stuff
use Scalar::Util qw( weaken );
use Task::Weaken 1.03; # to make sure it actually works!

# load POE ( just to fool dzil AutoPrereqs :)
require POE;

# The server-side CTX stuff
my $ctx;

# global so users of this module can override it locally
our $IGNORE_SSL_ERRORS = 0;

#pod =func Client_SSLify
#pod
#pod This function sslifies a client-side socket. You can pass several options to it:
#pod
#pod 	my $socket = shift;
#pod 	$socket = Client_SSLify( $socket, $version, $options, $ctx, $callback );
#pod 		$socket is the non-ssl socket you got from somewhere ( required )
#pod 		$version is the SSL version you want to use
#pod 		$options is the SSL options you want to use
#pod 		$ctx is the custom SSL context you want to use
#pod 		$callback is the callback hook on success/failure of sslification
#pod
#pod 		# This is an example of the callback and you should pass it as Client_SSLify( $socket, ... , \&callback );
#pod 		sub callback {
#pod 			my( $socket, $status, $errval ) = @_;
#pod 			# $socket is the original sslified socket in case you need to play with it
#pod 			# $status is either 1 or 0; with 1 signifying success and 0 failure
#pod 			# $errval will be defined if $status == 0; it's the numeric SSL error code
#pod 			# check http://www.openssl.org/docs/ssl/SSL_get_error.html for the possible error values ( and import them from Net::SSLeay! )
#pod
#pod 			# The return value from the callback is discarded
#pod 		}
#pod
#pod If $ctx is defined, SSLify will ignore $version and $options. Otherwise, it will be created from the $version and
#pod $options parameters. If all of them are undefined, it will follow the defaults in L</SSLify_ContextCreate>.
#pod
#pod BEWARE: If you passed in a CTX, SSLify will do Net::SSLeay::CTX_free( $ctx ) when the
#pod socket is destroyed. This means you cannot reuse contexts!
#pod
#pod NOTE: The way to have a client socket with proper certificates set up is:
#pod
#pod 	my $socket = shift;	# get the socket from somewhere
#pod 	my $ctx = SSLify_ContextCreate( 'server.key', 'server.crt' );
#pod 	$socket = Client_SSLify( $socket, undef, undef, $ctx );
#pod
#pod NOTE: You can pass the callback anywhere in the arguments, we'll figure it out for you! If you want to call a POE event, please look
#pod into the postback/callback stuff in L<POE::Session>.
#pod
#pod 	# we got this from POE::Wheel::SocketFactory
#pod 	sub event_SuccessEvent {
#pod 		my $socket = $_[ARG0];
#pod 		$socket = Client_SSLify( $socket, $_[SESSION]->callback( 'sslify_result' ) );
#pod 		$_[HEAP]->{client} = POE::Wheel::ReadWrite->new(
#pod 			Handle => $socket,
#pod 			...
#pod 		);
#pod 		return;
#pod 	}
#pod
#pod 	# the callback event
#pod 	sub event_sslify_result {
#pod 		my ($creation_args, $called_args) = @_[ARG0, ARG1];
#pod 		my( $socket, $status, $errval ) = @$called_args;
#pod
#pod 		if ( $status ) {
#pod 			print "Yay, SSLification worked!";
#pod 		} else {
#pod 			print "Aw, SSLification failed with error $errval";
#pod 		}
#pod 	}
#pod =cut

sub Client_SSLify {
	# Get the socket + version + options + ctx + callback
	my( $socket, $version, $options, $custom_ctx, $callback ) = @_;

	# Validation...
	if ( ! defined $socket ) {
		die "Did not get a defined socket";
	}

	# Mangle the callback stuff
	if ( defined $version and ref $version and ref( $version ) eq 'CODE' ) {
		$callback = $version;
		$version = $options = $custom_ctx = undef;
	} elsif ( defined $options and ref $options and ref( $options ) eq 'CODE' ) {
		$callback = $options;
		$options = $custom_ctx = undef;
	} elsif ( defined $custom_ctx and ref $custom_ctx and ref( $custom_ctx ) eq 'CODE' ) {
		$callback = $custom_ctx;
		$custom_ctx = undef;
	}

	# From IO::Handle POD
	# If an error occurs blocking will return undef and $! will be set.
	if ( ! defined $socket->blocking( 0 ) ) {
		die "Unable to set nonblocking mode on socket: $!";
	}

	# Now, we create the new socket and bind it to our subclass of Net::SSLeay::Handle
	my $newsock = gensym();
	tie( *$newsock, 'POE::Component::SSLify::ClientHandle', $socket, $version, $options, $custom_ctx, $callback ) or die "Unable to tie to our subclass: $!";

	# argh, store the newsock in the tied class to use for callback
	if ( defined $callback ) {
		tied( *$newsock )->{'orig_socket'} = $newsock;
		weaken( tied( *$newsock )->{'orig_socket'} );
	}

	# All done!
	return $newsock;
}

#pod =func Server_SSLify
#pod
#pod This function sslifies a server-side socket. You can pass several options to it:
#pod
#pod 	my $socket = shift;
#pod 	$socket = Server_SSLify( $socket, $ctx, $callback );
#pod 		$socket is the non-ssl socket you got from somewhere ( required )
#pod 		$ctx is the custom SSL context you want to use; overrides the global ctx set in SSLify_Options
#pod 		$callback is the callback hook on success/failure of sslification
#pod
#pod BEWARE: L</SSLify_Options> must be called first if you aren't passing a $ctx. If you want to set some options per-connection, do this:
#pod
#pod 	my $socket = shift;	# get the socket from somewhere
#pod 	my $ctx = SSLify_ContextCreate();
#pod 	# set various options on $ctx as desired
#pod 	$socket = Server_SSLify( $socket, $ctx );
#pod
#pod NOTE: You can use L</SSLify_GetCTX> to modify the global, and avoid doing this on every connection if the
#pod options are the same...
#pod
#pod Please look at L</Client_SSLify> for more details on the callback hook.
#pod =cut

sub Server_SSLify {
	# Get the socket!
	my( $socket, $custom_ctx, $callback ) = @_;

	# Validation...
	if ( ! defined $socket ) {
		die "Did not get a defined socket";
	}

	# If we don't have a ctx ready, we can't do anything...
	if ( ! defined $ctx and ! defined $custom_ctx ) {
		die 'Please do SSLify_Options() first ( or pass in a $ctx object )';
	}

	# mangle custom_ctx depending on callback
	if ( defined $custom_ctx and ref $custom_ctx and ref( $custom_ctx ) eq 'CODE' ) {
		$callback = $custom_ctx;
		$custom_ctx = undef;
	}

	# From IO::Handle POD
	# If an error occurs blocking will return undef and $! will be set.
	if ( ! defined $socket->blocking( 0 ) ) {
		die "Unable to set nonblocking mode on socket: $!";
	}

	# Now, we create the new socket and bind it to our subclass of Net::SSLeay::Handle
	my $newsock = gensym();
	tie( *$newsock, 'POE::Component::SSLify::ServerHandle', $socket, ( $custom_ctx || $ctx ), $callback ) or die "Unable to tie to our subclass: $!";

	# argh, store the newsock in the tied class to use for connref
	if ( defined $callback ) {
		tied( *$newsock )->{'orig_socket'} = $newsock;
		weaken( tied( *$newsock )->{'orig_socket'} );
	}

	# All done!
	return $newsock;
}

#pod =func SSLify_ContextCreate
#pod
#pod Accepts some options, and returns a brand-new Net::SSLeay context object ( $ctx )
#pod
#pod 	my $ctx = SSLify_ContextCreate( $key, $cert, $version, $options );
#pod 		$key is the certificate key file
#pod 		$cert is the certificate file
#pod 		$version is the SSL version to use
#pod 		$options is the SSL options to use
#pod
#pod You can then call various Net::SSLeay methods on the context
#pod
#pod 	my $mode = Net::SSLeay::CTX_get_mode( $ctx );
#pod
#pod By default we don't use the SSL key + certificate files
#pod
#pod By default we use the version: default. Known versions of the SSL connection - look at
#pod L<http://www.openssl.org/docs/ssl/SSL_CTX_new.html> for more info.
#pod
#pod 	* sslv2
#pod 	* sslv3
#pod 	* tlsv1
#pod 	* sslv23
#pod 	* default ( sslv23 )
#pod
#pod By default we don't set any options - look at L<http://www.openssl.org/docs/ssl/SSL_CTX_set_options.html> for more info.
#pod =cut

sub SSLify_ContextCreate {
	# Get the key + cert + version + options
	my( $key, $cert, $version, $options ) = @_;

	return _createSSLcontext( $key, $cert, $version, $options );
}

#pod =func SSLify_Options
#pod
#pod Call this function to initialize the global server-side context object. This will be the default context whenever you call
#pod L</Server_SSLify> without passing a custom context to it.
#pod
#pod 	SSLify_Options( $key, $cert, $version, $options );
#pod 		$key is the certificate key file ( required )
#pod 		$cert is the certificate file ( required )
#pod 		$version is the SSL version to use
#pod 		$options is the SSL options to use
#pod
#pod By default we use the version: default
#pod
#pod By default we use the options: Net::SSLeay::OP_ALL
#pod
#pod Please look at L</SSLify_ContextCreate> for more info on the available versions/options.
#pod =cut

sub SSLify_Options {
	# Get the key + cert + version + options
	my( $key, $cert, $version, $options ) = @_;

	# sanity
	if ( ! defined $key or ! defined $cert ) {
		die 'no key/cert specified';
	}

	# Set the default
	if ( ! defined $options ) {
		$options = Net::SSLeay::OP_ALL();
	}

	# set the context, possibly overwriting the previous one
	if ( defined $ctx ) {
		Net::SSLeay::CTX_free( $ctx );
		undef $ctx;
	}
	$ctx = _createSSLcontext( $key, $cert, $version, $options );

	# all done!
	return 1;
}

sub _createSSLcontext {
	my( $key, $cert, $version, $options ) = @_;

	my $context;
	if ( defined $version and ! ref $version ) {
		if ( $version eq 'sslv2' ) {
			$context = Net::SSLeay::CTX_v2_new();
		} elsif ( $version eq 'sslv3' ) {
			$context = Net::SSLeay::CTX_v3_new();
		} elsif ( $version eq 'tlsv1' ) {
			$context = Net::SSLeay::CTX_tlsv1_new();
		} elsif ( $version eq 'sslv23' ) {
			$context = Net::SSLeay::CTX_v23_new();
		} elsif ( $version eq 'default' ) {
			$context = Net::SSLeay::CTX_new();
		} else {
			die "unknown SSL version: $version";
		}
	} else {
		$context = Net::SSLeay::CTX_new();
	}
	if ( ! defined $context ) {
		die_now( "Failed to create SSL_CTX $!" );
		return;
	}

	# do we need to set options?
	if ( defined $options ) {
		Net::SSLeay::CTX_set_options( $context, $options );
		die_if_ssl_error( 'ssl ctx set options' ) if ! $IGNORE_SSL_ERRORS;
	}

	# do we need to set key/etc?
	if ( defined $key ) {
		# Following will ask password unless private key is not encrypted
		Net::SSLeay::CTX_use_RSAPrivateKey_file( $context, $key, FILETYPE_PEM );
		die_if_ssl_error( 'private key' ) if ! $IGNORE_SSL_ERRORS;
	}

	# Set the cert file
	if ( defined $cert ) {
		Net::SSLeay::CTX_use_certificate_chain_file( $context, $cert );
		die_if_ssl_error( 'certificate' ) if ! $IGNORE_SSL_ERRORS;
	}

	# All done!
	return $context;
}

#pod =func SSLify_GetCTX
#pod
#pod Returns the actual Net::SSLeay context object in case you wanted to play with it :)
#pod
#pod If passed in a socket, it will return that socket's $ctx instead of the global.
#pod
#pod 	my $ctx = SSLify_GetCTX();			# get the one set via SSLify_Options
#pod 	my $ctx = SSLify_GetCTX( $sslified_sock );	# get the one in the object
#pod =cut

sub SSLify_GetCTX {
	my $sock = shift;
	if ( ! defined $sock ) {
		return $ctx;
	} else {
		return tied( *$sock )->{'ctx'};
	}
}

#pod =func SSLify_GetCipher
#pod
#pod Returns the cipher used by the SSLified socket
#pod
#pod 	print "SSL Cipher is: " . SSLify_GetCipher( $sslified_sock ) . "\n";
#pod
#pod NOTE: Doing this immediately after Client_SSLify or Server_SSLify will result in "(NONE)" because the SSL handshake
#pod is not done yet. The socket is nonblocking, so you will have to wait a little bit for it to get ready.
#pod
#pod 	apoc@blackhole:~/mygit/perl-poe-sslify/examples$ perl serverclient.pl
#pod 	got connection from: 127.0.0.1 - commencing Server_SSLify()
#pod 	SSLified: 127.0.0.1 cipher type: ((NONE))
#pod 	Connected to server, commencing Client_SSLify()
#pod 	SSLified the connection to the server
#pod 	Connected to SSL server
#pod 	Input: hola
#pod 	got input from: 127.0.0.1 cipher type: (AES256-SHA) input: 'hola'
#pod 	Got Reply: hola
#pod 	Input: ^C
#pod 	stopped at serverclient.pl line 126.
#pod =cut

sub SSLify_GetCipher {
	my $sock = shift;
	return Net::SSLeay::get_cipher( tied( *$sock )->{'ssl'} );
}

#pod =func SSLify_GetSocket
#pod
#pod Returns the actual socket used by the SSLified socket, useful for stuff like getpeername()/getsockname()
#pod
#pod 	print "Remote IP is: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $sslified_sock ) ) ) )[1] ) . "\n";
#pod =cut

sub SSLify_GetSocket {
	my $sock = shift;
	return tied( *$sock )->{'socket'};
}

#pod =func SSLify_GetSSL
#pod
#pod Returns the actual Net::SSLeay object so you can call methods on it
#pod
#pod 	print Net::SSLeay::dump_peer_certificate( SSLify_GetSSL( $sslified_sock ) );
#pod =cut

sub SSLify_GetSSL {
	my $sock = shift;
	return tied( *$sock )->{'ssl'};
}

#pod =func SSLify_GetStatus
#pod
#pod Returns the status of the SSL negotiation/handshake/connection. See L<http://www.openssl.org/docs/ssl/SSL_connect.html#RETURN_VALUES>
#pod for more info.
#pod
#pod 	my $status = SSLify_GetStatus( $socket );
#pod 		-1 = still in negotiation stage ( or error )
#pod 		 0 = internal SSL error, connection will be dead
#pod 		 1 = negotiation successful
#pod =cut

sub SSLify_GetStatus {
	my $sock = shift;
	return tied( *$sock )->{'status'};
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

POE::Component::SSLify - Makes using SSL in the world of POE easy!

=head1 VERSION

  This document describes v1.012 of POE::Component::SSLify - released November 14, 2014 as part of POE-Component-SSLify.

=head1 SYNOPSIS

	# look at the DESCRIPTION for client and server example code

=head1 DESCRIPTION

This component is a method to simplify the SSLification of a socket before it is passed
to a L<POE::Wheel::ReadWrite> wheel in your application.

=head2 Client usage

	# Import the module
	use POE::Component::SSLify qw( Client_SSLify );

	# Create a normal SocketFactory wheel and connect to a SSL-enabled server
	my $factory = POE::Wheel::SocketFactory->new;

	# Time passes, SocketFactory gives you a socket when it connects in SuccessEvent
	# Convert the socket into a SSL socket POE can communicate with
	my $socket = shift;
	eval { $socket = Client_SSLify( $socket ) };
	if ( $@ ) {
		# Unable to SSLify it...
	}

	# Now, hand it off to ReadWrite
	my $rw = POE::Wheel::ReadWrite->new(
		Handle	=>	$socket,
		# other options as usual
	);

=head2 Server usage

	# !!! Make sure you have a public key + certificate
	# excellent howto: http://www.akadia.com/services/ssh_test_certificate.html

	# Import the module
	use POE::Component::SSLify qw( Server_SSLify SSLify_Options );

	# Set the key + certificate file
	eval { SSLify_Options( 'server.key', 'server.crt' ) };
	if ( $@ ) {
		# Unable to load key or certificate file...
	}

	# Create a normal SocketFactory wheel to listen for connections
	my $factory = POE::Wheel::SocketFactory->new;

	# Time passes, SocketFactory gives you a socket when it gets a connection in SuccessEvent
	# Convert the socket into a SSL socket POE can communicate with
	my $socket = shift;
	eval { $socket = Server_SSLify( $socket ) };
	if ( $@ ) {
		# Unable to SSLify it...
	}

	# Now, hand it off to ReadWrite
	my $rw = POE::Wheel::ReadWrite->new(
		Handle	=>	$socket,
		# other options as usual
	);

=head1 FUNCTIONS

=head2 Client_SSLify

This function sslifies a client-side socket. You can pass several options to it:

	my $socket = shift;
	$socket = Client_SSLify( $socket, $version, $options, $ctx, $callback );
		$socket is the non-ssl socket you got from somewhere ( required )
		$version is the SSL version you want to use
		$options is the SSL options you want to use
		$ctx is the custom SSL context you want to use
		$callback is the callback hook on success/failure of sslification

		# This is an example of the callback and you should pass it as Client_SSLify( $socket, ... , \&callback );
		sub callback {
			my( $socket, $status, $errval ) = @_;
			# $socket is the original sslified socket in case you need to play with it
			# $status is either 1 or 0; with 1 signifying success and 0 failure
			# $errval will be defined if $status == 0; it's the numeric SSL error code
			# check http://www.openssl.org/docs/ssl/SSL_get_error.html for the possible error values ( and import them from Net::SSLeay! )

			# The return value from the callback is discarded
		}

If $ctx is defined, SSLify will ignore $version and $options. Otherwise, it will be created from the $version and
$options parameters. If all of them are undefined, it will follow the defaults in L</SSLify_ContextCreate>.

BEWARE: If you passed in a CTX, SSLify will do Net::SSLeay::CTX_free( $ctx ) when the
socket is destroyed. This means you cannot reuse contexts!

NOTE: The way to have a client socket with proper certificates set up is:

	my $socket = shift;	# get the socket from somewhere
	my $ctx = SSLify_ContextCreate( 'server.key', 'server.crt' );
	$socket = Client_SSLify( $socket, undef, undef, $ctx );

NOTE: You can pass the callback anywhere in the arguments, we'll figure it out for you! If you want to call a POE event, please look
into the postback/callback stuff in L<POE::Session>.

	# we got this from POE::Wheel::SocketFactory
	sub event_SuccessEvent {
		my $socket = $_[ARG0];
		$socket = Client_SSLify( $socket, $_[SESSION]->callback( 'sslify_result' ) );
		$_[HEAP]->{client} = POE::Wheel::ReadWrite->new(
			Handle => $socket,
			...
		);
		return;
	}

	# the callback event
	sub event_sslify_result {
		my ($creation_args, $called_args) = @_[ARG0, ARG1];
		my( $socket, $status, $errval ) = @$called_args;

		if ( $status ) {
			print "Yay, SSLification worked!";
		} else {
			print "Aw, SSLification failed with error $errval";
		}
	}

=head2 Server_SSLify

This function sslifies a server-side socket. You can pass several options to it:

	my $socket = shift;
	$socket = Server_SSLify( $socket, $ctx, $callback );
		$socket is the non-ssl socket you got from somewhere ( required )
		$ctx is the custom SSL context you want to use; overrides the global ctx set in SSLify_Options
		$callback is the callback hook on success/failure of sslification

BEWARE: L</SSLify_Options> must be called first if you aren't passing a $ctx. If you want to set some options per-connection, do this:

	my $socket = shift;	# get the socket from somewhere
	my $ctx = SSLify_ContextCreate();
	# set various options on $ctx as desired
	$socket = Server_SSLify( $socket, $ctx );

NOTE: You can use L</SSLify_GetCTX> to modify the global, and avoid doing this on every connection if the
options are the same...

Please look at L</Client_SSLify> for more details on the callback hook.

=head2 SSLify_ContextCreate

Accepts some options, and returns a brand-new Net::SSLeay context object ( $ctx )

	my $ctx = SSLify_ContextCreate( $key, $cert, $version, $options );
		$key is the certificate key file
		$cert is the certificate file
		$version is the SSL version to use
		$options is the SSL options to use

You can then call various Net::SSLeay methods on the context

	my $mode = Net::SSLeay::CTX_get_mode( $ctx );

By default we don't use the SSL key + certificate files

By default we use the version: default. Known versions of the SSL connection - look at
L<http://www.openssl.org/docs/ssl/SSL_CTX_new.html> for more info.

	* sslv2
	* sslv3
	* tlsv1
	* sslv23
	* default ( sslv23 )

By default we don't set any options - look at L<http://www.openssl.org/docs/ssl/SSL_CTX_set_options.html> for more info.

=head2 SSLify_Options

Call this function to initialize the global server-side context object. This will be the default context whenever you call
L</Server_SSLify> without passing a custom context to it.

	SSLify_Options( $key, $cert, $version, $options );
		$key is the certificate key file ( required )
		$cert is the certificate file ( required )
		$version is the SSL version to use
		$options is the SSL options to use

By default we use the version: default

By default we use the options: Net::SSLeay::OP_ALL

Please look at L</SSLify_ContextCreate> for more info on the available versions/options.

=head2 SSLify_GetCTX

Returns the actual Net::SSLeay context object in case you wanted to play with it :)

If passed in a socket, it will return that socket's $ctx instead of the global.

	my $ctx = SSLify_GetCTX();			# get the one set via SSLify_Options
	my $ctx = SSLify_GetCTX( $sslified_sock );	# get the one in the object

=head2 SSLify_GetCipher

Returns the cipher used by the SSLified socket

	print "SSL Cipher is: " . SSLify_GetCipher( $sslified_sock ) . "\n";

NOTE: Doing this immediately after Client_SSLify or Server_SSLify will result in "(NONE)" because the SSL handshake
is not done yet. The socket is nonblocking, so you will have to wait a little bit for it to get ready.

	apoc@blackhole:~/mygit/perl-poe-sslify/examples$ perl serverclient.pl
	got connection from: 127.0.0.1 - commencing Server_SSLify()
	SSLified: 127.0.0.1 cipher type: ((NONE))
	Connected to server, commencing Client_SSLify()
	SSLified the connection to the server
	Connected to SSL server
	Input: hola
	got input from: 127.0.0.1 cipher type: (AES256-SHA) input: 'hola'
	Got Reply: hola
	Input: ^C
	stopped at serverclient.pl line 126.

=head2 SSLify_GetSocket

Returns the actual socket used by the SSLified socket, useful for stuff like getpeername()/getsockname()

	print "Remote IP is: " . inet_ntoa( ( unpack_sockaddr_in( getpeername( SSLify_GetSocket( $sslified_sock ) ) ) )[1] ) . "\n";

=head2 SSLify_GetSSL

Returns the actual Net::SSLeay object so you can call methods on it

	print Net::SSLeay::dump_peer_certificate( SSLify_GetSSL( $sslified_sock ) );

=head2 SSLify_GetStatus

Returns the status of the SSL negotiation/handshake/connection. See L<http://www.openssl.org/docs/ssl/SSL_connect.html#RETURN_VALUES>
for more info.

	my $status = SSLify_GetStatus( $socket );
		-1 = still in negotiation stage ( or error )
		 0 = internal SSL error, connection will be dead
		 1 = negotiation successful

=head1 NOTES

=head2 Socket methods doesn't work

The new socket this module gives you actually is tied socket magic, so you cannot do stuff like
getpeername() or getsockname(). The only way to do it is to use L</SSLify_GetSocket> and then operate on
the socket it returns.

=head2 Dying everywhere...

This module will die() if Net::SSLeay could not be loaded or it is not the version we want. So, it is recommended
that you check for errors and not use SSL, like so:

	eval { use POE::Component::SSLify };
	if ( $@ ) {
		$sslavailable = 0;
	} else {
		$sslavailable = 1;
	}

	# Make socket SSL!
	if ( $sslavailable ) {
		eval { $socket = POE::Component::SSLify::Client_SSLify( $socket ) };
		if ( $@ ) {
			# Unable to SSLify the socket...
		}
	}

=head3 $IGNORE_SSL_ERRORS

As of SSLify v1.003 you can override this variable to temporarily ignore some SSL errors. This is useful if you are doing crazy things
with the underlying Net::SSLeay stuff and don't want to die. However, it won't ignore all errors as some is still considered fatal.
Here's an example:

	{
		local $POE::Component::SSLify::IGNORE_SSL_ERRORS=1;
		my $ctx = SSLify_CreateContext(...);
		#Some more stuff
	}

=head2 OpenSSL functions

Theoretically you can do anything that Net::SSLeay exports from the OpenSSL libs on the socket. However, I have not tested every
possible function against SSLify, so use them carefully!

=head3 Net::SSLeay::renegotiate

This function has been tested ( it's in C<t/2_renegotiate_client.t> ) but it doesn't work on FreeBSD! I tracked it down to this security
advisory: L<http://security.freebsd.org/advisories/FreeBSD-SA-09:15.ssl.asc> which explains it in detail. The test will skip this function
if it detects that you're on a broken system. However, if you have the updated OpenSSL library that fixes this you can use it.

NOTE: Calling this means the callback function you passed in L</Client_SSLify> or L</Server_SSLify> will not fire! If you need this
please let me know and we can come up with a way to make it work.

=head2 Upgrading a non-ssl socket to SSL

You can have a normal plaintext socket, and convert it to SSL anytime. Just keep in mind that the client and the server must agree to sslify
at the same time, or they will be waiting on each other forever! See C<t/3_upgrade.t> for an example of how this works.

=head2 Downgrading a SSL socket to non-ssl

As of now this is unsupported. If you need this feature please let us know and we'll work on it together!

=head2 MSWin32 is not supported

This module doesn't work on MSWin32 platforms at all ( XP, Vista, 7, etc ) because of some weird underlying fd issues. Since I'm not a windows
developer, I'm unable to fix this. However, it seems like Cygwin on MSWin32 works just fine! Please help me fix this if you can, thanks!

=head2 LOAD_SSL_ENGINES

OpenSSL supports loading ENGINEs to accelerate the crypto algorithms. SSLify v1.004 automatically loaded the engines, but there was some
problems on certain platforms that caused coredumps. A big shout-out to BinGOs and CPANTesters for catching this! It's now disabled in v1.007
and you would need to explicitly enable it.

	sub POE::Component::SSLify::LOAD_SSL_ENGINES () { 1 }
	use POE::Component::SSLify qw( Client::SSLify );

=head1 EXPORT

Stuffs all of the functions in @EXPORT_OK so you have to request them directly.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE|POE>

=item *

L<Net::SSLeay|Net::SSLeay>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc POE::Component::SSLify

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/POE-Component-SSLify>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/POE-Component-SSLify>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-SSLify>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/POE-Component-SSLify>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/POE-Component-SSLify>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/POE-Component-SSLify>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/POE-Component-SSLify>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/POE-Component-SSLify>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=POE-Component-SSLify>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=POE::Component::SSLify>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-poe-component-sslify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-SSLify>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-poe-sslify>

  git clone https://github.com/apocalypse/perl-poe-sslify.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 ACKNOWLEDGEMENTS

	Original code is entirely Rocco Caputo ( Creator of POE ) -> I simply
	packaged up the code into something everyone could use and accepted the burden
	of maintaining it :)

	From the PoCo::Client::HTTP code =]
	# This code should probably become a POE::Kernel method,
	# seeing as it's rather baroque and potentially useful in a number
	# of places.

ASCENT also helped a lot with the nonblocking mode, without his hard work this
module would still be stuck in the stone age :)

A lot of people helped add various features/functions - please look at the changelog for more detail.

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
