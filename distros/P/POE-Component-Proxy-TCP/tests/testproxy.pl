#!/usr/bin/perl
# single process regression tester for the PoCO::Proxy::TCP
# sets up system with server, proxy, one or more clients
# and tests to see if the clients get what they expect back from server.

# Andrew Purshottam Jun 2004
# to do:
# -fix debugging print to show module and session, zap all print (done)
# - multiple sinultaneous conncections don't work! (they do actually,
#     but your test code had race conditions.) 
#   is this the fault of the TestServer, the TestClient (DTS?)
#   the proxy or both server and proxy (cause they use PoCo::S:TCP?
# - make system shut down gracefully at end so it can be a unit test.
# - add event handlers for _child _default to main session (done)
# - add destructors to all class oriented modules
# - lookup for resource leaks and under-references (places you need
#     to put a POEish thingy on a parents heap.)

use warnings;
use strict;
use diagnostics;
use Getopt::Std;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE::Component::Proxy::TCP;
use Data::Dumper;
use POSIX;
use Test::More qw(no_plan);
use Getopt::Std;

use lib qw(../inc);
use POE::Component::Proxy::TCP::PoeDebug; 
use TestServer;
use TestClient;
use ClientRequest;

$|++;  
my %opts;
getopts('d:', \%opts);
# shut up so test frame is not confused
$opts{'d'} = 0 unless defined($opts{'d'});

set_level($opts{'d'});

# create inital session
POE::Session->create
(inline_states =>
 { _start => sub {
     my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];
     my $status = $kernel->alias_set("main");
     my $server = TestServer->new(Port => 5000);
     $heap->{server} = $server;
     $heap->{proxy} = POE::Component::Proxy::TCP->new
       ( Alias => "ProxyServerSessionAlias",
	 Port               => 4000,
	 OrigPort           => 5000,
	 OrigAddress        => "localhost",
	 InlineStates       => {  },
	 
	 DataFromClient    => sub {
	   my $s = shift; 
	   dbprint(3, "**from client $s"); 
	 },
	 
	 DataFromServer    => sub {
	   my $s = shift; 
	   dbprint(3, "**from server $s"); 
	 },

       );
     # make sure 
     $kernel->delay_add( "start_client", 3);
   },
   client_done => sub {
     my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];
     $heap->{client_count}++;
     if ($heap->{client_count} == $heap->{number_clients}) {
       exit(0);
     }
   },
   test_result => sub {
     my ( $kernel, $session, $heap, $ok, $test_name ) =
       @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
     ok($ok, $test_name);
   },
   start_client => sub {
     my ( $kernel, $session, $heap ) = @_[KERNEL, SESSION, HEAP];
     $heap->{client_count} = 0;  # so we know when to shutn down
     $heap->{number_clients} = 0;# number of test clients run below, counted as generated.

     # test client #1
     my $request_list_ref1 = [ClientRequest->new(Count => 15,
						Text => "client #1 request #1!",
						DelaySecs => 2),
		 	     ClientRequest->new(Count => 6,
 						Text => "Client #1 request #2",
 						DelaySecs => 4),
			     ];
     my $client1 = TestClient->new(Port => 4000, 
				   RequestList => $request_list_ref1);
     $heap->{client1} = $client1;
     $heap->{number_clients}++;
     
     # test client #2
     my $request_list_ref2 = [ClientRequest->new(Count => 5,
						   Text => "client #2 request #1!",
						   DelaySecs => 2),
				ClientRequest->new(Count => 6,
   						Text => "client #2 request #2!",
   						DelaySecs => 4),
			       ];
     my $client2 = TestClient->new(Port => 4000, 
				     RequestList => $request_list_ref2);
     $heap->{client2} = $client2;
     $heap->{number_clients}++;

   },
   
   # Dummy states to prevent warnings.
   _stop   => sub { return 0 },
   _child  => sub { },
 },
);

$poe_kernel->run();
exit 0;


