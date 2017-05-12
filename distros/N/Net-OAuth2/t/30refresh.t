#!/usr/bin/env perl
use strict;
use warnings FATAL => "all";

use Test::More;
use HTTP::Response;
use JSON;

use Net::OAuth2;
use Net::OAuth2::AccessToken;
use Net::OAuth2::Profile::WebServer;

my $json = JSON->new;

BEGIN {
   eval "require Test::Mock::LWP::Dispatch";
   plan skip_all => "Test::Mock::LWP::Dispatch not installed" if $@;

   Test::Mock::LWP::Dispatch->import;
   plan tests => 7;
}

my $at_response = {
    token_type => 'Bearer',
    expires_in => time(),
    access_token => 'my-new-access-token',
    id_token => 'my-new-id-token',
};

my %p = (
    access_token_path  => "/o/oauth2/token",
    authorize_path     => "/o/oauth2/auth",
    client_id          => "my-id",
    client_secret      => "my-secret",
    refresh_token_path => "/o/oauth2/token",
    scope =>
      "http://www.google.com/reader/api http://www.google.com/reader/atom",
    site => "https://accounts.google.com"
);

$mock_ua->map(
    "$p{site}$p{refresh_token_path}" => sub {
        my $req = shift;
#        diag Dumper $req->content;
        HTTP::Response->new(
            200, "OK",
            [ "content-type" => "application/json", ],
            $json->encode($at_response),
        );
    }
);

my $id     = 'my-id';
my $secret = 'my-secret';
my $access_token_str = 'my-access_token';
my $refresh_token_str = 'my-refresh_token';

ok my $profile = Net::OAuth2::Profile::WebServer->new(%p)
   ,'instantiate Net::OAuth2::Profile::WebServer';

ok my $access_token = Net::OAuth2::AccessToken->new( 
    refresh_token => $refresh_token_str,
    access_token  => $access_token_str,
    profile       => $profile)
   ,'instantiate Net::OAuth2::AccessToken with Webserver Profile';

ok $access_token->refresh, 'access_token->refresh';
is $access_token->access_token, $at_response->{access_token},
  'response access token has been set';

is $access_token->refresh_token, $refresh_token_str,
  'refresh token remains unchanged';

$at_response->{refresh_token} = 'new-refresh-token';
ok $access_token->refresh, 'access_token->refresh';
is $access_token->refresh_token, $at_response->{refresh_token},
  'new response refresh token has been set';

