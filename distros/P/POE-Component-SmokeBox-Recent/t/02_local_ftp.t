use strict;
use warnings;
use Test::More;
#sub POE::Component::Client::FTP::DEBUG () { 1 }
use POE qw(Component::SmokeBox::Recent);
use Test::POE::Server::TCP;

my @data = qw(
MIRRORING.FROM
RECENT
RECENT.html
authors/00whois.html
authors/00whois.xml
authors/01mailrc.txt.gz
authors/02STAMP
authors/RECENT-1M.yaml
authors/RECENT-1Q.yaml
authors/RECENT-1W.yaml
authors/RECENT-1d.yaml
authors/RECENT-1h.yaml
authors/RECENT-6h.yaml
authors/id/A/AA/AAU/MRIM/CHECKSUMS
authors/id/A/AA/AAU/MRIM/Net-MRIM-1.10.meta
authors/id/A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
authors/id/A/AD/ADAMK/CHECKSUMS
authors/id/A/AD/ADAMK/ORLite-1.17.meta
authors/id/A/AD/ADAMK/ORLite-1.17.readme
authors/id/A/AD/ADAMK/ORLite-1.17.tar.gz
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.06.meta
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.06.readme
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.07.meta
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.07.readme
authors/id/A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
authors/id/A/AD/ADAMK/YAML-Tiny-1.36.meta
authors/id/A/AD/ADAMK/YAML-Tiny-1.36.readme
authors/id/A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
authors/id/J/JO/JONATHAN/Perl6/CHECKSUMS
authors/id/J/JO/JONATHAN/Perl6/NativeCall-v1.tar.gz
);

my $size = length( join "\n", @data );

my @tests = qw(
A/AA/AAU/MRIM/Net-MRIM-1.10.tar.gz
A/AD/ADAMK/ORLite-1.17.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.06.tar.gz
A/AD/ADAMK/Test-NeedsDisplay-1.07.tar.gz
A/AD/ADAMK/YAML-Tiny-1.36.tar.gz
);

my %tests = (
   'USER anonymous'     => '331 Any password will work',
   'PASS anon@anon.org' => '230 Any password will work',
#   'SIZE /pub/CPAN/RECENT' => '213 ' . $size,
   'QUIT'               => '221 Goodbye.',
);

plan tests => 9;

POE::Session->create(
   package_states => [
	main => [qw(
			_start
			_stop
			testd_registered
			testd_connected
			testd_disconnected
			testd_client_input
                        testd_client_input
                        datac_socket_failed
                        datac_connected
                        datac_client_flushed
			_recent
		)],
   ],
   heap => { tests => \%tests, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{url} = "ftp://127.0.0.1:$port/pub/CPAN/";
  return;
}

sub _stop {
  pass("Done");
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::SmokeBox::Recent->recent(
      url => $heap->{url},
      event => '_recent',
      context => 'Blah Blah Blah',
  );
  return;
}

sub testd_connected {
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
  $heap->{testd}->send_to_client( $id, $_ ) for @banner;
  return;
}

sub testd_disconnected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass("Client disconnected");
  $heap->{testd}->shutdown();
  delete $heap->{testd};
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($input);
  if ( defined $heap->{tests}->{ $input } ) {
     pass($input);
     my $response = delete $heap->{tests}->{ $input };
     $heap->{testd}->disconnect( $id ) unless scalar keys %{ $heap->{tests} };
     $heap->{testd}->send_to_client( $id, $response );
  }
  if ( $input =~ /^PASV/ ) {
     $heap->{client} = $id;
     $heap->{datac} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	prefix => 'datac',
     );
     my $port = $heap->{datac}->port;
     $heap->{testd}->send_to_client( $id, '227 Entering Passive Mode (' . join(',', split(/\./,'127.0.0.1'), (int($port / 256), $port % 256) ) . ').' );
  }
  if ( $input =~ /^RETR/ ) {
    $heap->{testd}->send_to_client( $heap->{client}, '150 Opening ASCII mode data connection for file list' );
    $heap->{client} = $id;
    return unless $heap->{dataconn};
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
  $heap->{testd}->send_to_client( $heap->{client}, '226 Closing data connection.' );
  $heap->{datac}->shutdown();
  delete $heap->{datac};
  return;
}

sub _recent {
  my ($heap,$hashref) = @_[HEAP,ARG0];
  ok( $hashref->{recent}, 'We got a RECENT listing' );
  is_deeply( $hashref->{recent}, \@tests, 'What we got matched' );
  ok( $hashref->{context} eq 'Blah Blah Blah', 'Context was okay' );
#  $heap->{testd}->shutdown();
#  delete $heap->{testd};
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
