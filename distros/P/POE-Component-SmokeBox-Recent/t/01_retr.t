use strict;
use warnings;
use Test::More;
#sub POE::Component::Client::FTP::DEBUG () { 1 }
use POE qw(Component::SmokeBox::Recent::FTP Filter::Line);
use Test::POE::Server::TCP;

my @data = qw(
MIRRORED.BY
MIRRORING.FROM
RECENT
RECENT.html
SITES
SITES.html
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
authors/id/A/AA/AAU/MRIM/Net-MRIM-1.11.meta
authors/id/A/AA/AAU/MRIM/Net-MRIM-1.11.tar.gz
authors/id/A/AB/ABELTJE/snapdir/CHECKSUMS
authors/id/A/AB/ABH/CHECKSUMS
authors/id/A/AB/ABH/Geo-Coder-Yahoo-0.43.meta
authors/id/A/AB/ABH/Geo-Coder-Yahoo-0.43.tar.gz
authors/id/A/AC/ACID/CHECKSUMS
authors/id/A/AC/ACID/Hyper-v0.05.meta
authors/id/A/AC/ACID/Hyper-v0.05.readme
authors/id/A/AC/ACID/Hyper-v0.05.tar.gz
authors/id/A/AD/ADAMK/CHECKSUMS
authors/id/A/AD/ADAMK/ORDB-CPANTS-0.01.meta
authors/id/A/AD/ADAMK/ORDB-CPANTS-0.01.readme
authors/id/A/AD/ADAMK/ORDB-CPANTS-0.01.tar.gz
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.01.meta
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.01.readme
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.01.tar.gz
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.02.meta
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.02.readme
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.02.tar.gz
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.03.meta
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.03.readme
authors/id/A/AD/ADAMK/ORDB-CPANTesters-0.03.tar.gz
authors/id/A/AD/ADAMK/ORLite-1.18.meta
authors/id/A/AD/ADAMK/ORLite-1.18.readme
authors/id/A/AD/ADAMK/ORLite-1.18.tar.gz
authors/id/A/AD/ADAMK/ORLite-Mirror-0.08.meta
authors/id/A/AD/ADAMK/ORLite-Mirror-0.08.readme
authors/id/A/AD/ADAMK/ORLite-Mirror-0.08.tar.gz
authors/id/A/AD/ADAMK/ORLite-Mirror-0.09.meta
authors/id/A/AD/ADAMK/ORLite-Mirror-0.09.readme
authors/id/A/AD/ADAMK/ORLite-Mirror-0.09.tar.gz
authors/id/A/AD/ADAMK/ORLite-Pod-0.01.meta
authors/id/A/AD/ADAMK/ORLite-Pod-0.01.readme
authors/id/A/AD/ADAMK/ORLite-Pod-0.01.tar.gz
authors/id/A/AD/ADAMK/ORLite-Pod-0.02.meta
authors/id/A/AD/ADAMK/ORLite-Pod-0.02.readme
authors/id/A/AD/ADAMK/ORLite-Pod-0.02.tar.gz
authors/id/A/AD/ADAMK/ORLite-Pod-0.05.meta
authors/id/A/AD/ADAMK/ORLite-Pod-0.05.readme
authors/id/A/AD/ADAMK/ORLite-Pod-0.05.tar.gz
authors/id/A/AD/ADAMK/ORLite-Pod-0.06.meta
authors/id/A/AD/ADAMK/ORLite-Pod-0.06.readme
authors/id/A/AD/ADAMK/ORLite-Pod-0.06.tar.gz
authors/id/A/AD/ADIRAJ/CHECKSUMS
authors/id/A/AD/ADRIANWIT/CHECKSUMS
authors/id/A/AD/ADRIANWIT/Test-DBUnit-0.19.meta
authors/id/A/AD/ADRIANWIT/Test-DBUnit-0.19.readme
authors/id/A/AD/ADRIANWIT/Test-DBUnit-0.19.tar.gz
authors/id/A/AE/AECOOPER/monotone/CHECKSUMS
authors/id/A/AJ/AJUNG/CHECKSUMS
authors/id/A/AL/ALEXMV/CHECKSUMS
authors/id/J/JO/JONATHAN/Perl6/CHECKSUMS
authors/id/J/JO/JONATHAN/Perl6/NativeCall-v1.tar.gz
);

my $size = length( join "\n", @data );

my %tests = (
   'USER anonymous' 	=> '331 Any password will work',
   'PASS anon@anon.org' => '230 Any password will work',
#   'SIZE /pub/CPAN/RECENT' => '213 ' . $size,
   'QUIT' 		=> '221 Goodbye.',
);

plan tests => 8 + scalar @data;

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
			ftp_data
			ftp_done
		)],
   ],
   heap => { tests => \%tests, types => [ [ '200', 'Type set to A' ], [ '200', 'Type set to I' ] ] },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
#    filter => POE::Filter::Line->new,
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{remote_port} = $port;
  return;
}

sub _stop {
  pass("Done");
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $ftp = POE::Component::SmokeBox::Recent::FTP->spawn(
        address => '127.0.0.1',
	port => $heap->{remote_port},
	path => '/pub/CPAN/RECENT',
  );
  isa_ok( $ftp, 'POE::Component::SmokeBox::Recent::FTP' );
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

sub ftp_data {
  pass($_[ARG0]);
  return;
}

sub ftp_done {
  pass($_[STATE]);
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
