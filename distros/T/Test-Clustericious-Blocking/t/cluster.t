use Test2::Bundle::Extended;
use Test::Clustericious::Blocking;
use HTTP::Tiny;
use JSON::PP qw( decode_json );

BEGIN {
  my $code = q{
    use Test::Clustericious::Cluster 0.35;
    use Clustericious 1.24;
    1;
  };
  
  skip_all 'Test requires Test::Clustericious::Cluster 0.35 and Clustericious 1.24'
    unless eval $code;
}

plan tests => 3;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('MyApp');

my $url = $cluster->url;
my $client = HTTP::Tiny->new;

is blocking { $client->get("$url/foo")->{content} }, 'a response', '/foo';
is blocking { shift @{ decode_json $client->get("$url/version")->{content} } }, '1.00', '/version';

done_testing;

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>


@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
use MyApp::Routes;

our $VERSION = '1.00';

1;


@@ lib/MyApp/Routes.pm
package MyApp::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;

get '/foo' => sub {
  shift->render(text => 'a response');
};

1;
