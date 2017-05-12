use strict;
use warnings;
use Test::More tests => 15;
#sub POE::Component::Client::FTP::DEBUG () { 1 }
use POE qw(Component::Client::FTP Filter::Line);
use Test::POE::Server::TCP;

my %tests = (
   'USER anonymous' 	=> '331 Any password will work',
   'PASS anon@anon.org' => '230 Any password will work',
   'QUIT' 		=> '221 Goodbye.',
);

POE::Session->create(
   package_states => [
	main => [qw(
			_start 
			_stop
			ftpd_registered 
			ftpd_connected
			ftpd_disconnected
			ftpd_client_input
                        ftpd_client_input
                        datac_socket_failed
                        datac_connected
                        datac_client_flushed
			connected
			authenticated
                        dir_connected
                        dir_data
                        dir_done
		)],
   ],
   heap => { tests => \%tests, types => [ [ '200', 'Type set to A' ], [ '200', 'Type set to I' ] ] },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{ftpd} = Test::POE::Server::TCP->spawn(
#    filter => POE::Filter::Line->new,
    address => '127.0.0.1',
    prefix  => 'ftpd',
  );
  my $port = $heap->{ftpd}->port;
  $heap->{remote_port} = $port;
  return;
}

sub _stop {
  pass("Done");
  return;
}

sub ftpd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::Client::FTP->spawn(
        Alias => 'ftpclient' . $_[SESSION]->ID(),
        Username => 'anonymous',
        Password => 'anon@anon.org',
        RemoteAddr => '127.0.0.1',
	RemotePort => $heap->{remote_port},
        Events => [qw(
			connected 
			connect_error 
			authenticated 
			login_error 
                        dir_connected
                        dir_data
                        dir_done
		  )],
        Filters => { get => POE::Filter::Line->new(), },
  );
  return;
}

sub ftpd_connected {
  my ($kernel,$heap,$id,$client_ip,$client_port,$server_ip,$server_port) = @_[KERNEL,HEAP,ARG0..ARG4];
  diag("$client_ip,$client_port,$server_ip,$server_port\n");
  my @banner = (
	'220---------- Welcome to Pure-FTPd [privsep] ----------',
	'220-You are user number 228 of 1000 allowed.',
	'220-Local time is now 18:46. Server port: 21.',
	'220-Only anonymous FTP is allowed here',
	'220 You will be disconnected after 30 minutes of inactivity.',
  );
  pass("Client connected");
  $heap->{ftpd}->send_to_client( $id, $_ ) for @banner;
  return;
}

sub ftpd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($input);
  if ( defined $heap->{tests}->{ $input } ) {
     pass($input);
     my $response = delete $heap->{tests}->{ $input };
     $heap->{ftpd}->disconnect( $id ) unless scalar keys %{ $heap->{tests} };
     $heap->{ftpd}->send_to_client( $id, $response );
  }
  if ( $input =~ /^PASV/ ) {
     $heap->{client} = $id;
     $heap->{datac} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	prefix => 'datac',
     );
     my $port = $heap->{datac}->port;
     $heap->{ftpd}->send_to_client( $id, '227 Entering Passive Mode (' . join(',', split(/\./,'127.0.0.1'), (int($port / 256), $port % 256) ) . ').' );
  }
  if ( $input =~ /^NLST/ ) {
    $heap->{ftpd}->send_to_client( $heap->{client}, '150 Opening ASCII mode data connection for file list' );
    $heap->{client} = $id;
    return unless $heap->{dataconn};
    my @data = qw(
        RECENT
        modules
        authors
    );
    $heap->{datac}->send_to_client( $heap->{dataconn}, shift @data );
    $heap->{nlst} = \@data;
  }
  return;
}

sub datac_socket_failed {
}

sub datac_connected {
  my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
#  diag("Data connection: $id\n");
  $heap->{dataconn} = $id;
  return;
}

sub datac_client_flushed {
  my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
  my $data = shift @{ $heap->{nlst} };
  if ( $data ) {
    $heap->{datac}->send_to_client( $id, $data );
    return;
  }
  delete $heap->{nlst};
  $heap->{ftpd}->send_to_client( $heap->{client}, '226 Closing data connection.' );
  $heap->{datac}->shutdown();
  delete $heap->{datac};
  return;
}

sub ftpd_disconnected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass("Disconnected");
  $heap->{ftpd}->shutdown();
  return;
}

sub connected {
  my ($numeric,$message) = @_[ARG0,ARG1];
  ok( $numeric eq '220', 'Correct connection numeric' );
  ok( $message eq 'You will be disconnected after 30 minutes of inactivity.', $message );
  return;
}

sub authenticated {
  my ($kernel,$sender,$numeric,$message) = @_[KERNEL,SENDER,ARG0,ARG1];
  ok( $numeric eq '230', 'Correct authentication numeric' ); 
  ok( $message eq 'Any password will work', $message );
  $kernel->post( $sender, 'dir' );
  return;
}

sub dir_connected {
  pass("Server connected to data port");
  return;
}

sub dir_data {
  pass("Data: " . $_[ARG0]);
  diag($_[ARG0] . "\n");
  return;
}

sub dir_done {
  my ($kernel,$heap,$sender) = @_[KERNEL,HEAP,SENDER];
  pass("dir done");
  $kernel->post( $sender, 'quit' );
  return;
}

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     return 0 if $event eq '_child';
     my @output = ( "$event: " );

     for my $arg (@$args) {
         if ( ref $arg eq 'ARRAY' ) {
             push( @output, '[' . join(' ,', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     print join ' ', @output, "\n";
     return 0;
 }
