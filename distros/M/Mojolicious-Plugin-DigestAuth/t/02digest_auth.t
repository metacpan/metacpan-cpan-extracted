use strict;
use warnings;
use lib 't';

use Mojolicious::Lite;

use Test::More tests => 30;
use Test::Mojo;

use TestHelper;

my $t = Test::Mojo->new;
my $url = '/';
any $url => create_action();

$t->get_ok($url)
  ->status_is(401)
  ->content_is('HTTP 401: Unauthorized');

$t->get_ok($url, build_auth_request($t->tx, username => 'sshaw', password => 'bad_bad_bad'))
  ->status_is(401);

$t->get_ok($url, build_auth_request($t->tx, username => 'not_in_realm'))
  ->status_is(401);

$t->get_ok($url, build_auth_request($t->tx, username => '', password => ''))
  ->status_is(401);
    
$t->get_ok($url, build_auth_request($t->tx, algorithm => 'unknown'))
  ->status_is(400)
  ->content_is('HTTP 400: Bad Request');

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, qop => 'unknown')) 
  ->status_is(400);

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx, opaque => 'baaaaahd'))
  ->status_is(400);

$t->get_ok($url)
  ->status_is(401);
$t->get_ok($url, build_auth_request($t->tx))
  ->status_is(200)
  ->content_is("You're in!");

$t->post_ok($url)
  ->status_is(401);
$t->post_ok($url, build_auth_request($t->tx))
  ->status_is(200)
  ->content_is("You're in!");


###
# Not with build_auth_request()
# $url = '/MD5-sess';
# get $url => create_action(algorithm => 'MD5-sess');
							                  
# $t->get_ok($url)    
#   ->status_is(401);
# $t->get_ok($url, build_auth_request($t->tx, algorithm => 'MD5-sess'))
#   ->status_is(200)
#   ->content_is("You're in!");

# $url = '/no_qop';
# get $url => create_action(qop => '');

# $t->get_ok($url)
#   ->status_is(401);
# $t->get_ok($url, build_auth_request($t->tx, qop => ''))
#   ->status_is(200)
#   ->content_is("You're in!");
###


# get '/www-auth' => create_action();
# $t->get_ok('/www-auth')
#   ->status_is(401);

# ## Req
# my $headers = build_auth_request($t->tx);
# $headers->{X_HTTP_AUTHORIZATION} = delete $headers->{Authorization};
# $t->get_ok('/www-auth', $headers)
#   ->status_is(200);
