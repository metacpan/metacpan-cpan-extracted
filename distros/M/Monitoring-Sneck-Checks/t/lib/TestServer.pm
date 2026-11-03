package TestServer;

# Forks a server on 127.0.0.1 for tests.

use strict;
use warnings;
use IO::Socket::IP;

# Starts a server and returns its port and PID. It greets each client
# with greeting, answers each line with the answers given, keyed by the
# line without the line ending, and closes on QUIT or the client going.
#
# Args...
#
#     - greeting :: Sent on connect, may be undef.
#
#     - answers :: Hash ref of line to answer.
#
#     - ssl :: Hash ref of IO::Socket::SSL args, such as SSL_cert_file,
#       for a TLS server.
#
#     - handler :: Code ref given each client, in the clear, in place of
#       all of the above.
sub start {
	my (%opts) = @_;

	my $listen = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1 )
		or die( 'can not listen, ' . $@ );
	my $port = $listen->sockport;
	my $pid  = fork();
	die( 'can not fork, ' . $! ) if !defined($pid);
	if ($pid) {
		close($listen);
		return ( $port, $pid );
	}

	if ( $opts{ssl} ) {
		require IO::Socket::SSL;
	}

	# a client that goes right after the TLS handshake, as the certificate checks do, leaves the
	# write of the greeting or of the TLS shutdown to get EPIPE, which must not end the server
	$SIG{PIPE} = 'IGNORE';
	while (1) {
		my $client = $listen->accept or next;
		if ( $opts{handler} ) {
			$client->autoflush(1);
			$opts{handler}->($client);
			close($client);
			next;
		}
		if ( $opts{ssl} ) {
			IO::Socket::SSL->start_SSL( $client, SSL_server => 1, %{ $opts{ssl} } ) or next;
		}
		$client->autoflush(1);
		print $client $opts{greeting} if defined( $opts{greeting} );
		while ( my $line = <$client> ) {
			$line =~ s/\r?\n\z//;
			last                                if $line eq 'QUIT';
			print $client $opts{answers}{$line} if defined( $opts{answers}{$line} );
		}
		close($client);
	} ## end while (1)
} ## end sub start

1;
