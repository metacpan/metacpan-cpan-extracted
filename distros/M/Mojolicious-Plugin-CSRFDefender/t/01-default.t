package t::CSRFDefender::Base;
use strict;
use warnings;

use Test::More tests => 23;

use Mojolicious::Lite;
use Test::Mojo;

# configure routing
get '/get' => 'get';
any [qw(get post)] => '/post' => 'post';
any [qw(get post)] => '/single-quotes' => 'single_quotes';

# load plugin
plugin 'Mojolicious::Plugin::CSRFDefender';

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

# forbidden unless csrf_token parameter
$t->post_ok('/post')->status_is(403)->content_like(qr{^Forbidden$});

# can access if exists csrf_token session and parameter
$t->post_ok('/post' => form => {csrftoken => $token_param})
  ->status_is(200);

# use same token
$t->get_ok('/post')->status_is(200)->element_exists('form input[name="csrftoken"]');
my $body2 = $t->tx->res->body;
my ($token_param2) = $body2 =~ /name="csrftoken" value="(.*?)"/;
is $token_param2, $token_param;

$t->get_ok('/single-quotes')->status_is(200)
  ->element_exists('form input[name="csrftoken"]')
  ->content_like(qr/name="csrftoken" value="(.*?)"/);

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

@@ single_quotes.html.ep
<html>
  <body>
    <form action='/post' method='post'>
      <input name='text' />
      <input type='submit' value='send' />
    </form>
  </body>
</html>
