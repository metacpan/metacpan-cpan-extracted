use POE;
use POE::Component::Server::SimpleHTTP;
use Sys::Hostname qw( hostname );

# Start the server!
POE::Component::Server::SimpleHTTP->new(
	'ALIAS'		=>	'HTTPD',
	'ADDRESS'	=>	127.0.0.1,
	'PORT'		=>	8080,
	'HANDLERS'	=>	[
		{
			'DIR'		=>	'.*',
			'SESSION'	=>	'HTTP_GET',
			'EVENT'		=>	'GOT_MAIN',
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
		'GOT_MAIN'	   =>	\&GOT_REQ,
		'GOT_STREAM'	=>	\&GOT_STREAM,
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
   
   $response->content_type("text/plain");
   
   # sets the response as streamed within our session with the stream event
   $response->stream(
      session  => 'HTTP_GET',
      event    => 'GOT_STREAM'
   );   

	# We are done!
	$_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

sub GOT_STREAM {
   my ( $kernel, $heap, $stream ) = @_[KERNEL, HEAP, ARG0];
   
   # the stream hash contains the wheel, the request, the response 
   # and an id associated the the wheel
   $stream->{'wheel'}->put("Hello World\n");

   # lets go on streaming ...
   POE::Kernel->delay('GOT_STREAM', 1, $stream );
}
