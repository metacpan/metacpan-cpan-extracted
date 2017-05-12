#!/usr/bin/perl

use Test::More tests => 11;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();
use Net::DAV::UUID ();

# Exploits an implementation detail
my $mock_token = 'opaquelocktoken:' . Net::DAV::UUID::generate( '/tmp/file', 'fred' );

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    ok( !$mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $mock_token }),
        'Can not unlock a non-existent lock' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/tmp/file', 'user' => 'bianca', 'owner' => 'Bianca' });

    ok( !$mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $lck->token }),
        'Can not unlock non-owned lock' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/tmp', 'user' => 'fred', 'owner' => 'Fred' });

    ok( !$mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $lck->token }),
        'Can not unlock ancestor lock' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/tmp/file1', 'user' => 'fred', 'owner' => 'Fred' });

    ok( !$mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $lck->token }),
        'Can not unlock sibling lock' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/tmp/file', 'user' => 'fred', 'owner' => 'Fred' });

    ok( !$mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $mock_token }),
        'Can not unlock with wrong token' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    my $lck = $mgr->lock({ 'path' => '/tmp/file', 'user' => 'fred', 'owner' => 'Fred' });
    ok( !$mgr->can_modify({ 'path' => '/tmp/file', 'user' => 'bianca' }), 'Can not modify locked resource.' );

    ok( $mgr->unlock({ 'path' => '/tmp/file', 'user' => 'fred', 'token' => $lck->token }),
        'Successfully unlocked resource' );
    ok( $mgr->can_modify({ 'path' => '/tmp/file', 'user' => 'bianca' }), 'Can modify unlocked resource.' );
}

{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new( $db );
    my $lck1 = $mgr->lock({ 'path' => '/tmp/file', 'user' => 'fred', 'owner' => 'Fred' });
    my $lck2 = $mgr->lock({ 'path' => '/tmp/subdir', 'user' => 'fred', 'owner' => 'Fred' });
    my $lck3 = $mgr->lock({ 'path' => '/tmp/junk', 'user' => 'fred', 'owner' => 'Fred' });

    ok( $mgr->unlock({ 'path' => '/tmp/subdir', 'user' => 'fred', 'token' => $lck2->token }), 'remove middle lock' );
    ok( !$mgr->can_modify({ 'path' => '/tmp/file', 'user' => 'bianca' }), 'Can not modify first locked resource.' );
    ok( !$mgr->can_modify({ 'path' => '/tmp/junk', 'user' => 'bianca' }), 'Can not modify last locked resource.' );
}

