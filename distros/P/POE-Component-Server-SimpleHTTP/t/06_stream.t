use strict;
use Test::More;

#plan skip_all => 'MSWin32 does not have a proper fork()' if $^O eq 'MSWin32';
BEGIN {
   eval { require POE::Component::Client::HTTP; };
   plan skip_all => 'POE::Component::Client::HTTP is required for this test' if $@;
}

plan tests => 6;

use HTTP::Request;
use POE;
use POE::Kernel;
#sub POE::Component::Server::SimpleHTTP::DEBUG () { 1 }
use POE::Component::Server::SimpleHTTP;

my $PORT = 2080;
my $IP = "localhost";

our %STREAMS;

####################################################################
POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
               		{
               			'DIR'		=>	'.*',
               			'SESSION'	=>	'HTTP_GET',
               			'EVENT'		=>	'GOT_MAIN',
               		},
                ],
		SETUPHANDLER => { SESSION => 'HTTP_GET', EVENT => '_tests', },
);
# Create our own session to receive events from SimpleHTTP
POE::Component::Client::HTTP->spawn(
         Agent     => 'TestAgent',
         Alias     => 'ua',
         Protocol  => 'HTTP/1.1', 
         From      => 'test@tester',
         Streaming => 100,
	 Proxy     => q{},
);

POE::Session->create(
                inline_states => {
                        '_start'        => sub {   
                           $_[KERNEL]->alias_set( 'HTTP_GET' );
                           $_[KERNEL]->yield('keepalive');
			   return;
                        },
			'_tests'     => \&_tests,
                  	'GOT_MAIN'   =>	\&GOT_MAIN,
                  	'GOT_STREAM' =>	\&GOT_STREAM,
		        keepalive    => \&keepalive,
			response     => \&response,
			'_shutdown'  => \&_shutdown,
                        'on_close'   => \&on_close,
                },   
);
    
$poe_kernel->run();

is( 0+keys %STREAMS, 0, "No open streams" );
exit 0;

sub GOT_MAIN {
   # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
   my( $kernel, $heap, $request, $response, $dirmatch ) = @_[KERNEL, HEAP, ARG0 .. ARG2 ];
    
   # Do our stuff to HTTP::Response
   $response->code( 200 );

   $response->content_type("text/plain");
   
   print "# GOT_MAIN \n";
   # sets the response as streamed within our session with the stream event
   $response->stream(
      session     => 'HTTP_GET',
      event       => 'GOT_STREAM'
   );   

   $heap->{'count'} ||= 0;

   my $c = $response->connection;
   $STREAMS{ $c->ID }=1;

   $_[KERNEL]->call( $_[SENDER], 'SETCLOSEHANDLER', $c, 'on_close', $c->ID );
    
    # We are done!
   $kernel->yield('GOT_STREAM', $response);
   return;
}

sub GOT_STREAM {
   my ( $kernel, $heap, $response ) = @_[KERNEL, HEAP, ARG0];

   # lets go on streaming ...
   if ($heap->{'count'} <= 2) {
      my $text = "Hello World ".$heap->{'count'}." \n";
      #print "send ".$text."\n";
      $response->content($text);
      
      $heap->{'count'}++;
      POE::Kernel->post('HTTPD', 'STREAM', $response);
   }
   else {
      $STREAMS{ $response->connection->ID }--;

      POE::Kernel->post('HTTPD', 'CLOSE', $response );
   }
   return;
}

sub keepalive { 
   my $heap  = $_[HEAP];

   $_[KERNEL]->delay_set('keepalive', 1);
   return;
}

sub _shutdown {
  $poe_kernel->alarm_remove_all();
  $poe_kernel->alias_remove( 'HTTP_GET' );
  $poe_kernel->post( 'ua', 'shutdown' );
  $poe_kernel->post( 'HTTPD', 'SHUTDOWN' );
  return;
}

sub _tests {
      my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION ];
      $heap->{'client_count'} = 0;
   
      my $request = HTTP::Request->new(GET => "http://$IP:$PORT/");
      
      diag('Test a stream of 3 helloworlds ..');
      POE::Kernel->post('ua', 'request', 'response', $request);
      return;
}
   
sub response {
      my ( $kernel, $heap, $session, $request_packet, $response_packet ) 
         = @_[KERNEL, HEAP, SESSION, ARG0, ARG1];
   
      my $return;
   
      # HTTP::Request
      my $request  = $request_packet->[0];
      my $response = $response_packet->[0];
      
      # the PoCoClientHTTP sends the first chunk in the content
      # of the http response
      #if ($heap->{'count'} == 1) {
      #   my $data = $response->content;
      #   chomp($data);
#print $data."\n";
       #  ok($data =~ /Hello World 0/, "First one as response content received");
      #}
      
      # then all streamed data in the second element of the response
      # array ...
      my ($resp, $data) = @$response_packet;
      return unless $data;
      chomp($data);
      foreach my $hello ( split /\n/, $data ) {
         ok($hello =~ /Hello World/, "Received a hello");
         $heap->{'client_count'}++;
      }
      if ($heap->{'client_count'} == 3) {
         is($heap->{'client_count'}, 3, "Got 3 streamed helloworlds ... all good :)");
	 $kernel->yield( '_shutdown' );
	 return;
      }
      return;
}

sub on_close {
    my $wid  = $_[ARG0];
    is( $STREAMS{$wid}, 0, "on_close comes after CLOSE" );
    delete $STREAMS{ $wid } if $STREAMS{ $wid } == 0;
}

