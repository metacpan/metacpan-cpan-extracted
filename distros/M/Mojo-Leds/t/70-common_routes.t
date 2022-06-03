BEGIN {
    use Test::More;

}

our $version = '1.1';
our $package = 'Skel';

package Skel;

our $VERSION = $version;
use Mojo::Base 'Mojo::Leds';

package main;
use Mojo::Base -strict;
use Test::Mojo;
use Net::Domain qw(hostname);

my $t = Test::Mojo->new('Skel');

my $app = $t->app;
my $r   = $app->routes;

$app->plugin('Mojo::Leds::Plugin::CommonRoutes');

$t->get_ok("/version")->status_is(200)->json_is( '/class' => $package )
    ->json_is( '/version' => $version );

$t->get_ok("/status")->status_is(200)->json_is( '/app_name' => $package )
    ->json_is( '/server/hostname' => hostname() )
    ->json_is( '/server/version'  => $version );

$t->get_ok("/routes")->status_is(200)->json_is( '/0/2' => 'version' );
$t->get_ok("/routes.txt")->status_is(200)->content_like(qr{^/version});
$t->get_ok("/routes/CPUW.txt")->status_is(200)
    ->content_like(qr{\^\\/version});
$t->get_ok("/routes/CPUW.json")->status_is(200)
    ->json_like( '/0/4' => qr{\^\\/version} );

done_testing();
