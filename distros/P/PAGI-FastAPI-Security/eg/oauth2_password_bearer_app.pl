#!/usr/bin/env perl

# Run with: pagi-server eg/oauth2_password_bearer_app.pl
#
# Demonstrates PAGI::FastAPI::Security::OAuth2::PasswordBearer, which
# extracts a bearer token exactly like HTTPBearer but also carries
# token_url/scopes metadata describing an OAuth2 password flow.
#
# NOTE: OAuth2::PasswordBearer does not implement a token endpoint,
# that's your application's job. This example adds a toy POST /token
# endpoint that issues a signed JWT after checking a hardcoded user
# store, purely to make the flow runnable end-to-end. A real app would
# check against a proper user store with hashed passwords.
#
# Try it:
#   TOKEN=$(curl -s -X POST http://127.0.0.1:5000/token \
#       -d 'username=alice&password=wonderland' \
#       | perl -MJSON::PP=decode_json -E '$/=undef; say decode_json(<STDIN>)->{access_token}')
#
#   curl -H "Authorization: Bearer $TOKEN"  http://127.0.0.1:5000/me
#   curl -H "Authorization: Bearer garbage" http://127.0.0.1:5000/me

use v5.36;
use Future::AsyncAwait;
use Types::Standard qw(Str);
use Crypt::JWT qw(encode_jwt decode_jwt);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::OAuth2::PasswordBearer;

use constant JWT_SECRET => 'demo-shared-secret';

# In a real app, load this from a database with hashed passwords.
use constant USERS => {
    alice => { password => 'wonderland', role => 'admin' },
    bob   => { password => 'builder',    role => 'viewer' },
};

my $oauth2 = PAGI::FastAPI::Security::OAuth2::PasswordBearer->new(
    token_url => '/token',
    scopes    => { 'items:read' => 'Read items', 'items:write' => 'Write items' },
);

my $app = PAGI::FastAPI->new(title => 'OAuth2-password-flow API');

# The token endpoint OAuth2::PasswordBearer's metadata points at.
# Not part of PAGI::FastAPI::Security, you write this yourself.
$app->post('/token',
    body    => { username => Str, password => Str },
    handler => async sub ($c) {
        my $record = USERS->{ $c->body('username') };
        unless ($record && $record->{password} eq $c->body('password')) {
            $c->status(401);
            return { detail => 'Incorrect username or password' };
        }
        my $token = encode_jwt(
            payload => { sub => $c->body('username'), role => $record->{role} },
            key     => JWT_SECRET,
            alg     => 'HS256',
        );
        return { access_token => $token, token_type => 'bearer' };
    }
);

$app->get('/me',
    dependencies => [
        $oauth2->depends(key => 'token'),
        Depends(async sub ($c) {
            my $claims = eval { decode_jwt(token => $c->stash->{token}, key => JWT_SECRET) };
            unless ($claims) {
                $c->status(401);
                $c->set_header('WWW-Authenticate' => 'Bearer');
                return { detail => 'Invalid or expired token' };
            }
            return $claims;
        }, key => 'claims'),
    ],
    handler => async sub ($c) {
        return {
            user => $c->stash->{claims}{sub},
            role => $c->stash->{claims}{role},
        };
    }
);

$app->to_app;
