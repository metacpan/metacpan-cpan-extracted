#!/usr/bin/env perl
use Mojo::Base;
use Test::Mojo;
use Test::More;
use Test::MockModule;

use Mojolicious::Lite;

# client server routes
get('/protected' => sub {
      my $c = shift;
      if (my $identity = $c->oidc->get_stored_identity()) {
        $c->render(text => $identity->{subject} . ' is authenticated');
      }
      else {
        $c->oidc->redirect_to_authorize();
      }
    });
get('/error/:code' => sub {
      my $c = shift;
      $c->log->warn("OIDC error : " . $c->flash('error_message'));
      $c->render(text   => 'Authentication Error',
                 status => $c->stash('code'));
    });

# provider server routes
get('/authorize' => sub {
      my $c = shift;
      my $redirect_uri  = $c->param('redirect_uri');
      my $client_id     = $c->param('client_id');
      my $state         = $c->param('state');
      my $response_type = $c->param('response_type');
      if ($response_type eq 'code' && $client_id eq 'my_id') {
        $c->redirect_to("$redirect_uri?client_id=$client_id&state=$state&code=abc&iss=my_issuer");
      }
      else {
        $c->redirect_to("$redirect_uri?error=error");
      }
    });
post('/token' => sub {
       my $c = shift;
       my $grant_type    = $c->param('grant_type');
       my $client_id     = $c->param('client_id');
       my $client_secret = $c->param('client_secret');
       my $code          = $c->param('code');
       if ($grant_type eq 'authorization_code'
           && $client_id eq 'my_id' && $client_secret eq 'my_secret'
           && $code eq 'abc') {
         $c->render(json => {id_token      => 'my_id_token',
                             access_token  => 'my_access_token',
                             refresh_token => 'my_refresh_token',
                             scope         => 'openid profile email',
                             token_type    => 'Bearer',
                             expires_in    => 3599});
       }
       else {
         $c->render(json => {error             => 'error',
                             error_description => 'error_description'},
                    status => 401);
       }
     });

my $mock_oidc_client = Test::MockModule->new('OIDC::Client');
$mock_oidc_client->redefine('kid_keys' => sub { {} });

my $mock_plugin = Test::MockModule->new('OIDC::Client::Plugin');
$mock_plugin->redefine('_generate_uuid_string' => sub { 'fake_uuid' });

plugin 'OIDC' => {
  authentication_error_path => '/error/401',
  provider => {
    my_provider => {
      id                   => 'my_id',
      issuer               => 'my_issuer',
      secret               => 'my_secret',
      authorize_url        => '/authorize',
      token_url            => '/token',
      userinfo_url         => '/userinfo',
      end_session_url      => '/logout',
      jwks_url             => '/jwks',
      signin_redirect_path => '/oidc/login/callback',
      scope                => 'openid profile email',
    },
  }
};

my $t = Test::Mojo->new(app);
$t->ua->max_redirects(3);

# invalid token format
$t->get_ok('/protected')
  ->status_is(401)
  ->content_is('Authentication Error');

$mock_oidc_client->redefine('decode_jwt' => sub {
  {
    'iss'   => 'my_issuer',
    'exp'   => 12345,
    'aud'   => 'my_id',
    'sub'   => 'my_subject',
    'nonce' => 'fake_uuid',
  }
});

$t->get_ok('/protected?a=b&c=d')
  ->status_is(200)
  ->content_is('my_subject is authenticated');

like($t->tx->req->url, qr[/protected\?a=b&c=d$],
     'keep initial url');

done_testing;
