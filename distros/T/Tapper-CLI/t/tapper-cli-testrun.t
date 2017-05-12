#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $s_testrun_result = `$^X -Ilib bin/tapper testrun-list --id=23 -v`;
ok($s_testrun_result, 'list single testrun');

my %h_testrun_elements = map { /^\s+(.+?): (.+)\s*/ } split /\n/, $s_testrun_result;

my $testrun = model('TestrunDB')->resultset('Testrun')->find(23);

is( $h_testrun_elements{Id}         , 23        , "testrun id");
is( $h_testrun_elements{Notes}      , 'perfmon' , "testrun notes - " . $testrun->notes . " - " . $s_testrun_result);
is( $h_testrun_elements{Shortname}  , 'perfmon' , "testrun shortname");
is( $h_testrun_elements{Topic}      , 'Software', "testrun topic_name");

my $precond_id = `$^X -Ilib bin/tapper precondition-new --condition="precondition_type: image\nname: suse.tgz"`;
chomp $precond_id;

my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
like($precond->precondition, qr"precondition_type: image", 'inserted precond / yaml');

# --------------------------------------------------

my $old_precond_id = $precond_id;
$precond_id = `$^X -Ilib bin/tapper precondition-update --id=$old_precond_id --shortname="foobar-perl-5.11" --condition="precondition_type: file\nname: some_file"`;
chomp $precond_id;

$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond->id, $old_precond_id, 'update precond / id');
is($precond->shortname, 'foobar-perl-5.11', 'update precond / shortname');
like($precond->precondition, qr'precondition_type: file', 'update precond / yaml');

# --------------------------------------------------

my $testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --requested_host=iring --precondition=1`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->testrun_scheduling->requested_hosts->first->host->name, 'iring', 'inserted testrun / first requested host');
is($testrun->topic_name, 'Software', 'Topic for new testrun');

# --------------------------------------------------
#
# Testrun with inexisting host
#


$testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --requested_host=nonexisting --precondition=1 2>&1`;
is($testrun_id, "Host 'nonexisting' does not exist\n", 'Requested host must exist');

# --------------------------------------------------
#
# Testrun with requested feature
#

$testrun_id = `$^X -Ilib bin/tapper testrun-new --requested_feature='mem > 4096' --queue=KVM --precondition=1`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->testrun_scheduling->requested_features->first->feature, 'mem > 4096', 'inserted testrun / first requested feature');
is($testrun->testrun_scheduling->queue->name, 'KVM', 'inserted testrun / Queue');

# --------------------------------------------------

my $old_testrun_id = $testrun_id;
$testrun_id = `$^X -Ilib bin/tapper testrun-update --id=$old_testrun_id --topic=Hardware`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
is($testrun->id, $old_testrun_id, 'updated testrun / id');
is($testrun->topic_name, "Hardware", 'updated testrun / topic');

# --------------------------------------------------

`$^X -Ilib bin/tapper testrun-delete --id=$testrun_id --force`;
$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
is($testrun, undef, "delete testrun");

`$^X -Ilib bin/tapper precondition-delete --id=$precond_id --force`;
$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond, undef, "delete precond");

# --------------------------------------------------

$testrun_id = `$^X -Ilib bin/tapper testrun-new --macroprecond=t/files/kernel_boot.mpc -Dkernel_version=2.6.19 --requested_host=iring`;
chomp $testrun_id;
$testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id,})->first();

my @precond_array = $testrun->ordered_preconditions;

is($precond_array[0]->precondition_as_hash->{precondition_type}, "package",'Parsing macropreconditions, first sub precondition');
is($precond_array[1]->precondition_as_hash->{precondition_type}, "exec",'Parsing macropreconditions, second sub precondition');
is($precond_array[1]->precondition_as_hash->{options}->[0], "2.6.19",'Parsing macropreconditions, template toolkit substitution');
is($precond_array[0]->precondition_as_hash->{filename}, "kernel/linux-2.6.19.tar.gz",'Parsing macropreconditions, template toolkit with if block');

$testrun_id = `$^X -Ilib bin/tapper testrun-new --macroprecond=t/files/kernel_boot.mpc --requested_host=iring 2>&1`;
chomp $testrun_id;
like($testrun_id, qr/Expected macro field 'kernel_version' missing./, "missing mandatory field recognized");

