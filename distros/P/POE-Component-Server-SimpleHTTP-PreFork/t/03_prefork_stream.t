use strict;
use Test::More;

BEGIN {
   eval { require IPC::Shareable; };
   plan skip_all => 'IPC::Shareable is required for this test' if $@;
}

plan tests => 3;

use HTTP::Request;
use POE;
use POE::Kernel;
use POE::Component::Client::HTTP;

eval { use IPC::Shareable; };

skip "Skipping PreFork tests" , 3 if $@;

use POE::Component::Server::SimpleHTTP::PreFork;

my $PORT = 2080;
my $IP = "localhost";

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
    }
}

####################################################################
if ($pid)  # we are parent
{                      
    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

    diag("$$: Sleep 2...");
    sleep 2;
    diag("continue");

	my $states = {
	  _start    => \&_start,
	  response  => \&response,
      quit      => \&quit,
	};
		
   POE::Session->create( inline_states => $states );

   sub _start {
      my ( $kernel, $heap, $session ) = @_[KERNEL, HEAP, SESSION ];
      $kernel->alias_set('TestAgent');
      print "START \n";
      $heap->{'count'} = 1;
      POE::Component::Client::HTTP->spawn(
         Agent     => 'TestAgent',
         Alias     => 'ua',
         Protocol  => 'HTTP/1.1', 
         From      => 'test@tester',
         Streaming => 50,
	 Proxy     => q{},
      );
   
      my $request = HTTP::Request->new(GET => "http://$IP:$PORT/");
      
      diag('Test a stream of 3 helloworlds ..');
      POE::Kernel->post('ua', 'request', 'response', $request);
   }
   
    sub quit {
        exit;
    }

   sub response {
      my ( $kernel, $heap, $session, $request_packet, $response_packet ) 
         = @_[KERNEL, HEAP, SESSION, ARG0, ARG1];
   
      my $return;
   
      # HTTP::Request
      my $request  = $request_packet->[0];
      my $response = $response_packet->[0];
      
      # then all streamed data in the second element of the response
      # array ...
      my ($resp, $data) = @$response_packet;
      chomp($data);
 #     print $data."\n";
      ok($data =~ /Hello World/, "Received a hello")
        if $heap->{'count'} <= 2;
   
      if ($heap->{'count'} == 2) {
         is($heap->{'count'}, 2, "Got 3 streamed helloworlds ... all good :)");
         #exit;
         $kernel->delay_set('quit', 3);
      }
      $heap->{'count'}++;
   }

   POE::Kernel->run;
}

####################################################################
else  # we are the child
{                          
    POE::Component::Server::SimpleHTTP::PreFork->new(
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
                'FORKHANDLERS'          =>      { 'HTTP_GET' => 'FORKED' },
                'MINSPARESERVERS'       =>      1,
                'MAXSPARESERVERS'       =>      3,
                'MAXCLIENTS'            =>      256,
                'STARTSERVERS'          =>      1,
    );
    # Create our own session to receive events from SimpleHTTP
    POE::Session->create(
                inline_states => {
                        '_start'        => sub {   
                           $_[KERNEL]->alias_set( 'HTTP_GET' );
                           $_[KERNEL]->yield('keepalive');
                        },
                  		'GOT_MAIN'	   =>	\&GOT_MAIN,
                  		'GOT_STREAM'	=>	\&GOT_STREAM,
		                  keepalive      => \&keepalive,
                        'quit'          => \&quit,
                },   
    );
    
    POE::Kernel->run;
}


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
    
    # We are done!
   $kernel->yield('GOT_STREAM', $response);
}

sub quit {
    POE::Kernel->call('HTTPD', 'SHUTDOWN');
    exit;
}

sub GOT_STREAM {
   my ( $kernel, $heap, $response ) = @_[KERNEL, HEAP, ARG0];

   # lets go on streaming ...
   if ($heap->{'count'} <= 2) {
      my $text = "Hello World ".$heap->{'count'}." \n";
    #  print "send ".$text."\n";
      $response->content($text);
      
      $heap->{'count'}++;
      POE::Kernel->post('HTTPD', 'STREAM', $response);
   }
    else {
      POE::Kernel->post('HTTPD', 'CLOSE', $response );
        $kernel->delay_set('quit', 1);
    }
}

sub keepalive { 
   $_[KERNEL]->delay_set('keepalive', 1);
}
