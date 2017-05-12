#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture(
    schema  => testrundb_schema,
    fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml',
);
# -----------------------------------------------------------------------------------------------------------------

my $retval;
my $i_host_id_host1 = `$^X -Ilib bin/tapper host-new  --name="host1"`;
chomp $i_host_id_host1;

my $host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host1);
ok($host_result->id, 'inserted host without option / id');
ok($host_result->free, 'inserted host  without option / free');
is($host_result->name, 'host1', 'inserted host without option / name');

# --------------------------------------------------

my $i_host_id_host2 = `$^X -Ilib bin/tapper host-new  --name="host2" --active --queue=KVM`;
chomp $i_host_id_host2;

$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host2);
ok($host_result->id, 'inserted host with active and existing queue / id');
is($host_result->name, 'host2', 'inserted host with active and existing queue / name');
ok($host_result->active, 'inserted host with active and existing queue / active');
ok($host_result->free, 'inserted host with active and existing queue / free');

# --------------------------------------------------

my $i_host_id_host3 = `$^X -Ilib bin/tapper host-new  --name="host3" --queue=Xen --queue=KVM`;
chomp $i_host_id_host3;

$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host3);
ok($host_result->id, 'inserted host with multiple existing queues / id');
is($host_result->name, 'host3', 'inserted host with multiple existing queues / name');
is($host_result->active, undef, 'inserted host with multiple existing queues / active');
ok($host_result->free, 'inserted host with multiple existing queues / free');
if ($host_result->queuehosts->count) {
        my @queue_names = map {$_->queue->name} $host_result->queuehosts->all;
        is_deeply(['Xen', 'KVM'] , \@queue_names, 'inserted host with multiple existing queues / queues');
}
else {
        fail("Queues assigned to host");
}

# --------------------------------------------------
my $i_host_id_4 = qx($^X -Ilib bin/tapper host-new  --name="host4" --queue=noexist 2>&1);
like($i_host_id_4, qr(No such queue: noexist), 'Error handling for nonexistent queue');


# --------------------------------------------------
# diag qx($^X -Ilib bin/tapper host-list -v);
my $hosts = qx($^X -Ilib bin/tapper host-list --queue=KVM 2>&1);
like($hosts, qr(\s+\d+ \| host2\n\s+\d+ \| host3\n), 'Show hosts / queue');

$hosts = qx($^X -Ilib bin/tapper host-list --queue=KVM 2>&1);
like($hosts, qr(11 *| *host2\n *12 *| *host3\n), 'Show hosts / queue');

# --------------------------------------------------
qx($^X -Ilib bin/tapper host-update --delboundqueue --active=1 --id=$i_host_id_host1 2>&1);
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host1);
ok($host_result->active, 'Update host / active');
is($host_result->queuehosts->count, 0, 'Update host / delete all queues');

# --------------------------------------------------
$retval = qx($^X -Ilib bin/tapper host-update --active=1 --id=$i_host_id_host2 2>&1);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host2);
ok($host_result->active, 'Update host - active');

$retval = qx($^X -Ilib bin/tapper host-update --active=0 --id=$i_host_id_host2 2>&1);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host2);
ok(!$host_result->active, 'Update host - deactivate');

# --------------------------------------------------
$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host1);
ok($host_result, 'Delete host / host exists before delete');
is($host_result->is_deleted, 0, 'Delete host / Deleted flag unset before delete');
is($host_result->active, 1, 'Delete host / Host active before delete');
is($host_result->name, 'host1', 'Working on the expected host');

qx($^X -Ilib bin/tapper host-delete --name=host1 --force 2>&1);
$host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host1);
isa_ok($host_result, 'Tapper::Schema::TestrunDB::Result::Host', 'Delete host / host still in DB');
is($host_result->is_deleted, 1, 'Delete host / Deleted flag set');
is($host_result->active, 0, 'Delete host / Host no longer active');

qx($^X -Ilib bin/tapper host-deny --host=host2 --queue=AdHoc);
my $queue_result = model('TestrunDB')->resultset('Queue')->find({name => 'AdHoc'});
is($queue_result->deniedhosts->first->host->name, 'host2', 'host2 denied from queue AdHoc');
qx($^X -Ilib bin/tapper host-deny --host=host2 --queue=AdHoc --off);
is($queue_result->deniedhosts->count, 0, 'host2 denial from queue AdHoc removed');

qx($^X -Ilib bin/tapper host-bind --host=host3 --queue=AdHoc);
$queue_result = model('TestrunDB')->resultset('Queue')->find({name => 'AdHoc'});
is($queue_result->queuehosts->first->host->name, 'host3', 'host3 bound to queue AdHoc');
qx($^X -Ilib bin/tapper host-bind --host=host3 --queue=AdHoc --off);
is($queue_result->deniedhosts->count, 0, 'host3 binding to queue AdHoc removed');

TODO: { local $TODO = "host-update --pool_count not yet implemented";
$retval = qx($^X -Ilib bin/tapper host-update --name=host2 --pool_count 2);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find({name => 'host2'});
is($host_result->pool_free, '2', 'Host2 is now a pool host with 2 elements');

my $job = model('TestrunDB')->resultset('TestrunScheduling')->new({host_id => 11, # host_id 11 is host2
                                                                   testrun_id => 3001,
                                                                  })->insert;
$job->mark_as_running();

$retval = qx($^X -Ilib bin/tapper host-update --name=host2 --pool_count 3);
diag($retval) if $?;
is($?, 0, 'Update host / return value');

$retval = qx($^X -Ilib bin/tapper host-list --name=host2 -v);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
like($retval, qr(1/3), 'Poolcount updated');
}

done_testing();
