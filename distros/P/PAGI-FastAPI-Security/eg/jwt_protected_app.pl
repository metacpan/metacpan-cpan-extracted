#!/usr/bin/env perl

# Run with: pagi-server eg/jwt_protected_app.pl
#
# Demonstrates chaining PAGI::FastAPI::Security::HTTPBearer (which only
# extracts the token) with a second Depends() that actually verifies it
# as a signed JWT via Crypt::JWT.
#
# Try it:
#   TOKEN=$(perl -MCrypt::JWT=encode_jwt -E 'say encode_jwt(payload=>{sub=>"alice",role=>"admin"}, key=>"demo-shared-secret", alg=>"HS256")')
#   curl -H "Authorization: Bearer $TOKEN"  http://127.0.0.1:5000/me
#   curl -H "Authorization: Bearer garbage" http://127.0.0.1:5000/me

use v5.36;
use Future::AsyncAwait;
use Crypt::JWT qw(decode_jwt);
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::HTTPBearer;

# In a real app, load this from config/environment, not a literal.
use constant JWT_SECRET => 'demo-shared-secret';

my $bearer = PAGI::FastAPI::Security::HTTPBearer->new;

my $app = PAGI::FastAPI->new(title => 'JWT-protected API');

$app->get('/me',
    dependencies => [
        $bearer->depends(key => 'token'),
        Depends(async sub ($c) {
            my $claims = eval {
                decode_jwt(token => $c->stash->{token}, key => JWT_SECRET);
            };
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
