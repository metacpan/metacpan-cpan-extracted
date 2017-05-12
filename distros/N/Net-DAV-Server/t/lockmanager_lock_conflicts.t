#!/usr/bin/perl

use Test::More tests => 12;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

my $token_re = qr/^opaquelocktoken:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/;

{
    my $label = 'Beneath lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $token = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' })->token;
    like( $token, $token_re, "$label: Initial lock" );
    ok( !defined $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'bianca', 'owner' => 'Bianca' }), "$label: non-owner cannot lock without token" );
    ok( !defined $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred' }), "$label: owner cannot lock without token" );

    ok( !defined $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'bianca', 'owner' => 'Bianca', 'token' => $token }), "$label: non-owner cannot lock with token" );
    my $token2 = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred', 'token' => $token })->token;
    like( $token2, $token_re, "$label: owner can lock with token" );
    isnt( $token2, $token, "$label: tokens are not the same." );
}

{
    my $label = 'Lock ancestor';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $token = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred' })->token;
    like( $token, $token_re, "$label: Initial lock" );
    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca' }), "$label: non-owner cannot lock without token" );
    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: owner cannot lock without token" );

    ok( !defined $mgr->lock({ 'path' => '/foo', 'user' => 'bianca', 'owner' => 'Bianca', 'token' => $token }), "$label: non-owner cannot lock with token" );
    my $token2 = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'token' => $token })->token;
    like( $token2, $token_re, "$label: owner can lock with token" );
    isnt( $token2, $token, "$label: tokens are not the same." );
}


