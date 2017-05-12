package TestClient;
# test client for proxy test - Andrew V. Purshottam
# sends request lines of form count: text 
# to do
# - change approach for validating input to output:
#   instead of trying to deduce expected output from input requests,
#   make log of request lines sent to server. Decorate these
#   lines with per connection (session id?) data.
use warnings;
use strict;
use diagnostics;

# sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use Carp qw(carp croak);
use Data::Dumper;
use POE;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE qw(Component::Server::TCP);
use ClientRequest;
use POE::Component::Proxy::TCP::PoeDebug;

use fields qw(alias port address proxy_client request_list_ref resp_list_ref 
	      test_count number_tests);

sub new {
  my TestClient $self = shift;
  unless (ref $self) {
    $self = fields::new($self);
  }

  # Extract parameters.
  my %param = @_;

  $self->{alias}      = delete $param{Alias};
  $self->{alias} = "test_client_alias" unless defined ($self->{alias});
  dbprint(3, "alias:", $self->{alias});
  $self->{port}      = delete $param{Port};
  $self->{port} = 8000 unless defined ($self->{port});
  dbprint(3, "port", $self->{port});
  $self->{address}      = delete $param{Address};
  $self->{address} = "localhost" unless defined ($self->{address});
  dbprint(3, "address", $self->{address});
  croak "TestClient needs a RequestList parameter" 
    unless exists $param{RequestList};
  $self->{request_list_ref}      = delete $param{RequestList};
  dbprint(10, "request_list_ref:", Dumper($self->{request_list_ref}));
	
  foreach (sort keys %param) {
    carp "TestClient doesn't recognize \"$_\" as a parameter";
  }
			    
  # set up private instance data.
  $self->{resp_list_ref} = [];
  $self->{test_count} = 0;
  $self->{number_tests} = scalar(@{$self->{request_list_ref}});
  dbprint(3, "number_tests: $self->{number_tests}");

  $self->{proxy_client} = 
    POE::Component::Client::TCP->new
	( # Alias => $self->{alias},
	  RemoteAddress => $self->{address},
	  RemotePort => $self->{port},
	  Filter     => "POE::Filter::Line", 
	  Args => [$self],
	  Started => sub {
	    my ( $kernel, $heap, $inner_self) = @_[ KERNEL, HEAP, ARG0];
	    $heap->{self} = $inner_self;
	    dbprint(3, "connected to $inner_self->{address}:$inner_self->{port}"); 
	  },
	  Connected => sub {
	    my ( $kernel, $heap) = @_[ KERNEL, HEAP];
	    dbprint(3, "connected to $self->{address}:$self->{port}");
	    # enqueue events for all test requests...
	    my $base_delay = 0;
	    foreach my $req (@{$self->{request_list_ref}}) {
	      my $req_line = $req->get_request();
	      my $req_delay =  $req->{delay_secs};
	      dbprint(4, "sending req:", $req->dump(), 
		      " as line:$req_line at: $req_delay");

	      $kernel->delay_add("send_server", 
				 $req_delay + $base_delay, 
				 $req_line );
	      $base_delay += $req_delay;
	    }

	    dbprint(4, "**All done for this connection $base_delay");
	    $kernel->delay_add("send_server", $base_delay+2, "END" );

	  },
	  
	  # The connection failed.
	  ConnectError => sub {
	    dbprint(0, "could not connect to $self->{address}:$self->{port}" );
	  },
	  
	  # The remote server has sent us something, so log it in the
	  # resp_list_ref. 
	  ServerInput => sub {
	    my ( $kernel, $heap, $input ) = @_[ KERNEL, HEAP, ARG0 ];
	    if (defined($input)) {
	      dbprint(3, "TestClient got input from server $self->{address} :", 
		"$self->{port}:-$input");
	      if ($input =~ m/^END/) {
		dbprint (1, "Client got END!");
	      } else { 
		push(@{$self->{resp_list_ref}}, $input);
	      }
	    } else {
	      dbprint (1, "ServerInput event but no input!");
	    }
	  },
	  
	  ConnectError => sub  {
	    my ($syscall_name, $error_number, $error_string) = @_[ARG0, ARG1, ARG2];
	    dbprint(1, "ConnectError from ORIG_SERVER on", 
	      " $self->{port} : $self->{address}");
	  },
	  
	  Disconnected   => sub {
	    my ($kernel, $heap) = @_[ KERNEL, HEAP];
	    dbprint(1, "Disconnected from ORIG_SERVER on", 
	      "$self->{port} : $self->{address}");
	    $kernel->yield("validate");
	  },
	  
	  ServerError => sub  {
	    my ($syscall_name, $error_number, $error_string) = @_[ARG0, ARG1, ARG2];
	    dbprint(1, "ServerError from ORIG_SERVER on $self->{port} :",
	      "$self->{address}");
	  },

	  InlineStates =>
	  {             
	   validate => sub {
	     my ($kernel, $heap) = @_[ KERNEL, HEAP];
	     my $self = $heap->{self};
	     my $request_list_ref = $self->{request_list_ref};
	     my $resp_list_ref = $self->{resp_list_ref};
	     dbprint(8, "Comparing ", Dumper($request_list_ref, $resp_list_ref));
	     foreach my $req (@{$request_list_ref}) {
	       my $count = $req->{count};
	       my $ok = 1;
	       for (my $i = 0; $i < $count; $i++) {
		 my $resp_line = shift @{$resp_list_ref};
		 if (!$req->cmp_with_responce($resp_line)) {
		   $ok = 0;
		   dbprint(1, "Bad responce: $resp_line");
		 }
	       }
	       if ($ok) {
		 dbprint(1, "test succeeded!");
	       } else { 
		 dbprint(1, "test failed!\n");
	       }
	       $kernel->post("main", "test_result", $ok, $req->get_test_name());
	       $self->{test_count}++;
	       if ($self->{number_tests} == $self->{test_count}) {
		 $kernel->post("main", "client_done");
	       }
	       
	     }
	   },
	   
	   send_server => sub {
	     my ( $heap, $message ) = @_[ HEAP, ARG0 ];
	     dbprint(3,  "sending from test client to server:$self->{address}:$self->{port}:",
	       "mess:$message");
	     if ($heap->{connected}) {
	       $heap->{server}->put($message);
	     } else {
	       dbprint(3, "send_server error not connected to server.");
	     }
	   },
	  }
	);
  
  return $self;
}

1;

