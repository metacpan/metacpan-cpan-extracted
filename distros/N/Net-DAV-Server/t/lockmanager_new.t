#!/usr/bin/perl

use Test::More tests => 3;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager ();
use Net::DAV::LockManager::Simple ();

my $db = Net::DAV::LockManager::Simple->new();

isa_ok( $db, 'Net::DAV::LockManager::Simple' );

my $mgr = Net::DAV::LockManager->new($db);
isa_ok( $mgr, 'Net::DAV::LockManager' );
can_ok( $mgr, qw/can_modify lock unlock refresh_lock/ );
