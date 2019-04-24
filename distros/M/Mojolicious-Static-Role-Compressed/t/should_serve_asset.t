use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

my ($goodbye_etag, $goodbye_etag_br) = etag('goodbye.txt', 'br');
my $goodbye_last_modified = last_modified('goodbye.txt');

my ($yo_etag, $yo_etag_br) = etag('yo.txt', 'br');
my $yo_last_modified = last_modified('yo.txt');

my $t = Test::Mojo->new;

app->static->should_serve_asset(undef);
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

app->static->should_serve_asset(0);
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

app->static->should_serve_asset('0' => {'Accept-Encoding' => 'br, gzip'});
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

app->static->should_serve_asset('');
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

app->static->should_serve_asset(1);
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

app->static->should_serve_asset(sub {1});
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

app->static->should_serve_asset(sub { $_->path =~ /goodbye\.txt$/ });
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

app->static->should_serve_asset(sub { $_->path =~ /yo\.txt$/ });
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

done_testing;
