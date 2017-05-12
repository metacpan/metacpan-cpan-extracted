#!/usr/bin/perl

use Test::More tests => 25;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

my $token_re = qr/^opaquelocktoken:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/;

# Verify simple locks.
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    like( $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred' })->token, $token_re, 'lock root' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    like( $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' })->token, $token_re, 'lock one level' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    like( $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 'infinity', 'scope' => 'exclusive', 'timeout' => 900 })->token,
        $token_re,
        'lock one level, explicit values.'
    );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    like( $mgr->lock({ 'path' => '/foo/a/b/c/d/e/f', 'user' => 'fred', 'owner' => 'Fred' })->token, $token_re, 'lock multi-level' );
}

# Verify attempted re-lock
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' });
    my $token = $lck->token;
    like( $token, $token_re, 'Initial lock is okay.' );

    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), 'Cannot relock same owner' );
    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'token' => $token }), 'Cannot relock same owner, token' );
    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca' }), 'Cannot relock different owner' );
}

# Verify nesting locks.
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred' });
    my $token = $lck->token;
    like( $token, $token_re, 'lock root, again' );

    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), 'Cannot lock below an infinity lock' );

    my $flck = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'token' => $token });
    like( $flck->token, $token_re, 'Locking with token is allowed' );
    isnt( $token, $flck->token, 'Tokens do not match' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred' });
    my $token = $lck->token;
    like( $token, $token_re, 'lock root, again' );

    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca' }), 'Cannot lock with wrong owner and no token' );
    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca', 'token' => $token }), 'Cannot lock with wrong owner' );
}

# Verify non-overlapping locks
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/bar', 'user' => 'fred', 'owner' => 'Fred' });
    my $token = $lck->token;
    like( $token, $token_re, 'fred locks bar' );

    my $olck = $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca' });
    like( $olck->token, $token_re, 'bianca locks foo' );
    isnt( $token, $olck->token, 'Non-overlapping tokens do not match' );
    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), 'foo is locked for fred.' );
    ok( !$mgr->can_modify({ 'path' => '/bar', 'user' => 'bianca', 'owner' => 'Bianca' }), 'bar is locked for bianca.' );
}

# Verify nested non-infinity locks.
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 0 });
    my $token = $lck->token;
    like( $token, $token_re, 'non-infinity: lock root, again' );

    my $flck = $mgr->lock({ 'path' => '/bar', 'user' => 'fred', 'owner' => 'Fred' });
    like( $flck->token, $token_re, 'non-infinity: fred locks bar' );
    isnt( $token, $flck->token, 'non-infinity: Tokens do not match' );
    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'bianca', 'owner' => 'Bianca' }), 'root is locked for bianca.' );
    ok( !$mgr->can_modify({ 'path' => '/bar', 'user' => 'bianca', 'owner' => 'Bianca' }), 'bar is locked for bianca.' );
}

