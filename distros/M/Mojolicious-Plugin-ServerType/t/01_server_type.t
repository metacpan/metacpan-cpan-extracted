use Mojo::Base -strict;

use Mojolicious::Lite;

use Mojo::Server::Prefork;

use Test::Mojo;
use Test::More;

plugin 'ServerType';

get '/' => sub {
    my $c = shift;

    $c->render( json => {"serverType" => $c->app->server_type } );
};

get '/prefork' => sub {
    my $c = shift;

    $c->app->plugins->emit_hook( before_server_start => Mojo::Server::Prefork->new(), $c->app );

    $c->render( json => {} );
};

is( app->server_type, undef, "The server_type should be undef if not running under a server that supports the 'before_server_start' hook.");

my $t = Test::Mojo->new;

# Test::Mojo appears to use Mojo::Server::Daemon
$t->get_ok('/')
    ->status_is(200)
    ->json_is( { serverType => 'Mojo::Server::Daemon' } );


$t->get_ok('/prefork')
    ->status_is(200);

$t->get_ok('/')
    ->status_is(200)
    ->json_is( { serverType => 'Mojo::Server::Prefork' } );

done_testing();
