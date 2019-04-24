use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

my ($goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip) = etag('goodbye.txt', 'br', 'gzip');
my $goodbye_last_modified = last_modified('goodbye.txt');

my ($yo_etag, $yo_etag_br, $yo_etag_gzip) = etag('yo.txt', 'br', 'gzip');
my $yo_last_modified = last_modified('yo.txt');

my $t = Test::Mojo->new;

# test with no Accept-Encoding
$t->get_ok('/goodbye.txt')->status_is(200)->content_type_is('text/plain;charset=UTF-8')
    ->header_is(ETag => $goodbye_etag)->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt')->status_is(200)->content_type_is('text/plain;charset=UTF-8')
    ->header_is(ETag => $yo_etag)->header_is('Last-Modified' => $yo_last_modified)
    ->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test with empty Accept-Encoding
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => ''})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => ''})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# test with Accept-Encoding that doesn't match any compression_types encodings
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'deflate'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'deflate'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $yo_etag)
    ->header_is('Last-Modified' => $yo_last_modified)->content_is("Yo Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# Send one that doesn't match any compression_type, and one that does
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'deflate, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'deflate, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $yo_etag_gzip)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a gz file!\n");

# send both available Accept-Encoding's
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br, gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

# make sure order in Accept-Encoding doesn't matter
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'gzip, br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'gzip, br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

# only send br
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'br')
    ->header_is(ETag => $yo_etag_br)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a br file!\n");

# only send gzip
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");
$t->get_ok('/yo.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $yo_etag_gzip)->header_is('Last-Modified' => $yo_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Yo Mojo from a gz file!\n");

done_testing;
