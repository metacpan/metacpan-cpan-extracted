#!/usr/bin/env perl
#
# Make sure IO::Socket::SSL is installed and start with
#
# ./eg/auth.pl daemon -l https://*:8081

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

use Mojolicious::Lite;
use Net::Salesforce;
use Mojo::URL;
use DDP;

app->helper(
    'sf' => sub {
        my $self = shift;
        Net::Salesforce->new(
            'key'          => $ENV{SFKEY},
            'secret'       => $ENV{SFSECRET},
            'redirect_uri' => 'https://localhost:8081/callback',
            'api_host'      => 'https://cs7.salesforce.com/',
        );
    }
);

get '/' => sub {
  my ($c) = @_;
} => 'index';

post '/auth' => sub {
    my ($c) = @_;
    return $c->redirect_to(app->sf->authorize_url);
};

get '/callback' => sub {
  my ($c) = @_;
  my $authorization_code = $c->param('code');
  my $payload = app->sf->authenticate($authorization_code);
  $c->stash(oauth => $payload);
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
% use DDP;
% p $oauth;
<html><head><title>Callback</title></head>
<body>
<h1>Authenticated</h1>
<p>Your access_token is: <%= $oauth->{access_token} %></p>
<p>Your refresh_token is: <%= $oauth->{refresh_token} %></p>
</body>
</html>
