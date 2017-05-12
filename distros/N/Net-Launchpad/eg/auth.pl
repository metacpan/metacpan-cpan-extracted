#!/usr/bin/env perl

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojolicious::Lite;
use Net::Launchpad;
use Mojo::URL;
use Data::Dumper::Concise;
use feature qw[say];

my $callback_uri = "http://localhost:3000/callback";
my $consumer_key = "Net-Launchpad";

app->helper(
    lp => sub {
        my $self = shift;
        Net::Launchpad->new(
            consumer_key => $consumer_key,
            callback_uri => $callback_uri
        );
    }
);


get '/' => sub {
  my ($c) = @_;
} => 'index';

post '/auth' => sub {
    my ($c) = @_;
    my ($token, $secret) = app->lp->request_token;
    $c->session('consumer_key' => $consumer_key);
    $c->session('token' => $token);
    $c->session('secret' => $secret);
    return $c->redirect_to(app->lp->authorize_token($token, $secret));
};

get '/callback' => sub {
  my ($c) = @_;
  my ($access_token, $access_token_secret) = app->lp->access_token($c->session('token'), $c->session('secret'));
  $c->stash(consumer_key => $c->session('consumer_key'));
  $c->stash(access_token => $access_token);
  $c->stash(access_token_secret => $access_token_secret);
} => 'authenticated';

app->start;

__DATA__

@@ index.html.ep
<html><head><title>index</title></head>
<body>
<form method="post" action="/auth">
<button type="submit">Auth</button>
</form>
</body>
</html>

@@ authenticated.html.ep
<html><head><title>Callback</title></head>
<body>
<h1>Authenticated</h1>
<p>Your consumer_key is: <%= $consumer_key %></p>
<p>Your access_token is: <%= $access_token %></p>
<p>Your access_token_secret is: <%= $access_token_secret %></p>
</body>
</html>
