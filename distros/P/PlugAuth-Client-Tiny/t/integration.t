use strict;
use warnings;
use Test::More;
use PlugAuth::Client::Tiny;

BEGIN {
  my $code = q{
    use Test::Clustericious::Blocking;
    use Test::Clustericious::Cluster 0.25;
    use Clustericious 1.06;
    use PlugAuth 0.32;
    1;
  };

  my $diag = 'Test::Clustericious::Blocking, Test::Clustericious::Cluster 0.25, Clustericious 1.06 and PlugAuth 0.32';

  plan skip_all => "Test requires $diag" unless eval $code;
}

plan tests => 6;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster = $cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client::Tiny->new(
  url => $cluster->url
);

is blocking { $client->version }, PlugAuth->VERSION, "client.version = @{[ PlugAuth->VERSION ]}";
is blocking { $client->auth('charliebrown', 'snoopy') }, 1, 'good password';
is blocking { $client->auth('charliebrown', 'bogus') },  0, 'bad password';
is blocking { $client->authz('charliebrown', 'bar', '/foo') }, 1, 'good authz';
is blocking { $client->authz('charliebrown', 'barx', '/fxoo') }, 0, 'bad authz';

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
user_file: <%= home %>/var/data/user
resource_file: <%= home %>/var/data/resource


@@ var/data/user
charliebrown:snCedLzbuy6yg


@@ var/data/resource
/foo (bar) : charliebrown
