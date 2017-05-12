use strict;
use warnings;
use lib 't';

use Mojolicious::Lite;
use Test::More tests => 68;
use Test::Mojo;

use TestHelper;

my $url = '/';
get $url => create_action();

# # Mojo related URL handling
my $t = Test::Mojo->new;
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);
    
$t->get_ok($url)
    ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => '//'))
    ->status_is(200);

SKIP: {
    skip 'Mojo::Parameters bug causes test to fail prior to v1.45', 4 if !eval { Mojolicious->VERSION(1.45) };
    $t->get_ok($url)
      ->status_is(401);
    $t->get_ok($url, build_auth_request($t->tx, uri => '/?'))
      ->status_is(200);
}

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => 'http://a.com'))
  ->status_is(200);
    
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => 'http://a.com/'))
  ->status_is(200);
    
$url = '/?a=b';
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => '//?a=b'))
  ->status_is(200);
    
$url = '/?a=b%20c';
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => 'http://a.com?a=b%20c'))
  ->status_is(200);
    
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => 'http://a.com?a=b c'))
  ->status_is(200);

$url = '/a/b';
get $url => create_action();

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);
    
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => '//a///b'))
  ->status_is(200);
    
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => 'http://a.com//a///b'))
  ->status_is(200);

# REQUEST_URI
$url = '/request_uri';
get $url => create_action(env => { REQUEST_URI => "$url?x=y" });

$url .= '?x=y';
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);

# SCRIPT_NAME
$url = '/script.pl';
get $url => create_action(env => { SCRIPT_NAME => '/script.pl' });
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);

# SCRIPT_NAME + PATH_INFO
$url = '/script.pl/path';
get $url => create_action(env => { SCRIPT_NAME => 'script.pl', PATH_INFO => '/path' });
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);

# SCRIPT_NAME + PATH_INFO + QUERY_STRING
$url = '/script.pl/path/info';
get $url => create_action(env => { SCRIPT_NAME => 'script.pl', PATH_INFO => '/path/info', QUERY_STRING => 'x=y' });
$url .= '?x=y';
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => $url))
  ->status_is(200);

# Digest URL does not match
$url = '/bad';
get $url => create_action();
$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => ''))
  ->status_is(400);

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, uri => "$url?x=y"))
  ->status_is(400);
