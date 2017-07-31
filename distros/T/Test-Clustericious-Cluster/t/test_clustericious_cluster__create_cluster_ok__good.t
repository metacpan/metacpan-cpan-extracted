use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;

is(
  intercept { Test::Clustericious::Cluster->new->create_cluster_ok( qw( Foo Bar ) ) },
  array {
    event Note => sub {
      call message => match qr{\[extract\] DIR  .*/home/.*/lib$};
    };
    event Note => sub {
      call message => match qr{\[extract\] FILE .*/home/.*/lib/(Foo|Bar)\.pm$};
    };
    event Note => sub {
      call message => match qr{\[extract\] FILE .*/home/.*/lib/(Foo|Bar)\.pm$};
    };
    event Ok => sub {
      call pass => T();
      call name => 'created cluster';
    };
    end;
  },
  'valid config'
);

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
