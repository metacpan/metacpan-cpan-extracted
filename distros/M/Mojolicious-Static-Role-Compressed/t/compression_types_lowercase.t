use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed')
    ->compression_types([{ext => 'br', encoding => 'BR'}, {ext => 'gz', encoding => 'GZIP'}]);

my ($goodbye_etag, $goodbye_etag_br, $goodbye_etag_gzip) = etag('goodbye.txt', 'BR', 'GZIP');
my $goodbye_last_modified = last_modified('goodbye.txt');

my $t = Test::Mojo->new;

# test encodings get lowercased for expanded and non-expanded
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'GZIP')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'BR')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");

# test accept-encoding and compression_types both need lowercased
$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'GzIP'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'GZIP')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

$t->get_ok('/goodbye.txt' => {'Accept-Encoding' => 'Br'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'BR')
    ->header_is(ETag => $goodbye_etag_br)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a br file!\n");

done_testing;
