#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Net::Async::Keycloak
  Net::Async::Keycloak::Admin
  Net::Async::Keycloak::Auth
  Net::Async::Keycloak::Error
  Net::Async::Keycloak::Error::API
  Net::Async::Keycloak::Error::Network
  Net::Async::Keycloak::Error::Validation
  Net::Async::Keycloak::OIDC
  Net::Async::Keycloak::Role::HTTP
)) {
  use_ok($_);
}

done_testing;
