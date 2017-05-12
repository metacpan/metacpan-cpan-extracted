use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

plan 7;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_cluster_ok(
  [ MyApp1 => { ua1 => $cluster->_add_ua } ],
  [ MyApp2 => { ua1 => $cluster->_add_ua } ],
);

my $t = $cluster->t;

our @urls = @{ $cluster->urls };

$t->get_ok("$urls[0]/end_of_road")
  ->status_is(200)
  ->content_is('now, light our darkest hour');

$t->get_ok("$urls[0]/redirect1")
  ->status_is(200)
  ->content_is('([now, light our darkest hour])');

__DATA__

@@ lib/MyApp1.pm
package MyApp1;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

has 'ua1';

sub startup
{
  my($self) = @_;
  $self->routes->get('/redirect1' => sub {
    my($c) = @_;
    $c->render(text => '(' . $self->ua1->get("$main::urls[1]/redirect2")->res->body . ')');
  });
  $self->routes->get('/end_of_road' => sub {
    my $c = shift;
    $c->render(text => 'now, light our darkest hour');
  });
}

1;

@@ lib/MyApp2.pm
package MyApp2;

use strict;
use warnings;
use Mojo::Base qw( Mojolicious );

has 'ua1';

sub startup
{
  my($self, $config) =@_;
  $self->routes->get('/redirect2' => sub {
    my($c) = @_;
    $c->render(text => '[' . $self->ua1->get("$main::urls[0]/end_of_road")->res->body . ']');
  });
}

1;
