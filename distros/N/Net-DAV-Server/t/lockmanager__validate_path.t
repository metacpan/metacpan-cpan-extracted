#!/usr/bin/perl

use Test::More tests => 13;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();

# Testing internal method, not for external use.
# Method used in several places for validating input parameters

path_is_invalid( 'abcdef/ghi', 'Relative path' );
path_is_invalid( '/ab/../de/', 'Path containing .. segment' );
path_is_invalid( '/ab/de/..',  'Path containing trailing .. segment' );
path_is_invalid( '/ab/./de/',  'Path containing . segment' );
path_is_invalid( '/ab/de/.',   'Path containing trailing . segment' );

path_is_valid( '/',         '/',        'Root path' );
path_is_valid( '/foo',      '/foo',     'Simple path' );
path_is_valid( '/foo/bar/', '/foo/bar', 'Path with trailing /' );

path_is_valid( 'http://xmpl.org/foo/bar/',            '/foo/bar', 'Full URI' );
path_is_valid( 'http://xmpl.org:2077/foo/bar/',       '/foo/bar', 'Full URI with port' );
path_is_valid( 'http://fred@xmpl.org/foo/bar/',       '/foo/bar', 'URI with user' );
path_is_valid( 'http://fred@xmpl.org:2077/foo/bar/',  '/foo/bar', 'URI with user and port' );
path_is_valid( 'https://fred@xmpl.org:2077/foo/bar/', '/foo/bar', 'URI with everything and https' );


sub path_is_valid {
    my ($path, $clean, $label) = @_;
    my $req = { 'path' => $path };
    eval {
        Net::DAV::LockManager::_validate_lock_request( $req ); 1;
    } or do {
        fail( "$label: path invalid unexpectedly" );
    };
    is( $req->{'path'}, $clean, "$label: path cleaned" );
}

sub path_is_invalid {
    my ($path, $label) = @_;
    eval {
        Net::DAV::LockManager::_validate_lock_request({ 'path' => $path }); 1;
    } or do {
        like( $@, qr/Not a clean path/, $label );
        return;
    };
    fail( "$label: path valid unexpectedly" );
}
