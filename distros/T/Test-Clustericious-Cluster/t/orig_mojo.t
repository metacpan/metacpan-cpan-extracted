use strict;
use warnings;
use 5.010001;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

plan 9;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(
  'Foo',
  'Bar',
);

my $t = $cluster->t;
$t->get_ok($cluster->urls->[0])
  ->status_is(200)
  ->content_is('Foo');

$t->get_ok($cluster->urls->[1])
  ->status_is(200)
  ->content_is('Bar');

# make sure autoextraction worked
like $INC{'Foo.pm'}, qr{/lib/Foo\.pm$}, "Foo.pm looks like it was read from a real placew";
ok   -f $INC{'Foo.pm'},                 "Foo.pm is a real file";

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
