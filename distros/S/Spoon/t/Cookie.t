use strict;
use Test::More tests => 2;
use Spoon::Cookie;

my $cookie = Spoon::Cookie->new;
$cookie->write("foo", { bar => "baz" });

my @cookies = $cookie->set_cookie_headers;
like $cookies[1]->[0]->as_string, qr/foo=/;

$cookie->write("foo", { bar => "baz" }, { -domain => "www.example.com" });
@cookies = $cookie->set_cookie_headers;
like $cookies[1]->[0]->as_string, qr/domain=www\.example\.com/;

