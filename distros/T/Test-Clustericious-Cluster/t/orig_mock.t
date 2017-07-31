use Test::Clustericious::Cluster;
use Test2::V0 -no_srand => 1;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_cluster_ok(qw( Foo ));

my $url = $cluster->url;
my $t   = $cluster->t;

$t->get_ok("$url/bar")
  ->status_is(200)
  ->content_is('foo.example.com');

done_testing;

__DATA__

@@ lib/Foo.pm
package Foo;

use Mojo::Base qw( Mojolicious );
use Net::hostent;

sub startup
{
  my($self) = @_;
  
  $self->routes->get('/:host' => sub {
    my $c = shift;

    my $host = gethost($c->param('host'));
    return $c->render_not_found
      unless defined $host;
    return $c->render(text => $host->name);
  });
}

1;

@@ lib/Net/hostent.pm
package Net::hostent;

use strict;
use warnings;
use base qw( Exporter );
our @EXPORT = qw( gethost );

sub gethost
{
  my $input_name = shift;
  return unless $input_name =~ /^(foo|bar|baz|foo.example.com)$/;
  bless {}, 'Net::hostent';
}

sub name { 'foo.example.com' }
sub aliases { qw( foo.example.com foo bar baz ) }

1;
