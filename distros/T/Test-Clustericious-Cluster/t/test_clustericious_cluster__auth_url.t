use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;

my $e = intercept { $cluster->create_plugauth_lite_ok };

my $url = $cluster->auth_url;
isa_ok $url, 'Mojo::URL';

is(
  $e,
  array {
    event Ok => sub {
      call name => "PlugAuth::Lite instance on $url";
    };
  },
  'URL in create_plugauth_lite_ok matches actual auth_url',
);

done_testing;
