use strict;
use warnings;

use Net::Prometheus;

my $client = Net::Prometheus->new;

$client->new_gauge(
   name => "ten",
   help => "The number ten",
)->set( 10 );

use Plack::Builder;

builder {
  mount "/metrics" => $client->psgi_app,
  sub { [ 500, [], [] ] }
};
