use strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Util qw/gunzip gzip/;

get '/' => sub {
    my ($c) = @_;
    my $status = $c->req->json->{status} // 200;
    $c->res->headers->content_encoding($c->req->json->{content_encoding})
        if $c->req->json->{content_encoding};

    if (my $body = $c->req->json->{body}) {
        $c->render(text => $body, status => $status);
    } else {
        $c->render(data => $c->req->json->{data}, status => $status);
    }
};

local $ENV{MOJO_GZIP} = 0;

# Test without plugin does not gzip
my $t = Test::Mojo->new;
my $text = 'a' x 860;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

plugin 'Gzip';

# No gzip in Accept-Encoding header means no gzip
$t->get_ok('/' => { 'Accept-Encoding' => 'nothing' } => json => { body => $text })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# Content below min_size of 860 means no gzip
my $text_below_min_size = 'a' x 859;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text_below_min_size })
  ->content_is($text_below_min_size)
  ->header_is('Content-Length' => length($text_below_min_size))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# Non-200 status code means no gzip
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, status => 201 })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, status => 404 })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, status => 500 })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# Non-empty content encoding means no gzip
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, content_encoding => 'already encoded' })
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# gzip content encoding means no gzip by this plugin
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { data => gzip $text, content_encoding => 'gzip' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_unlike(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# gzip in Accept-Encoding, 200 status, length >= 860, no content_encoding means gzip
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# case doesn't matter for accept encoding
$t->get_ok('/' => { 'Accept-Encoding' => 'Gzip' } => json => { body => $text })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

$t->get_ok('/' => { 'Accept-Encoding' => 'GzIp' } => json => { body => $text })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

done_testing;
