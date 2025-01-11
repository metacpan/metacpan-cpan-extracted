#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Module::Load 'load';
use Mojolicious::Lite;
use Try::Tiny;

use FindBin qw($Bin);
use lib "$Bin/lib/MyCatalystApp/lib";

my @required_modules = qw(
  Catalyst::Runtime
  Catalyst::Action::RenderView
  Catalyst::Plugin::ConfigLoader
  Catalyst::Plugin::Session::Store::FastMmap
  Catalyst::Plugin::Static::Simple
  Catalyst::View::JSON
  Config::General
  Test::WWW::Mechanize::Catalyst::WithContext
);
my @missing_modules;
foreach my $module (@required_modules) {
  try {
    load $module;
  }
  catch {
    push @missing_modules, $module;
  };
}
if (@missing_modules) {
  plan skip_all => sprintf('%s %s required', join(', ', @missing_modules),
                                                        @missing_modules > 1 ? 'are' : 'is');
}

local $ENV{MOJO_LOG_LEVEL} = 'error';

# provider server routes
get('/wellknown' => sub {
  my $c = shift;
  my %url = (
    authorization_endpoint => '/authorize',
    end_session_endpoint   => '/logout',
    token_endpoint         => '/token',
    userinfo_endpoint      => '/userinfo',
    jwks_uri               => '/jwks',
  );
  $c->render(json => {map { $_ => $url{$_} } keys %url});
});
# get '/authorize' in MyCatalystApp/Controller/Root.pm (ugly but necessary)
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
$mock_oidc_client->redefine('user_agent' => app->ua);

my $mock_plugin = Test::MockModule->new('OIDC::Client::Plugin');
$mock_plugin->redefine('_generate_uuid_string' => sub { 'fake_uuid' });

my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'MyCatalystApp' );

$mech->get_ok('/',
              'get public index page');

$mech->content_like(qr/Welcome/,
                    'expected text for index page');

# invalid token format
$mech->get('/protected');
is($mech->status(), 401,
   'expected status');
$mech->content_is('Authentication Error',
                  'expected error message');

$mock_oidc_client->redefine('decode_jwt' => sub {
  {
    'iss'   => 'my_issuer',
    'exp'   => 12345,
    'aud'   => 'my_id',
    'sub'   => 'my_subject',
    'nonce' => 'fake_uuid',
  }
});

$mech->get_ok('/protected?a=b&c=d',
              'get protected page');

$mech->content_is('my_subject is authenticated',
                  'expected text');
like($mech->c->req->uri, qr[/protected\?a=b&c=d$],

     'keep initial url');

done_testing;
