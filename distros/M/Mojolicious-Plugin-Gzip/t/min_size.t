use strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Util qw/gunzip gzip/;

get '/' => sub {
    my ($c) = @_;
    $c->render(text => $c->req->body);
};

local $ENV{MOJO_GZIP} = 0;

plugin 'Gzip';

my $t = Test::Mojo->new;

# Test one below minimum doesn't work
my $text = 'a' x 859;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# At min_size gzips
$text = 'a' x 860;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# One above min_size gzips
$text = 'a' x 861;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test setting min_size
plugin 'Gzip' => {min_size => 500};

# Test one below minimum doesn't work
$text = 'a' x 499;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->content_is($text)
  ->header_is('Content-Length' => length($text))
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

# At min_size gzips
$text = 'a' x 500;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# One above min_size gzips
$text = 'a' x 501;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => $text)
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is('Content-Encoding' => 'gzip');
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

done_testing;
