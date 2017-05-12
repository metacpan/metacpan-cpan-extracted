package t::CSRFDefender::Onetime;
use strict;
use warnings;

use Test::More tests => 19;

use Mojolicious::Lite;
use Test::Mojo;

# configure routing
get '/get' => 'get';
any [qw(get post)] => '/post' => 'post';

# load plugin
plugin 'Mojolicious::Plugin::CSRFDefender' => {
    onetime => 1,
};

# forbidden unless session
my $t = Test::Mojo->new;
$t->post_ok('/post')->status_is(403)->content_like(qr{^Forbidden$});

# no csrf_token if form method is get
$t->get_ok('/get')->status_is(200)->content_like(qr{(?!csrftoken)});

# set csrf_token param and session if form method is post
$t->get_ok('/post')->status_is(200)->element_exists('form input[name="csrftoken"]');
my $body = $t->tx->res->body;
my ($token_param) = $body =~ /name="csrftoken" value="(.*?)"/;
like $token_param, qr{^[a-zA-Z0-9_]{32}$}, 'valid token';

# can access if exists csrf_token session and parameter
$t->post_ok('/post' => form => {'csrftoken' => $token_param})
  ->status_is(200);

# when access again, token is changed
$t->get_ok('/post')->status_is(200)->element_exists('form input[name="csrftoken"]');
my $body2 = $t->tx->res->body;
my ($token_param2) = $body2 =~ /name="csrftoken" value="(.*?)"/;
like $token_param2, qr{^[a-zA-Z0-9_]{32}$}, 'valid token';
isnt $token_param, $token_param2;

# can access if exists csrf_token session and parameter
$t->post_ok('/post' => form => {'csrftoken' => $token_param2})
  ->status_is(200);

__DATA__;

@@ get.html.ep
<html>
  <body>
    <form action="/get">
      <input name="text" />
      <input type="submit" value="send" />
    </form>
  </body>
</html>

@@ post.html.ep
<html>
  <body>
    <form action="/post" method="post">
      <input name="text" />
      <input type="submit" value="send" />
    </form>
  </body>
</html>
