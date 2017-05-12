#!perl

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More;
use Test::Deep;
use YAML::Syck;

use Tapper::Cmd::Testrun;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------

my $cmd = Tapper::Cmd::Testrun->new();
isa_ok($cmd, 'Tapper::Cmd::Testrun', '$testrun');

#######################################################
#
#   check support methods
#
#######################################################

my $owner_id = Tapper::Model::get_or_create_owner('sschwigo');
is($owner_id, 12, 'get owner id for login');


#######################################################
#
#   check add method
#
#######################################################

my $testrun_args = {notes     => 'foo',
                    shortname => 'foo',
                    topic     => 'foo',
                    earliest  => DateTime->new( year   => 1964,
                                                month  => 10,
                                                day    => 16,
                                                hour   => 16,
                                                minute => 12,
                                                second => 47),
                    requested_hosts => ['iring','bullock'],
                    notify          => 'ok',
                    owner           => 'sschwigo'};

my $testrun_id = $cmd->add($testrun_args);
ok(defined($testrun_id), 'Adding testrun');
my $testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
my $retval = {owner       => $testrun->owner_id,
              notes       => $testrun->notes,
              shortname   => $testrun->shortname,
              topic       => $testrun->topic_name,
              earliest    => $testrun->starttime_earliest,
              requested_hosts => [ map {$_->host->name} $testrun->testrun_scheduling->requested_hosts->all ],
             };
my $notify = model('TestrunDB')->resultset('Notification')->search({},
                                                                   {  result_class => 'DBIx::Class::ResultClass::HashRefInflator',}
                                                                  )->first;

$testrun_args->{owner}    =  12;
delete $testrun_args->{notify};

is_deeply($retval, $testrun_args, 'Values of added test run');
cmp_deeply($notify, superhashof({event => 'testrun_finished',
                                 owner_id => 12,
                                 filter   =>       "testrun('id') == ".$testrun->id." and testrun('success_word') eq 'pass'",
                                }), 'Values of added test run');


#######################################################
#
#   check update method
#
#######################################################

my $testrun_id_new = $cmd->update($testrun_id, {hostname => 'iring'});
is($testrun_id_new, $testrun_id, 'Updated testrun without creating a new one');

$testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
$retval = {
           owner       => $testrun->owner_id,
           notes       => $testrun->notes,
           shortname   => $testrun->shortname,
           topic       => $testrun->topic_name,
           earliest    => $testrun->starttime_earliest,
           requested_hosts => [ map {$_->host->name} $testrun->testrun_scheduling->requested_hosts->all ],
          };
is_deeply($retval, $testrun_args, 'Values of updated test run');

#######################################################
#
#   check rerun method
#
#######################################################

$testrun_id_new = $cmd->rerun($testrun_id);
isnt($testrun_id_new, $testrun_id, 'Rerun testrun with new id');

$testrun        = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
my $testrun_new = model('TestrunDB')->resultset('Testrun')->find($testrun_id_new);

$retval = { owner       => $testrun->owner_id,
            notes       => $testrun->notes,
            shortname   => $testrun->shortname,
            topic       => $testrun->topic_name,
          };
$testrun_args = {owner       => $testrun_new->owner_id,
                 notes       => $testrun_new->notes,
                 shortname   => $testrun_new->shortname,
                 topic       => $testrun_new->topic_name,
          };
is_deeply($retval, $testrun_args, 'Values of rerun test run');

my @precond_array     = $testrun_new->ordered_preconditions;
my @precond_array_old = $testrun->ordered_preconditions;
is_deeply(\@precond_array, \@precond_array_old, 'Rerun testrun with same preconditions');



#######################################################
#
#   check del method
#
#######################################################

$retval = $cmd->del(101);
is($retval, 0, 'Delete testrun');
$testrun = model('TestrunDB')->resultset('Testrun')->find(101);
is($testrun, undef, 'Delete correct testrun');

my $tr_spec = YAML::Syck::LoadFile('t/misc_files/testrun.mpc');
my @testruns = $cmd->create($tr_spec->{description});
is(int @testruns, 4, 'Testruns created from requested_hosts_all, requested_hosts_any, requested_hosts_any');

TODO: {
        local $TODO = 'searching all hosts with a given feature set is not yet implemented';
        is(int @testruns, 6, 'Testruns created from all requests');
}

for (my $i=1; $i<=2; $i++) {
        $testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
        is($testrun->testrun_scheduling->requested_hosts->count, 1, "$i. requested_host_all testrun with one requested host");
        is($testrun->preconditions, 6, "$i. requested_host_all testrun has preconditions assigned");
}

$testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
is($testrun->testrun_scheduling->requested_hosts->count, 2, "requested_host_any testrun with two requested hosts");
is($testrun->preconditions, 6, "requested_host_any testrun has preconditions assigned");
is($testrun->topic_name, 'Topic', 'Topic set from description');
is($testrun->testrun_scheduling->queue->name, 'Kernel', 'Queue set from description');

$testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
is($testrun->testrun_scheduling->requested_features->count, 2, "requested_features_any testrun with two requested features");
is($testrun->preconditions, 6, "requested_feature_any testrun has preconditions assigned");

$testrun = model('TestrunDB')->resultset('Testrun')->find(3001);
$retval = $cmd->cancel(3001);
is($testrun->testrun_scheduling->status, 'finished', 'Testrun was not running and is now finished');

$testrun->testrun_scheduling->status('running'); # can't use mark_as_running because database is incomplete (undefined values)
$testrun->testrun_scheduling->update;
$cmd->cancel(3001, 'Go away!');

my $message = model('TestrunDB')->resultset('Message')->search({testrun_id => 3001})->first;
is_deeply($message->message,{
                             'error' => 'Go away!',
                             'state' => 'quit'
                            },
          'Cancel message in DB'
         );
is_deeply($cmd->status(3004), { 'success_ratio' => undef, 'status' => 'schedule' }, 'Query scheduled testrun');

done_testing;
