use strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Mojo::Util qw/gunzip gzip/;

get '/' => sub {
    my ($c) = @_;
    $c->res->headers->etag($c->req->json->{etag})
        if defined $c->req->json->{etag};

    $c->render(text => $c->req->json->{body});
};

local $ENV{MOJO_GZIP} = 0;

plugin 'Gzip';

my $t = Test::Mojo->new;

# Test no gzip means -gzip is not added
my $text_below_min_size = 'a' x 859;
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text_below_min_size, etag => 'abcd' })
  ->content_is($text_below_min_size)
  ->header_is('Content-Length' => length($text_below_min_size))
  ->header_is(ETag => 'abcd')
  ->header_unlike('Content-Encoding' => qr/gzip/)
  ->header_unlike(Vary => qr/Accept-Encoding/);

my $text = 'a' x 860;

# Test that etag is not set with undef etag provided
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_like(ETag => qr/^$/)
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test that etag is not set with empty etag provided
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_like(ETag => qr/^$/)
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test quote of length 1
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '""-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test quote of length 2
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '""' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"""-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test quote of length 3
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"""' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '""-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test a of length 1
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => 'a' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"a-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test a of length 2
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => 'aa' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"aa-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test a of length 3
$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => 'aaa' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"aaa-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

# Test etags surrounded by quotes, the way that they should be

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"a"' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"a-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"ab"' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"ab-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"abc"' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"abc-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

$t->get_ok('/' => { 'Accept-Encoding' => 'gzip' } => json => { body => $text, etag => '"abcd"' })
  ->header_is('Content-Length' => length($t->tx->res->body))
  ->header_is(ETag => '"abcd-gzip"')
  ->header_is('Content-Encoding' => 'gzip')
  ->header_like(Vary => qr/Accept-Encoding/);
is gunzip($t->tx->res->body), $text, 'gunzipped text is equal to original text';

done_testing;
