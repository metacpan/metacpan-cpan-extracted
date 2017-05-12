use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

skip_all 'Test requires Clustericious 1.24'
  unless eval q{ use Clustericious 1.24; 1 };

plan 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo Foo Foo ));

foreach my $index (0..2)
{
  subtest "client $index" => sub {
    my $client = eval { $cluster->client($index) };
    diag $@ if $@;
    isa_ok $client, 'Clustericious::Client';
    isa_ok $client, 'Foo::Client';
    is $client->config->url, $cluster->urls->[$index], "client.config.url correct @{[ $cluster->urls->[$index] ]}";
    
    is $client->welcome, 'willkommen', 'client.welcome';
  };
}

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use base qw( Clustericious::App );
use Clustericious::RouteBuilder;

get '/' => sub { shift->render(text => 'willkommen') };

1;


@@ lib/Foo/Client.pm
package Foo::Client;

use strict;
use warnings;
use Clustericious::Client;

route welcome => 'GET', '/';

1;
