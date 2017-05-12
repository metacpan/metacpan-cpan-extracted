use strict;
use warnings;
use 5.010;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Model 'model';


BEGIN{use_ok('Tapper::MCP::State')}



# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
my $testrun_id = 23;
my $state = Tapper::MCP::State->new($testrun_id);
isa_ok($state, 'Tapper::MCP::State');


sub message_create
{
        my ($data) = @_;
        my $message = model('TestrunDB')->resultset('Message')->new
                  ({
                   message => $data,
                   testrun_id => $testrun_id,
                   });
        $message->insert;
        return $message;
}



my $timeout_span = 100;


sub initial_state
{

        {'current_state' => 'started',
          'install' => {
                        'timeout_install_span' => '7200',
                        'timeout_boot_span' => $timeout_span,
                        'timeout_current_date' => undef
                       },
                         'prcs' => [
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 5, 2],
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 5, 2],
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                     {
                                      'timeout_testprograms_span' => [ 5, 2],
                                      'timeout_boot_span' => $timeout_span,
                                      'timeout_current_date' => undef,
                                      'results' => [],
                                      'current_state' => 'preload'
                                    }
                                   ],
                                     'results' => []
                             }
}

my ($retval, $timeout, $db_state);

$retval = $state->state_init(initial_state());
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));

($retval, $timeout) = $state->update_state(message_create({state => 'start-install'}));
is($retval, 0, 'start-install handled');
$retval = $state->state_details->current_state();
is($retval, 'installing', 'Current state at installation');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');



($retval, $timeout) = $state->update_state(message_create({state => 'end-install'}));
is($retval, 0, 'end-install handled');
$retval = $state->state_details->current_state();
is($retval, 'reboot_test', 'Current state after installation');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');


($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 1}));
is($retval, 0, '1. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 1. guest started');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');

($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 2}));
is($retval, 0, '2. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 2. guest started');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');

($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 3}));
is($retval, 0, '3. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 3. guest started');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');


($retval, $timeout) = $state->update_state(message_create({ state => 'start-testing', prc_number => 0}));
is($retval, 0, '3. guest_started handled');
$retval = $state->state_details->current_state();
is($retval, 'testing', 'Current state after 3. guest started');
$db_state = model('TestrunDB')->resultset('State')->search({testrun_id => $testrun_id})->first;
is_deeply($db_state->state, $state->state_details->state_details, 'State updated in db');


done_testing();
