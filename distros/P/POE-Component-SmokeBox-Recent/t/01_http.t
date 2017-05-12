use strict;
use warnings;
use Test::More;
use POE qw(Component::SmokeBox::Recent::HTTP Filter::HTTP::Parser);
use Test::POE::Server::TCP;
use HTTP::Date qw( time2str );
use HTTP::Response;

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

plan tests => 9 + scalar @data;

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
			http_response
			_default
		)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::HTTP::Parser->new( type => 'server' ),
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
  my $uri = URI->new();
  $uri->scheme( 'http' );
  $uri->host( '127.0.0.1' );
  $uri->path( '/pub/CPAN/RECENT' );
  $uri->port( $heap->{remote_port} );
  my $ftp = POE::Component::SmokeBox::Recent::HTTP->spawn(
	uri  => $uri,
  );
  isa_ok( $ftp, 'POE::Component::SmokeBox::Recent::HTTP' );
  return;
}

sub testd_connected {
  my ($kernel,$heap,$id,$client_ip,$client_port,$server_ip,$server_port) = @_[KERNEL,HEAP,ARG0..ARG4];
  diag("$client_ip,$client_port,$server_ip,$server_port\n");
  pass("Client connected");
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
  my ($kernel,$heap,$id,$req) = @_[KERNEL,HEAP,ARG0,ARG1];
  diag($req->as_string);
  isa_ok( $req, 'HTTP::Request' );
  is( $req->method, 'GET', 'Method was GET' );
  is( $req->uri->path, '/pub/CPAN/RECENT', 'Correct PATH requested' );
  ok( $req->header( 'Host' ), 'There was a Host header' );
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->header('Content-Type', 'text/plain');
  $resp->header('Date', time2str(time));
  $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
  $resp->header('Connection', 'close');
  $resp->content( join "\n", @data );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $heap->{testd}->send_to_client( $id, $resp );
  return;
}

sub http_response {
  my ($kernel,$heap,$resp) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $resp, 'HTTP::Response' );
  my @content = split /\n/, $resp->content;
  foreach my $line ( @content ) {
     is( $line, shift @data, $line );
  }
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
