use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site');
my $lib  = $site->child('lib')->to_string;
my $www  = $site->child('www')->to_string;
lib->import($lib);
lib->import($www);

my $t = Test::Mojo->new('Skel');
push @{ $t->app->renderer->paths }, $www;

# direct to another controller no link changed
my $r = $t->app->routes;
$r->any('/direct')->to( app => 'welcome::index', action => 'route' )
  ->name('root');
$t->get_ok('/direct')->status_is(200)->content_like(qr/Welcome/i);

# redirect to another controller via 304 with changed location
$r->any('/redirect')->to( cb => sub { shift->redirect_to('/welcome') } );
$t->get_ok('/redirect')->status_is(302)->header_is( location => '/welcome' );

# prove redirect
$t->ua->max_redirects(1);
$t->get_ok('/redirect')->status_is(200)->content_like(qr/Welcome/i);

done_testing();
