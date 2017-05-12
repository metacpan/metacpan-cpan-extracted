use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Clustericious::Cluster;
BEGIN {
  skip_all 'test requires Clustericious 1.24'
    unless eval q{ 
      use Clustericious 1.24;
      1;
    };
}

plan 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok( qw( Foo Bar ) );

is(
  $cluster->client(0),
  object {
    prop blessed => 'Foo::Client';
  },
  'client(0)',
);

is(
  $cluster->client(1),
  object {
    prop blessed => 'Clustericious::Client';
  },
  'client(1)',
);

is(
  $cluster->client(2),
  undef,
  'client(2)',
);

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use base qw( Clustericious::App );

1;


@@ lib/Foo/Client.pm
package Foo::Client;
use Clustericious::Client;
route welcome => 'GET', '/';
1;


@@ lib/Bar.pm
package Bar;

use strict;
use warnings;
use base qw( Clustericious::App );

1;

