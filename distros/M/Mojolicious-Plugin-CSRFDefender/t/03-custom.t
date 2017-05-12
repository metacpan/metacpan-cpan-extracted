package t::CSRFDefender::Custom;
use strict;
use warnings;

use Test::More tests => 16;

use Mojolicious::Lite;
use Test::Mojo;

# configure routing
get '/get' => 'get';
any [qw(get post)] => '/post' => sub {
    my $self = shift;
    $self->stash('token' => $self->session('session-csrftoken'));
} => 'post';

# load plugin
plugin 'Mojolicious::Plugin::CSRFDefender' => {
    parameter_name => 'param-csrftoken',
    session_key    => 'session-csrftoken',
    token_length   => 40,
    error_status   => 400,
    error_content  => 'Bad Request',
};

# forbidden unless session
my $t = Test::Mojo->new;
$t->post_ok('/post')->status_is(400)->content_like(qr{Bad Request});

# no csrf_token if form method is get
$t->get_ok('/get')->status_is(200)->content_like(qr{(?!param-csrftoken)});

# set csrf_token param and session if form method is post
$t->get_ok('/post')->status_is(200)->element_exists('form input[name="param-csrftoken"]');
my $body = $t->tx->res->body;
my ($token_param) = $body =~ /name="param-csrftoken" value="(.*?)"/;
like $token_param, qr{^[a-zA-Z0-9_]{40}$}, 'valid token';

# check session
my ($s_token) = $body =~ m{<span>session-token:(.*?)</span>};
like $s_token, qr{^[a-zA-Z0-9_]{40}$}, 'valid session token';

# forbidden unless csrf_token parameter
$t->post_ok('/post')->status_is(400)->content_like(qr{Bad Request});

# can access if exists csrf_token session and parameter
$t->post_ok('/post' => form => {'param-csrftoken' => $token_param})
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
    <span>session-token:<%= $token %></span>
  </body>
</html>
