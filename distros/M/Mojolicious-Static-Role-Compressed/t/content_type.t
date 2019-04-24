use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelpers;

local $ENV{MOJO_GZIP} = 0;

app->static->with_roles('+Compressed');

get '/goodbye'      => sub { shift->reply->static('goodbye.txt') };
get '/goodbye_html' => sub {
    my ($c) = @_;
    $c->res->headers->content_type('text/html');
    $c->reply->static('goodbye.txt');
};

my ($goodbye_etag, $goodbye_etag_gzip) = etag('goodbye.txt', 'gzip');
my $goodbye_last_modified = last_modified('goodbye.txt');

my $t = Test::Mojo->new;

$t->get_ok('/goodbye' => {'Accept-Encoding' => ''})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is(ETag => $goodbye_etag)
    ->header_is('Last-Modified' => $goodbye_last_modified)
    ->content_is("Goodbye Mojo from a static file!\n");
ok !!$t->tx->res->headers->every_header('Content-Encoding'), 'content-encoding header is not set';
ok !!$t->tx->res->headers->every_header('Vary'),             'vary header is not set';

# The content-type of the original file (text/plain...) should be used instead of the file that is actually
# served (application/x-gzip).
$t->get_ok('/goodbye' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/plain;charset=UTF-8')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

# we shouldn't overwrite the content type when the user sets it.
$t->get_ok('/goodbye_html' => {'Accept-Encoding' => 'gzip'})->status_is(200)
    ->content_type_is('text/html')->header_is('Content-Encoding' => 'gzip')
    ->header_is(ETag => $goodbye_etag_gzip)->header_is('Last-Modified' => $goodbye_last_modified)
    ->header_is(Vary => 'Accept-Encoding')->content_is("Goodbye Mojo from a gz file!\n");

done_testing;
