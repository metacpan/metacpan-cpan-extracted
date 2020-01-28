#! /usr/bin/env perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $queue_id = `$^X -Ilib bin/tapper queue-new --name="Affe" --priority=4711`;
chomp $queue_id;

my $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
ok($queue->id, 'inserted queue / id');
is($queue->name, "Affe", 'inserted queue / name');
is($queue->priority, 4711, 'inserted queue / priority');

`$^X -Ilib bin/tapper host-new  --name="host3" --queue=Xen --queue=KVM`;
is($?, 0, 'New host / return value');

my $retval = `$^X -Ilib bin/tapper queue-list --maxprio=300 --minprio=200 -v `;
like ($retval, qr/\s+Id: 2\s+Name: KVM\s+Priority: 200\s+Runcount: 200\s+Active: 0\s+Bound hosts: host3\s+Id: 1\s+Name: Xen\s+Priority: 300\s+Runcount: 300\s+Active: 0\s+Bound hosts: host3/, 'List queues');

$retval = `$^X -Ilib bin/tapper queue-list --maxprio=10 -v `;
like($retval, qr/\s+Id: 3\s+Name: Kernel\s+Priority: 10\s+Runcount: 10\s+Active: 0\s+Queued testruns \(ids\): 3001, 3002/, 'Queued testruns in listqueue');

$retval = `$^X -Ilib bin/tapper queue-list --name=Xen --name=Kernel -v`;
like($retval, qr/\s+Id: 3\s+Name: Kernel\s+Priority: 10\s+Runcount: 10\s+Active: 0\s+Queued testruns \(ids\): 3001, 3002\s+Id: 1\s+Name: Xen\s+Priority: 300\s+Runcount: 300\s+Active: 0\s+Bound hosts: host3/, 'List queues by name');

$retval = `$^X -Ilib bin/tapper queue-update --name=Xen -p500 -v`;
like($retval, qr/\s+Id: 1\s+Name: Xen\s+Priority: 500\s+Runcount: 300\s+Active: 0\s+Bound hosts: host3/, 'Update queue priority');

$retval = `$^X -Ilib bin/tapper queue-update --name=Xen --active=1 -v`;
like($retval, qr/\s+Id: 1\s+Name: Xen\s+Priority: 500\s+Runcount: 500\s+Active: 1\s+Bound hosts: host3/, 'Update queue active flag');

$retval = `$^X -Ilib bin/tapper queue-update --name=Xen --active=0 -v`;
like($retval, qr/\s+Id: 1\s+Name: Xen\s+Priority: 500\s+Runcount: 500\s+Active: 0\s+Bound hosts: host3/, 'Update queue active flag');

$retval = `$^X -Ilib bin/tapper queue-delete --name=Xen --force -v`;
like($retval, qr/info: Deleted queue Xen/, 'Delete queue');

done_testing();
