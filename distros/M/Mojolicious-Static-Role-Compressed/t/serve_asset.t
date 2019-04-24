use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

get '/hello' => sub {
    my ($c) = @_;
    my $asset = $c->app->static->file('hello.txt');
    $c->reply->asset($asset);
};
get '/goodbye' => sub {
    my ($c) = @_;
    my $asset = $c->app->static->file('goodbye.txt');
    $c->reply->asset($asset);
};

my $hello_etag          = etag('hello.txt');
my $hello_last_modified = last_modified('hello.txt');

my ($goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip) = etag('goodbye.txt', 'br', 'gzip');
my $goodbye_last_modified = last_modified('goodbye.txt');

my $t = Test::Mojo->new;

# hello.txt has no compressed files
$t->get_ok('/hello' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $hello_etag)
    ->header_is('Last-Modified' => $hello_last_modified)
    ->content_is("Hello Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye')->status_is(200)->content_type_is('text/plain;charset=UTF-8')
    ->header_is(ETag => $goodbye_etag)->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye' => {'Accept-Encoding' => ''})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye' => {'Accept-Encoding' => 'nothing'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/goodbye' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye' => {'Accept-Encoding' => 'gzip, br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye' => {'Accept-Encoding' => 'br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/goodbye' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

done_testing;
