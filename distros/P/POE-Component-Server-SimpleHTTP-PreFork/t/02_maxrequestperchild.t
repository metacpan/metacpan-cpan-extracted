use strict;
use Test::More;

BEGIN {
   eval { require IPC::Shareable; };
   plan skip_all => 'IPC::Shareable is required for this test' if $@;
}

plan tests => 2;

use HTTP::Request;
use POE;
use POE::Kernel;
use POE::Component::Client::HTTP;

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

my %options = (
   create      => 'yes',
   exclusive   => 0,
   mode        => 0644,
);

my %test;
tie %test, 'IPC::Shareable', 'data', {%options};

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
      quit		=> \&quit,
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
	 Proxy     => q{},
      );
   
      my $request = HTTP::Request->new(GET => "http://$IP:$PORT/");
      
      $heap->{count} = 0;
      
      diag('Test maxrequestperchild ..');
      POE::Kernel->post('ua', 'request', 'response', $request);
   }
   
   sub quit {
       # print "Trying to shudown the server \n";
       # POE::Kernel->post('HTTPD', 'SHUTDOWN');
       exit;
    }

   sub response {
      my ( $kernel, $heap, $session, $request_packet, $response_packet ) 
         = @_[KERNEL, HEAP, SESSION, ARG0, ARG1];
   
      my $return;
      $heap->{count}++;
      # HTTP::Request
      my $request  = $request_packet->[0];
      my $response = $response_packet->[0];
      
      # the PoCoClientHTTP sends the first chunk in the content
      # of the http response
      my $data = $response->content;
      chomp($data);
      ok($data =~ /this is bonk/, "Response content received");
      
      if ($heap->{count} <= 1) {
         POE::Kernel->post('ua', 'request', 'response', $request);
      }
      else {

        $kernel->delay_set('quit', 5);
        #exit;
	  }
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
                'MAXSPARESERVERS'       =>      10,
                'MAXCLIENTS'            =>      256,
                'STARTSERVERS'          =>      1,
                'MAXREQUESTPERCHILD'    =>      1,
    );
    # Create our own session to receive events from SimpleHTTP
    POE::Session->create(
                inline_states => {
                        '_start'        => sub {   
                           $_[KERNEL]->alias_set( 'HTTP_GET' );
                           $_[KERNEL]->yield('keepalive');
                           $test{requests} = 0;
                           $test{forkeds} = 0;
                        },
                  		'GOT_MAIN'	   =>	\&GOT_MAIN,
                  		'GOT_STREAM'	=>	\&GOT_STREAM,
                  		'FORKED'	=>	\&FORKED,
                        'SHUTDOWN'  => \&shutdown,
                },   
    );
    
    POE::Kernel->run;
}

sub FORKED {
   my( $kernel, $heap) = @_[KERNEL, HEAP];
   
   $test{forkeds}++;
   
   if ($test{requests} == 1) {
      diag("Forked a child.. it's fine");
   }
   elsif ($test{requests} == 2) {
      diag("Forked again child.. it's again fine");
      $test{requests} = 0; # ok that's ugly ..
      #POE::Kernel->post('HTTPD', 'SHUTDOWN');
      $kernel->delay_set('SHUTDOWN', 3);
   }
   
}

sub shutdown {
		POE::Kernel->call('HTTPD', 'SHUTDOWN');
 exit;
}

sub GOT_MAIN {
    # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
    my( $kernel, $heap, $request, $response, $dirmatch ) = @_[KERNEL, HEAP, ARG0 .. ARG2 ];
    
    # Do our stuff to HTTP::Response
    $response->code( 200 );

   $response->content_type("text/plain");
   
   $test{requests}++;
   $response->content("this is bonk");
   $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
