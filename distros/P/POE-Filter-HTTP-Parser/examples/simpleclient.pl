use strict;
use warnings;
use URI;
use HTTP::Request;
use POE;
use POE::Filter::HTTP::Parser;
use Test::POE::Client::TCP;

$|=1;

my $link = shift;
die "You must provide a url to fetch\n" unless $link;
my $uri = URI->new($link);
die "Can't handle that scheme sorry\n" unless $uri->scheme eq 'http';

POE::Session->create(
   package_states => [
	main => [qw(_start webc_connected webc_input)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{webc} = Test::POE::Client::TCP->spawn(
        address         => $uri->host,
        port            => $uri->port,
        autoconnect     => 1,
        prefix          => 'webc',
        filter          => POE::Filter::HTTP::Parser->new( debug => 1 ),
  );
  return;
}

sub webc_connected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $req = HTTP::Request->new( GET => ( $uri->path || '/' ) );
  $req->header( 'Host', $uri->host_port );
  $req->protocol( 'HTTP/1.1' );
  $heap->{webc}->send_to_server( $req );
  return;
}

sub webc_input {
  my ($heap,$input) = @_[HEAP,ARG0];
  print $input->as_string;
  $heap->{webc}->shutdown();
  delete $heap->{webc};
  return;
}
