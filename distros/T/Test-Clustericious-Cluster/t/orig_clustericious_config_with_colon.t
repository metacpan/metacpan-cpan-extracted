use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

skip_all 'test requires Clustericious 1.24'
  unless eval q{ use Clustericious 1.24; 1; };

plan 2;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('Foo::Bar');

is $cluster->apps->[0]->config->stuff, 'things', 'found th correct config';

__DATA__

@@ etc/Foo-Bar.conf
---
url: <%= cluster->url %>
stuff: things

@@ lib/Foo/Bar.pm
package Foo::Bar;

use strict;
use warnings;
use base qw( Clustericious::App );

1;
