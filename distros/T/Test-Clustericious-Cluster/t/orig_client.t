use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
BEGIN {
  skip_all 'test requires Clustericious 1.24'
    unless eval q{ 
      use Clustericious 1.24;
      1;
    };
}
use Clustericious::Client;
use Test::Clustericious::Config;
use File::HomeDir;

skip_all 'test requires Clustericious::Client 1.01'
  unless Clustericious::Client->can('_mojo_user_agent_factory');
plan 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('MyApp');

note "etc/MyApp.conf:";
note "  $_" for do {
  open my $fh, '<', "@{[ File::HomeDir->my_home ]}/etc/MyApp.conf";
  <$fh>;
};

require MyApp::Client;

my $client = eval { MyApp::Client->new };
diag $@ if $@;
isa_ok $client, 'MyApp::Client';

is $client->welcome, 'welcome', 'welcome returns welcome';
is $client->version->[0], '1.00', 'version = 1.00';

__DATA__

@@ lib/MyApp.pm
package MyApp;

use Mojo::JSON qw( encode_json );
use Mojo::Base qw( Mojolicious );
use base qw( Clustericious::App );

sub startup
{
  my($self, $config) = @_;
  $self->routes->get('/' => sub { shift->render(text => 'welcome') });
  $self->routes->get('/version' => sub {
    my $c = shift;
    $c->tx->res->headers->content_type('application/json');
    $c->render(text => encode_json([ '1.00' ]));
  });
}

1;

@@ lib/MyApp/Client.pm
package MyApp::Client;
use Clustericious::Client;
route welcome => 'GET', '/';
1;


@@ lib/Clustericious/App.pm
package Clustericious::App;

use base qw( Mojolicious );

1;
