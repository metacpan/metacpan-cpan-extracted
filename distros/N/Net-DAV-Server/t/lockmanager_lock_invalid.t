#!/usr/bin/perl

use Test::More tests => 26;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

{
    # Validate parameters
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    did_die( sub { $mgr->lock() },                          qr/hash reference/,           'No args' );
    did_die( sub { $mgr->lock( 'fred' ) },                  qr/hash reference/,           'String arg' );
    did_die( sub { $mgr->lock({}) },                        qr/Missing required/,         'No params' );
    did_die( sub { $mgr->lock({ 'user' => 'gwj', 'owner' => 'G. Wade' }) },      qr/Missing required 'path'/,  'Missing path' );
    did_die( sub { $mgr->lock({ 'path' => '/tmp/file', 'owner' => 'G. Wade' }) }, qr/Missing required 'user'/, 'Missing user' );
    did_die( sub { $mgr->lock({ 'path' => '/tmp/file', 'user' => 'gwj' }) }, qr/Missing required 'owner'/, 'Missing owner' );
}

{
    # Path checking
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    foreach my $path ( '', qw{/.. /fred/.. /../fred /fred/../bianca /fred/./bianca fred/ fred} ) {
        did_die( sub { $mgr->lock({ 'path' => $path, 'user'=>'gwj', 'owner' => 'G. Wade' }) }, qr/Not a clean path/, "$path: Not an allowed path" );
    }
}

{
    # Owner checking
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);
    foreach my $user ( '', qw{aa()bb /fred/ ab+cd $fred} ) {
        did_die( sub { $mgr->lock({ 'path' => '/fred/foo', 'user'=>$user, 'owner' => 'G. Wade' }) }, qr/Not a valid user/, "$user Not an allowed user" );
    }
}

# Validate optional parameters
{
    my $db = Net::DAV::LockManager::Simple->new();
    my $mgr = Net::DAV::LockManager->new($db);

    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'scope' => 'xyzzy' }) }, qr/not a supported .* scope/, 'Unknown scope value.' );
    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'scope' => 'shared' }) }, qr/not a supported .* scope/, '"shared" not currently supported' );

    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => '1' }) }, qr/not a supported .* depth/, 'No numerics other than 0 for depth.' );
    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'depth' => 'xyzzy' }) }, qr/not a supported .* depth/, 'No non-numerics other than inifinity' );

    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'timeout' => -1 }) }, qr/not a supported .* timeout/, 'Negative timeout not allowed' );
    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'timeout' => 3.14 }) }, qr/not a supported .* timeout/, 'Only integer timeout allowed' );
    did_die( sub { $mgr->lock({ 'path' => '/foo', 'user' => 'fred', 'owner' => 'Fred', 'timeout' => 'xyzzy' }) }, qr/not a supported .* timeout/, 'Non-numeric timeout not allowed' );
}

sub did_die {
    my ($code, $regex, $label) = @_;
    if ( eval { $code->(); } ) {
        fail( "$label: no exception" );
        return;
    }
    like( $@, $regex, $label );
}
