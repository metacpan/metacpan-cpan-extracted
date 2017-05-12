#!/usr/bin/perl

use Test::More tests => 10;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( !defined $mgr->find_lock({ 'path' => '/foo/bar/baz' }), 'No lock returned if no lock' );
}

{
    my $label = 'Direct lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource" );
    is_deeply( $mgr->find_lock({ 'path' => '/foo' }), $lock, "$label: Direct lock returned" );
}

{
    my $label = 'Indirect lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource" );
    is_deeply( $mgr->find_lock({ 'path' => '/foo/bar/baz' }), $lock, "$label: Indirect lock returned" );
}

{
    my $label = 'Two indirect locks';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock_i = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource 1" );
    ok( my $lock = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred', 'token' => $lock_i->token }), "$label: Locked resource 2" );
    is_deeply( $mgr->find_lock({ 'path' => '/foo/bar/baz' }), $lock, "$label: Both locks returned" );
}

{
    my $label = 'Depth-0 ancestor lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock_i = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 0 }), "$label: Locked resource 1" );
    ok( !defined $mgr->find_lock({ 'path' => '/foo/bar/baz' }), "$label: Depth 0 locks not returned." );
}
