#!/usr/bin/perl

use Test::More tests => 15;
use Carp;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;

use Net::DAV::Server ();
use Net::DAV::LockManager::Simple ();

my $dav = Net::DAV::Server->new();

isa_ok( $dav, 'Net::DAV::Server' );
can_ok( $dav, qw/options put get head post delete mkcol propfind copy lock unlock move/ );
ok( !defined eval { $dav->can( 'trace' ); }, 'trace method not supported.' );

# Implementation detail
ok( !exists $dav->{'lock_manager'}, 'Default new: no lock manager created.' );
ok( !exists $dav->{'_dsn'},         'Default new: no dsn created.' );
ok( !$dav->filesys,                 'Default new: no filesys.' );

{
    my $dav = Net::DAV::Server->new( -dbobj => Net::DAV::LockManager::Simple->new() );
    ok( exists $dav->{'lock_manager'},  '-dbobj: lock manager created.' );
    ok( !exists $dav->{'_dsn'},         '-dbobj: no dsn created.' );
    ok( !$dav->filesys,                 '-dbobj: no filesys.' );
}

{
    my $dav = Net::DAV::Server->new( -dbfile => 'file.db' );
    ok( !exists $dav->{'lock_manager'}, '-dbfile: no lock manager created.' );
    is( $dav->{'_dsn'}, 'dbi:SQLite:dbname=file.db',  '-dbfile: dsn created.' );
    ok( !$dav->filesys,                 '-dbfile: no filesys.' );
}

{
    my $dav = Net::DAV::Server->new( -dsn => 'dbi:SQLite:dbname=junk.db' );
    ok( !exists $dav->{'lock_manager'}, '-dbfile: no lock manager created.' );
    is( $dav->{'_dsn'}, 'dbi:SQLite:dbname=junk.db',  '-dbfile: dsn created.' );
    ok( !$dav->filesys,                 '-dbfile: no filesys.' );
}
