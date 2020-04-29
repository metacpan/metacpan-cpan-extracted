use strict;
use warnings;

use Net::Prometheus;

use IO::Async::Loop;
use Net::Async::HTTP::Server::PSGI;

use Metrics::Any::Adapter 'Prometheus';

use constant LISTEN_PORT => 8200;

my $client = Net::Prometheus->new;

$client->new_gauge(
   name => "ten",
   help => "The number ten",
)->set( 10 );

my $loop = IO::Async::Loop->new;

my $httpserver = Net::Async::HTTP::Server::PSGI->new(
   app => $client->psgi_app,
);
$loop->add( $httpserver );
$httpserver->listen(
   addr => { family => "inet6", socktype => "stream", port => LISTEN_PORT }
)->get;

$loop->run;
