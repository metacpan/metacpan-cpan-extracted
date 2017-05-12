#!/usr/bin/perl

use Test::More tests => 15;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    my @locks = $mgr->list_all_locks({ 'path' => '/foo/bar/baz' });
    is_deeply( \@locks, [], 'No locks returned if no locks' );
}

{
    my $label = 'Direct lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource" );
    my @locks = $mgr->list_all_locks({ 'path' => '/foo' });
    is_deeply( \@locks, [ $lock ], "$label: Direct lock returned" );
}

{
    my $label = 'Indirect lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource" );
    my @locks = $mgr->list_all_locks({ 'path' => '/foo/bar/baz' });
    is_deeply( \@locks, [ $lock ], "$label: Indirect lock returned" );
}

{
    my $label = 'Two indirect locks';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock_i = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource 1" );
    ok( my $lock = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred', 'token' => $lock_i->token }), "$label: Locked resource 2" );
    my @locks = $mgr->list_all_locks({ 'path' => '/foo/bar/baz' });
    is_deeply( \@locks, [ $lock, $lock_i ], "$label: Both locks returned" );
}

{
    my $label = 'Depth-0 ancestor lock';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock_i = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 0 }), "$label: Locked resource 1" );
    ok( my $lock = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource" );
    my @locks = $mgr->list_all_locks({ 'path' => '/foo/bar/baz' });
    is_deeply( \@locks, [ $lock ], "$label: Depth 0 locks not returned." );
}

{
    my $label = 'Multiple indirect locks';
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( my $lock_i = $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred' }), "$label: Locked resource 1" );
    ok( my $lock_i2 = $mgr->lock({ 'path' => '/foo/bar', 'user' => 'fred', 'owner' => 'Fred', 'token' => $lock_i->token }), "$label: Locked resource 2" );
    ok( my $lock = $mgr->lock({ 'path' => '/foo/bar/baz', 'user' => 'fred', 'owner' => 'Fred', 'token' => [ $lock_i->token, $lock_i2->token ] }), "$label: Locked resource 3" );
    my @locks = $mgr->list_all_locks({ 'path' => '/foo/bar/baz' });
    is_deeply( \@locks, [ $lock, $lock_i2, $lock_i ], "$label: Depth 0 locks not returned." );
}
