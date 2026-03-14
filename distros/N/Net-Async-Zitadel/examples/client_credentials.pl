#!/usr/bin/env perl

# client_credentials.pl — Obtain an access token via client credentials grant
#
# Usage:
#   ZITADEL_ISSUER=https://zitadel.example.com \
#   ZITADEL_CLIENT_ID=my-client \
#   ZITADEL_CLIENT_SECRET=my-secret \
#   perl examples/client_credentials.pl

use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::Zitadel;

my $issuer        = $ENV{ZITADEL_ISSUER}        or die "ZITADEL_ISSUER required\n";
my $client_id     = $ENV{ZITADEL_CLIENT_ID}     or die "ZITADEL_CLIENT_ID required\n";
my $client_secret = $ENV{ZITADEL_CLIENT_SECRET} or die "ZITADEL_CLIENT_SECRET required\n";
my $scope         = $ENV{ZITADEL_SCOPE} // 'openid';

my $loop = IO::Async::Loop->new;

my $z = Net::Async::Zitadel->new(issuer => $issuer);
$loop->add($z);

my $token_response = $z->oidc->client_credentials_token_f(
    client_id     => $client_id,
    client_secret => $client_secret,
    scope         => $scope,
)->get;

printf "Access token: %s\n", $token_response->{access_token};
printf "Token type:   %s\n", $token_response->{token_type} // '(none)';
printf "Expires in:   %s seconds\n", $token_response->{expires_in} // '(unknown)';
