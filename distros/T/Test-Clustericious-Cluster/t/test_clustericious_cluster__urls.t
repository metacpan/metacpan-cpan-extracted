use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Foo Foo ));

note "url: $_" for @{ $cluster->urls };

is(
  $cluster->urls,
  array {
    item object {
      prop blessed => 'Mojo::URL';
      call host => '127.0.0.1';
      call scheme => 'http';
      call path => '';
    };
    item object {
      prop blessed => 'Mojo::URL';
      call host => '127.0.0.1';
      call scheme => 'http';
      call path => '';
    };
    etc;
  },
  'urls',
);

is $cluster->url, $cluster->urls->[1], 'url';

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
