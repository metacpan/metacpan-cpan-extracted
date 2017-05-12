#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;

use Tapper::Cmd::Queue;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $queue = Tapper::Cmd::Queue->new();
isa_ok($queue, 'Tapper::Cmd::Queue', '$queue');

my $queue_id   = $queue->add({name => 'newqueue', priority => 100});
my $queue_rs = model('TestrunDB')->resultset('Queue')->find($queue_id);
isa_ok($queue, 'Tapper::Cmd::Queue', 'Insert queue / queue id returned');

$queue_rs = model('TestrunDB')->resultset('Queue');
foreach my $queue_r ($queue_rs->all) {
        is($queue_r->runcount, $queue_r->priority, "Insert queue / runcount queue ".$queue_r->name);
        $queue_r->runcount(-1);
        $queue_r->update;
}

my $queue_id_updated = $queue->update($queue_id, {priority => 1337});
ok(defined($queue_id_updated), 'Update queue / success');
foreach my $queue_r ($queue_rs->all) {
        is($queue_r->runcount, $queue_r->priority, "Update queue / runcount queue ".$queue_r->name);
}

my $queue_result = model('TestrunDB')->resultset('Queue')->find($queue_id);

$queue_result->is_deleted(0);
$queue_result->active(1);

$queue->del($queue_result->id);

# update queue information;
$queue_result = model('TestrunDB')->resultset('Queue')->find($queue_id);

is($queue_result, undef, 'Empty Queue deleted');

$queue_id   = $queue->add({name => 'queue_with_jobs', priority => 100});
my $job = model('TestrunDB')->resultset('TestrunScheduling')->first;
$job->queue_id($queue_id); $job->update();
$queue->del($queue_id);


$queue_result = model('TestrunDB')->resultset('Queue')->find($queue_id);
isa_ok($queue_result, 'Tapper::Schema::TestrunDB::Result::Queue', 'Nonempty queue exists after deleted');
is($queue_result->is_deleted, 1, 'Queue deleted by setting deleted flag');
is($queue_result->active, 0, 'Queue no longer active');
my $queue_id_new = $queue->add({name => 'queue_with_jobs', priority => 100});
is($queue_id_new, $queue_id, 'New on queue with deleted flag reactivated the existing one');

done_testing();

