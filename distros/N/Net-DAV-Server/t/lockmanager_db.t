#! /usr/bin/perl

use Test::More tests => 5;
use Carp;

use strict;
use warnings;

use File::Temp qw(tmpnam);
use Net::DAV::LockManager::DB ();

#
# Check that the database constructor acts properly when passed a data source
# name.
#
{
    my $tmp = File::Temp::tmpnam('/tmp', 'foo-bar-baz.db');
    my $dsn = 'dbi:SQLite:dbname=' . $tmp;
    my $db = Net::DAV::LockManager::DB->new($dsn);

    ok(defined $db, "Able to gain database context when providing a data source name");

    # XXX -  This depends upon an implementation detail!
    ok(!defined $db->{'tmp'}, "Database driver does not create a temporary database when passed a data source name");

    $db->close();
    $db = undef;

    $db = Net::DAV::LockManager::DB->new($dsn);

    ok(defined $db, "Able to reopen named database after prior closure");

    # XXX - This depends upon another implementation detail!
    eval {
        $db->_initialize();
    };

    ok($@ eq '', "Database driver does not attempt to reapply schema on an existing database");
}

#
# Check that the database constructor acts properly when no data source
# name is passed.
#
{
    my $db = Net::DAV::LockManager::DB->new();

    ok(defined $db, "Able to gain database context with a temporary database");
}
