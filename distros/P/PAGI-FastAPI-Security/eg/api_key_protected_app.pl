#!/usr/bin/env perl

# Run with: pagi-server eg/api_key_protected_app.pl
#
# Demonstrates chaining PAGI::FastAPI::Security::APIKey (which only
# extracts the key from the X-API-Key header) with a second Depends()
# that actually looks it up against a store of known keys.
#
# Try it:
#   curl -H "X-API-Key: demo-key-alice" http://127.0.0.1:5000/me
#   curl -H "X-API-Key: no-such-key"    http://127.0.0.1:5000/me

use v5.36;
use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::APIKey;

# In a real app, load this from a database, not a literal.
use constant API_KEYS => {
    'demo-key-alice' => { user => 'alice', role => 'admin' },
    'demo-key-bob'   => { user => 'bob',   role => 'viewer' },
};

my $api_key = PAGI::FastAPI::Security::APIKey->new(
    in   => 'header',
    name => 'X-API-Key',
);

my $app = PAGI::FastAPI->new(title => 'API-key-protected API');

$app->get('/me',
    dependencies => [
        $api_key->depends(key => 'api_key'),
        Depends(async sub ($c) {
            my $identity = API_KEYS->{ $c->stash->{api_key} };
            unless ($identity) {
                $c->status(403);
                return { detail => 'Invalid API key' };
            }
            return $identity;
        }, key => 'identity'),
    ],
    handler => async sub ($c) {
        return {
            user => $c->stash->{identity}{user},
            role => $c->stash->{identity}{role},
        };
    }
);

$app->to_app;
