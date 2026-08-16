#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use POTest;
use POUA;
use MockIdP;

# The github preset is plain OAuth2: no id_token, identity from the
# user API. MockIdP serves the GitHub shapes at /user and /user/emails.

my $idp_app = MockIdP::app();
my $ua = POUA->new(map => { idp_origin() => $idp_app });

my @logins;
{
    package GithubApp;
    use Punk;
    use Punk::Plugin::OAuth2;
    session secret => 'github-secret';
    plugin 'OAuth2';
    oauth2 github => {
        preset                 => 'github',
        authorization_endpoint => "$MockIdP::ISSUER/authorize",
        token_endpoint         => "$MockIdP::ISSUER/token",
        identity_endpoint      => "$MockIdP::ISSUER/user",
        emails_endpoint        => "$MockIdP::ISSUER/user/emails",
        client_id              => $MockIdP::CLIENT_ID,
        client_secret          => $MockIdP::CLIENT_SECRET,
        allow_local            => 1,
        ua                     => $ua,
    };
    oauth2_login '/auth' => {
        on_login => sub { push @logins, $_[1]; return },
        base_url => POTest::client_origin(),
    };
}
my $app = GithubApp->to_app;

{
    MockIdP::reset_state();
    my %jar;
    my ($status, $headers) = run_login($app, $idp_app,
                                       cookies => \%jar,
                                       start => '/auth/github');
    is $status, 302, 'github-preset login completes';
    is scalar @logins, 1, 'on_login called';
    my $id = $logins[0];
    is $id->{provider}, 'github', 'provider name';
    is $id->{sub}, '7', 'sub is the numeric id, stringified';
    is $id->{email}, 'alice@example.com',
        'primary email picked from /user/emails';
    ok $id->{email_verified}, 'primary email verified flag';
    is $id->{name}, 'Alice', 'name mapped';
    is $id->{raw}{login}, 'alice', 'raw user payload preserved';
}

# no nonce parameter for a non-OIDC provider
{
    MockIdP::reset_state();
    my %jar;
    my ($s, $h) = POTest::hit($app, GET => '/auth/github',
                              cookies => \%jar);
    unlike $h->{location}, qr/[?&]nonce=/,
        'no nonce on a plain OAuth2 authorize URL';
    like $h->{location}, qr/code_challenge_method=S256/,
        'PKCE still always on';
}

done_testing();
