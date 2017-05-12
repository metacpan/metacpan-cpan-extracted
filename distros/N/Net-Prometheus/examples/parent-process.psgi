use strict;
use warnings;

use Net::Prometheus;
use Net::Prometheus::ProcessCollector;

my $client = Net::Prometheus->new;

$client->register( Net::Prometheus::ProcessCollector->new(
   prefix => "parent_process",
   pid => getppid(),
) );

use Plack::Builder;

builder {
  mount "/metrics" => $client->psgi_app,
  sub { [ 500, [], [] ] }
};
