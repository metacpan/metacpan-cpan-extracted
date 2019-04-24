use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

get '/asset_memory' => sub {
    shift->reply->asset(Mojo::Asset::Memory->new->add_chunk('Hello Mojo from a memory asset!'));
};

my $t = Test::Mojo->new;

$t->get_ok('/asset_memory' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_is('Hello Mojo from a memory asset!');
ok !!$t->tx->res->headers->every_header('Content-Type'),     'content-type header is not set';
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Last-Modified'),    'last-modified header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

done_testing;
