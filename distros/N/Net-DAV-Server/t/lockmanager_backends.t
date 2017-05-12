#!/usr/bin/perl

use Test::More tests => 32;
use Carp;

use strict;
use warnings;

use Net::DAV::LockManager::Simple ();
use Net::DAV::LockManager::DB ();

sub reduce {
    my $test = shift;

    foreach my $item (@_) {
        return $item if $test->($item);
    }
}

my @db_drivers = (
    sub { return ('Net::DAV::LockManager::DB'       => Net::DAV::LockManager::DB->new()) },
    sub { return ('Net::DAV::LockManager::Simple'   => Net::DAV::LockManager::Simple->new()) }
);

my $test_data = {
    '/'         => [qw(/foo /foo/bar /foo/bar/baz /foo/meow)],
    '/foo'      => [qw(/foo/bar /foo/bar/baz /foo/meow)],
    '/foo/bar'  => [qw(/foo/bar/baz)]
};

#
# Verify that simple lock database CRUD operations function properly.
#
foreach my $db_driver (@db_drivers) {
    my ($db_type, $db) = $db_driver->();

    my $path = "/foo";

    my $lock = $db->add(Net::DAV::Lock->new({
        'expiry'    => time() + 720,
        'creator'   => 'alice',
        'owner'     => 'Alice',
        'depth'     => 'infinity',
        'scope'     => 'exclusive',
        'path'      => $path
    }));

    ok(ref $lock eq "Net::DAV::Lock", "$db_type\::add() able to add lock entries to the database");
    ok($db->get($path)->path eq $path, "$db_type\::get() able to locate lock entries by path");

    my $new_expiry = time() + 800;
    $lock->renew($new_expiry);
    ok($db->update($lock)->expiry == $new_expiry, "$db_type\::update() is able to update/renew locks");
    ok($db->get($path)->uuid eq $lock->uuid, "$db_type\::get() does not mangle UUIDs when reanimating Net::DAV::Lock");

    $db->remove($lock);
    ok(!defined $db->get($path), "$db_type\::remove() actually removes lock entry");

    $db->close();
}

#
# Verify that recursive lock lookup works.
#
foreach my $db_driver (@db_drivers) {
    my ($db_type, $db) = $db_driver->();

    foreach my $path (qw(/ /foo /foo/bar /foo/bar/baz /foo/meow)) {
        $db->add(Net::DAV::Lock->new({
            'expiry'    => time() + 720,
            'creator'   => 'alice',
            'owner'     => 'Alice',
            'depth'     => 'infinity',
            'scope'     => 'exclusive',
            'path'      => $path
        }));
    }

    while (my ($ancestor, $descendants) = each(%$test_data)) {
        my @locks = $db->list_descendants($ancestor);

        #
        # list_descendants() should return the exact number of items specified
        # in this particular test.
        #
        my $message = sprintf("%s::list_descendants() returned %d items for %s",
          $db_type, scalar @$descendants, $ancestor);

        ok(scalar @locks == scalar @$descendants, $message);

        #
        # Check to see if the objects returned are actually the right ones.
        #
        foreach my $path (@$descendants) {
            ok(ref reduce(sub {
                return shift->path eq $path
            }, @locks) eq "Net::DAV::Lock", "$db_type\::list_descendants() contains lock for $path");
        }
    }

    $db->close();
}