$testrun_id = `$^X -Ilib bin/tapper testrun-new --requested_host=iring 2>&1`;
chomp $testrun_id;
is($testrun_id, 'error: At least one of "precondition" or "macroprecond" is required', "Prevented testrun without precondition");

$testrun_id = `$^X -Ilib bin/tapper testrun-rerun --id=23`;
chomp $testrun_id;
ok($testrun_id, 'Got some testrun');
isnt($testrun_id, 23, 'Rerun creates new testrun');
$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
my $testrun_old = model('TestrunDB')->resultset('Testrun')->find(23);
@precond_array = $testrun->ordered_preconditions;
my @precond_array_old = $testrun_old->ordered_preconditions;
is_deeply(\@precond_array, \@precond_array_old, 'Rerun testrun with same preconditions');

# --------------------------------------------------

my $queue_id = `$^X -Ilib bin/tapper queue-new --name="Affe" --priority=4711`;
chomp $queue_id;

my $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
ok($queue->id, 'inserted queue / id');
is($queue->name, "Affe", 'inserted queue / name');
is($queue->priority, 4711, 'inserted queue / priority');

$testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --requested_host=iring --precondition=1 --precondition=2 --queue=Affe --auto_rerun`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->topic_name, 'Software', 'Topic for new testrun');
is($testrun->testrun_scheduling->queue->name, 'Affe', 'Queue for new testrun');
is($testrun->testrun_scheduling->auto_rerun, '1', 'Auto_rerun new testrun');

# --------------------------------------------------

my $host_id = `$^X -Ilib bin/tapper host-new --name=fritz --active`;
chomp $host_id;

my $host = model('TestrunDB')->resultset('Host')->find($host_id);
ok($host->id, 'inserted testrun has id');
is($host->id, $host_id, 'inserted testrun has right id');
is($host->name, 'fritz', 'Name of new host');


# --------------------------------------------------

$testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --rerun_on_error=3 --precondition=1`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->rerun_on_error, 3, 'Setting rerun on error');


# --------------------------------------------------
#         Priorities
# --------------------------------------------------
$testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --priority --precondition=1`;
chomp $testrun_id;
$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
ok(defined($testrun->testrun_scheduling->prioqueue_seq), 'inserted testrun is in priority queue');

# --------------------------------------------------
#         Notify
# --------------------------------------------------

$testrun_id = `$^X -Ilib bin/tapper testrun-new --topic=Software --notify --precondition=1`;
chomp $testrun_id;
$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
my $notify = model('TestrunDB')->resultset('Notification')->first;
is($notify->filter, "testrun('id') == $testrun_id", 'Notification with filter');

# --------------------------------------------------
#         Pause/Continue
# --------------------------------------------------

# validate current state after new
my $job;
$job = model('TestrunDB')->resultset('TestrunScheduling')->search({testrun_id => $testrun_id})->first; # refetch
is($job->status(), 'schedule', 'state after new is schedule');

# pause
my $paused_testrun_id = `$^X -Ilib bin/tapper testrun-pause --id=$testrun_id`;
$job = model('TestrunDB')->resultset('TestrunScheduling')->search({testrun_id => $testrun_id})->first; # refetch
is($job->status, 'prepare', 'state after pause is prepare');

# continue
my $continued_testrun_id = `$^X -Ilib bin/tapper testrun-continue --id=$testrun_id`;
$job = model('TestrunDB')->resultset('TestrunScheduling')->search({testrun_id => $testrun_id})->first; # refetch
is($job->status, 'schedule', 'state after continue is schedule');

# --------------------------------------------------
#         Cancel
# --------------------------------------------------

$testrun->testrun_scheduling->status('running');
$testrun->testrun_scheduling->update;

`$^X -Ilib bin/tapper testrun-cancel --id=$testrun_id --comment='foo'`;
my $message = model('TestrunDB')->resultset('Message')->search({testrun_id => $testrun_id})->first;
is_deeply($message->message, {error => 'foo', state => 'quit'}, 'Cancel message sent to MCP');
done_testing();
