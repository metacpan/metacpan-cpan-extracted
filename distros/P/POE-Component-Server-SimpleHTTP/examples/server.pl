use POE;
use POE::Component::Server::SimpleHTTP;
use Sys::Hostname qw( hostname );

# Start the server!
POE::Component::Server::SimpleHTTP->new(
	'ALIAS'		=>	'HTTPD',
	'ADDRESS'	=>	0,
	'PORT'		=>	8080,
	'HANDLERS'	=>	[
		{
			'DIR'		=>	'^/$',
			'SESSION'	=>	'HTTP_GET',
			'EVENT'		=>	'GOT_MAIN',
		},
		{
			'DIR'		=>	'.*',
			'SESSION'	=>	'HTTP_GET',
			'EVENT'		=>	'GOT_ERR',
		},
	],
	'HEADERS'	=>	{
		'Server'	=>	'My Own Server',
	},
) or die 'Unable to create the HTTP Server';

# Create our own session to receive events from SimpleHTTP
POE::Session->create(
	inline_states => {
		'_start'	=>	sub { $_[KERNEL]->alias_set( 'HTTP_GET' ) },
		'GOT_MAIN'	=>	\&GOT_REQ,
		'GOT_ERR'	=>	\&GOT_ERR,
	},
);

# Start POE!
POE::Kernel->run();

# We're done!
exit;

sub GOT_REQ {
	# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
	my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

	# Do our stuff to HTTP::Response
	$response->code( 200 );
	$response->content( 'Hi, you fetched ' . $request->uri );

	# We are done!
	$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

sub GOT_ERR {
	# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
	my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

	# Check for errors
	if ( ! defined $request ) {
		$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
		return;
	}

	# Do our stuff to HTTP::Response
	$response->code( 404 );
	$response->content( "Hi visitor from " . $response->connection->remote_ip . ", Page not found -> '" . $request->uri->path . "'" );

	# We are done!
	# For speed, you could use $_[KERNEL]->call( ... )
	$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
