#!/usr/bin/perl

use Test::More tests => 32;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

use Net::DAV::UUID ();

# No locks
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    ok( $mgr->can_modify({ 'path' => '/', 'user' => 'fred' }), '/ with no lock' );
    ok( $mgr->can_modify({ 'path' => '/foo', 'user' => 'fred' }), 'one level with no lock' );
    ok( $mgr->can_modify({ 'path' => '/foo/a/b/c/d/e', 'user' => 'fred' }), 'multi-level with no lock' );
}

# Infinity lock on ancestor
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred' });
    my $t = $lck->token;

    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'bianca' }), 'different user, resource with lock, no token' );
    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'bianca' }), 'different user, child of resource with lock, no token' );
    ok( !$mgr->can_modify({ 'path' => '/a/b/c/d/e/f', 'user' => 'bianca' }), 'different user, descendant of resource with lock, no token' );

    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'bianca', 'token' => $t }), 'different user, resource with lock' );
    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'bianca', 'token' => $t }), 'different user, child of resource with lock' );
    ok( !$mgr->can_modify({ 'path' => '/a/b/c/d/e/f', 'user' => 'bianca', 'token' => $t }), 'different user, descendant of resource with lock' );
}

# Infinity lock on ancestor
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred' });

    # Warning: Reliance on an implementation detail.
    my $mock_token = 'opaquelocktoken:' . Net::DAV::UUID::generate( '/foo', 'fred' );

    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'fred', 'token' => $mock_token }), 'wrong token, resource with lock' );
    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'fred', 'token' => $mock_token }), 'wrong token, child of resource with lock' );
    ok( !$mgr->can_modify({ 'path' => '/a/b/c/d/e/f', 'user' => 'fred', 'token' => $mock_token }), 'wrong token, descendant of resource with lock' );
}

# Infinity lock on non-ancestor
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', });

    ok( $mgr->can_modify({ 'path' => '/bar', 'user' => 'bianca' }), 'different user, sibling resource, without token' );
    ok( $mgr->can_modify({ 'path' => '/bar/foo', 'user' => 'bianca' }), 'different user, child of resource with lock' );
    ok( $mgr->can_modify({ 'path' => '/bar/c/d/e/f', 'user' => 'bianca' }), 'different user, descendant of sibling resource with lock' );
}

# Non-Infinity lock on ancestor
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 0 });
    my $t = $lck->token;

    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'bianca' }), 'different user, resource with lock, without token' );
    ok( $mgr->can_modify({ 'path' => '/foo', 'user' => 'bianca' }), 'different user, child of resource with lock, without token' );
    ok( $mgr->can_modify({ 'path' => '/a/b/c/d/e/f', 'user' => 'bianca' }), 'different user, descendant of resource with lock, without token' );

    ok( !$mgr->can_modify({ 'path' => '/', 'user' => 'bianca', 'token' => $t }), 'different user, resource with lock' );
    ok( $mgr->can_modify({ 'path' => '/foo', 'user' => 'bianca', 'token' => $t }), 'different user, child of resource with lock' );
    ok( $mgr->can_modify({ 'path' => '/a/b/c/d/e/f', 'user' => 'bianca', 'token' => $t }), 'different user, descendant of resource with lock' );
}

# Non-Infinity lock on non-ancestor
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 0 });
    my $t = $lck->token;

    ok( $mgr->can_modify({ 'path' => '/bar', 'user' => 'bianca' }), 'different user, sibling resource' );
    ok( $mgr->can_modify({ 'path' => '/bar/c/d/e/f', 'user' => 'bianca' }), 'different user, descendant of sibling resource with lock' );
}

# Infinity lock on non-ancestor, multiple-tokens
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' });
    # Warning: Reliance on an implementation detail.
    my $tokens = [
        'opaquelocktoken:' . Net::DAV::UUID::generate( '/baz', 'fred' ), # mock token 1
        $lck->token,                                                     # Correct token
        'opaquelocktoken:' . Net::DAV::UUID::generate( '/bar', 'fred' ), # mock token 2
    ];

    ok( $mgr->can_modify({ 'path' => '/foo', 'user' => 'fred', 'token' => $tokens }), 'user, resource, multi-token' );
    ok( $mgr->can_modify({ 'path' => '/foo/bar', 'user' => 'fred', 'token' => $tokens }), 'user, child, multi-token' );
    ok( $mgr->can_modify({ 'path' => '/foo/bar/c/d/e/f', 'user' => 'fred', 'token' => $tokens }), 'user, descendant, multi-token' );

    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'bianca', 'token' => $tokens }), 'different user, resource, multi-token' );
    ok( !$mgr->can_modify({ 'path' => '/foo/bar', 'user' => 'bianca', 'token' => $tokens }), 'different user, child, multi-token' );
    ok( !$mgr->can_modify({ 'path' => '/foo/bar/c/d/e/f', 'user' => 'bianca', 'token' => $tokens }), 'different user, descendant, multi-token' );

    $tokens = [ @{$tokens}[0,2] ];  # Remove correct token
    ok( !$mgr->can_modify({ 'path' => '/foo', 'user' => 'fred', 'token' => $tokens }), 'user, resource, multi-token, all bad' );
    ok( !$mgr->can_modify({ 'path' => '/foo/bar', 'user' => 'fred', 'token' => $tokens }), 'user, child, multi-token, all bad' );
    ok( !$mgr->can_modify({ 'path' => '/foo/bar/c/d/e/f', 'user' => 'fred', 'token' => $tokens }), 'user, descendant, multi-token, all bad' );
}

