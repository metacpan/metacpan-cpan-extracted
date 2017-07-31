use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo Bar ));

note "url: $_" for @{ $cluster->apps };

is(
  $cluster->apps,
  array {
    item object {
      prop blessed => 'Foo';
    };
    item object {
      prop blessed => 'Bar';
    };
  },
  'apps',
);

is $cluster->index, 1, 'index';

done_testing;

__DATA__

@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

sub startup
{
  my $self = shift;
  $self->routes->get('/' => sub {
    shift->render(text => "Foo");
  });
}

1;

@@ lib/Bar.pm
package Bar;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

sub startup
{
  my $self = shift;
  $self->routes->get('/' => sub {
    shift->render(text => "Bar");
  });
}

1;
