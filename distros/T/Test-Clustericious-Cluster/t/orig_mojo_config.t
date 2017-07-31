use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(['Foo' => { arg1 => 'one', arg2 => 'two' }]);

my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url")
  ->status_is(200)
  ->content_is('welcome');

$t->get_ok("$url/foo")
  ->status_is(200)
  ->content_is('one');

$t->get_ok("$url/bar")
  ->status_is(200)
  ->content_is('two');

done_testing;

__DATA__

@@ lib/Foo.pm
package Foo;

use 5.010001;
use Mojo::Base qw( Mojolicious );

has 'arg1';
has 'arg2';

sub startup
{
  my($self) = @_;
  $self->routes->get('/' => sub { shift->render(text => 'welcome') });
  $self->routes->get('/foo' => sub { shift->render(text => $self->arg1 // 'undefined') });
  $self->routes->get('/bar' => sub { shift->render(text => $self->arg2 // 'undefined') });
}

1;
