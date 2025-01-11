#!/usr/bin/env perl
use Mojo::Base;
use Test::Mojo;
use Test::More;
use Test::MockModule;

use Try::Tiny;
use Mojolicious::Lite;

# resource server routes
get('/my-resource' => sub {
      my $c = shift;

      my $user = try {
        $c->oidc->verify_token();
        return $c->oidc->build_user_from_userinfo();
      }
      catch {
        $c->log->warn("Token/User validation : $_");
        $c->render(json => {error => 'Unauthorized'}, status => 401);
        return;
      } or return;

      unless ($user->has_role('role2')) {
        $c->log->warn("Insufficient roles");
        $c->render(json => {error => 'Forbidden'}, status => 403);
        return;
      }

      $c->render(json => {user_login => $user->login});
    });

# provider server routes
get('/userinfo' => sub {
      my $c = shift;

      my $authorization = $c->req->headers->authorization;

      if ($authorization eq 'Bearer Doe') {
        $c->render(json => {
          sub       => 'DOEJ',
          firstName => 'John',
          lastName  => 'Doe',
          roles     => [qw/app.role1 app.role2/],
        });
      }
      elsif ($authorization eq 'Bearer Smith') {
        $c->render(json => {
          sub       => 'SMITHL',
          firstName => 'Liam',
          lastName  => 'Smith',
          roles     => [qw/app.role3/],
        });
      }
      else {
        $c->render(json => {error             => 'SearchError',
                            error_description => 'User not found'},
                   status => 404);
      }
    });

my $mock_oidc_client = Test::MockModule->new('OIDC::Client');
$mock_oidc_client->redefine('kid_keys'    => sub { {} });
$mock_oidc_client->redefine('has_expired' => sub { 0 });

plugin 'OIDC' => {
  provider => {
    my_provider => {
      id           => 'my_id',
      issuer       => 'my_issuer',
      secret       => 'my_secret',
      role_prefix  => 'app.',
      userinfo_url => '/userinfo',
      jwks_url     => '/jwks',
      claim_mapping => {
        login     => 'sub',
        lastname  => 'lastName',
        firstname => 'firstName',
        email     => 'email',
        roles     => 'roles',
      },
    },
  }
};

$mock_oidc_client->redefine('decode_jwt' => sub {
  {
    'iss'   => 'my_issuer',
    'exp'   => 12345,
    'aud'   => 'my_id',
    'sub'   => 'my_subject',
    'nonce' => 'fake_uuid',
  }
});

my $t = Test::Mojo->new(app);

$t->get_ok('/my-resource' => {Authorization => 'Bearer Unknown'})
  ->status_is(401)
  ->json_is('/error' => 'Unauthorized');

$t->get_ok('/my-resource' => {Authorization => 'Bearer Smith'})
  ->status_is(403)
  ->json_is('/error' => 'Forbidden');

$t->get_ok('/my-resource' => {Authorization => 'Bearer Doe'})
  ->status_is(200)
  ->json_is('/user_login' => 'DOEJ');

done_testing;
