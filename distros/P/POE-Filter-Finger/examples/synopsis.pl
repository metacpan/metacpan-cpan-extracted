   use strict;
   use warnings;
   use POE;
   use POE qw(Filter::Stackable Filter::Line Filter::Finger);
   use Test::POE::Server::TCP;

   POE::Session->create(
     package_states => [
        'main' => [qw(
                        _start
                        testd_client_input
        )],
     ],
   );
   
   $poe_kernel->run();
   exit 0;
   
   sub _start {
     my $heap = $_[HEAP];
     # Spawn the Test::POE::Server::TCP server.
     $heap->{testd} = Test::POE::Server::TCP->spawn(
        address => '127.0.0.1',
        port => 0,
	filter => POE::Filter::Stackable->new(
		Filters => [
			POE::Filter::Line->new(),
			POE::Filter::Finger->new(),
		],
	),
     );
     warn "Listening on port: ", $heap->{testd}->port(), "\n";
     return;
   }
   
   sub testd_client_input {
     my ($kernel,$heap,$sender,$id,$input) = @_[KERNEL,HEAP,SENDER,ARG0,ARG1];

     my $output;

     SWITCH: {
	if ( $input->{listing} ) {
	    $output = 'listing of users rejected';
	    last SWITCH;
	}
	if ( $input->{user} ) {
	    my $username = $input->{user}->{username};
	    $output = "query for information on alleged user <$username> rejected";
	    last SWITCH;
	}
	if ( $input->{forward} ) {
	    $output = 'finger forwarding service denied';
	    last SWITCH;
	}
	$output = 'could not understand query';
     }

     $kernel->post( $sender, 'send_to_client', $id, $output );

     return;
   }

