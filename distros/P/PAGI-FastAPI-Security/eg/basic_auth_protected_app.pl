#!/usr/bin/env perl

# Run with: pagi-server eg/basic_auth_protected_app.pl
#
# Demonstrates chaining PAGI::FastAPI::Security::HTTPBasic (which only
# extracts the username/password from the Authorization header) with a
# second Depends() that actually checks them against a user store.
#
# Try it:
#   curl -u alice:wonderland http://127.0.0.1:5000/me
#   curl -u alice:wrongpass  http://127.0.0.1:5000/me

use v5.36;
use Future::AsyncAwait;
use PAGI::FastAPI;
use PAGI::FastAPI::Depends qw(Depends);
use PAGI::FastAPI::Security::HTTPBasic;

# In a real app, store a salted hash (e.g. via Crypt::Bcrypt) and compare
# with a constant-time check, not plaintext passwords like this demo.
use constant USERS => {
    alice => { password => 'wonderland', role => 'admin' },
    bob   => { password => 'builder',    role => 'viewer' },
};

my $basic = PAGI::FastAPI::Security::HTTPBasic->new(realm => 'demo-api');
my $app   = PAGI::FastAPI->new(title => 'Basic-auth-protected API');

$app->get('/me',
    dependencies => [
        $basic->depends(key => 'creds'),
        Depends(async sub ($c) {
            my ($user, $pass) = @{ $c->stash->{creds} }{qw(username password)};
            my $record = USERS->{$user};
            unless ($record && $record->{password} eq $pass) {
                $c->status(401);
                $c->set_header('WWW-Authenticate' => 'Basic realm="demo-api"');
                return { detail => 'Invalid username or password' };
            }
            return { user => $user, role => $record->{role} };
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
