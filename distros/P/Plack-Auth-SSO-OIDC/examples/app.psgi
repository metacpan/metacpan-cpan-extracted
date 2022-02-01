#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(:5.10);
use Plack::Builder;
use Plack::Auth::SSO::OIDC;
use Plack::Session::Store::File;
use Data::Dumper;

my $uri_base = "http://localhost:5000";

builder {

    enable "Session",
        store => Plack::Session::Store::File->new();

    mount "/auth/oidc" => Plack::Auth::SSO::OIDC->new(
        uri_base => $uri_base,
        authorization_path => "/auth/callback",
        error_path => "/auth/error",
        openid_uri => "https://example.oidc.org/auth/oidc/.well-known/openid-configuration",
        client_id => "my-client-id",
        client_secret => "myclient-secret",
        uid_key => "email"
    )->to_app();

    mount "/auth/callback" => sub {
        my $env = shift;
        my $session = Plack::Session->new($env);
        [ 200, [ "Content-Type" => "text/plain" ], [
            Dumper($session)
        ]];
    };

    mount "/auth/error" => sub {

        my $env = shift;
        my $session = Plack::Session->new($env);
        my $auth_sso_error = $session->get("auth_sso_error");

        unless ( $auth_sso_error ) {

            return [ 302, [ Location => "$uri_base/" ], [] ];

        }

        [ 200, [ "Content-Type" => "text/plain" ], [
            $auth_sso_error->{content}
        ]];

    };
};
