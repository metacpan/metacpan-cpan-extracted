
use POE;
use POE::Component::Server::Stomp;
use Net::Stomp::Frame;
use Carp;
use strict;

$SIG{__DIE__} = sub {
    Carp::confess(@_);
};

POE::Component::Server::Stomp->new(
	HandleFrame        => \&handle_frame,
	ClientDisconnected => \&client_disconnected,
	ClientError        => \&client_error,
);

POE::Kernel->run();
exit;

sub handle_frame
{
	my ($kernel, $heap, $frame) = @_[ KERNEL, HEAP, ARG0 ];

	print "RECIEVED FRAME:\n";
	print $frame->as_string . "\n";

	# Just for fun, we pretend to play along with the STOMP protocol.

	my $response;

	if ( $frame->command eq 'CONNECT' )
	{
		$response = Net::Stomp::Frame->new({
			command => 'CONNECTED',
		});
	}

	if ( $response )
	{
		$heap->{client}->put( $response );
	}
}

sub client_disconnected
{
	my ($kernel, $heap) = @_[ KERNEL, HEAP ];

	print "CLIENT DISCONNECTED\n";
}

sub client_error
{
	my ($kernel, $name, $number, $message) = @_[ KERNEL, ARG0, ARG1, ARG2 ];

	print "ERROR: $name $number $message\n";
}

