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
my $state = Tapper::MCP::State->new(23);
isa_ok($state, 'Tapper::MCP::State');

sub message_create
{
        my ($data) = @_;
        my $message = model('TestrunDB')->resultset('Message')->new
                  ({
                   message => $data,
                   testrun_id => 23,
                   });
        $message->insert;
        return $message;
}


########################################################
#                                                      #
# This test checks timeout handling in MCP::State.     #
# Please note that we can not test for the exact       #
# timeout value we expect because we do not know       #
# how much time has passed from the relevant           #
# timeout to start running and the time we check       #
# this timeout. Thus the test use $expect-1 <=$timeout #
# and $timeout <= $expect.                             #
#                                                      #
########################################################



my $timeout_span = 2;


sub initial_state
{

        {'current_state' => 'started',
          'install' => {
                        'timeout_install_span' => 3*$timeout_span,
                        'timeout_boot_span'    => $timeout_span,
                        'timeout_current_date' => undef
                       },
                         'prcs' => [
                                    {
                                     'timeout_boot_span' => 7*$timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 5, 2],
                                     'timeout_boot_span' => 2 * $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_testprograms_span' => [ 10, 4],
                                     'timeout_boot_span' => 3 * $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                     {
                                      'timeout_testprograms_span' => [ 15, 6],
                                      'timeout_boot_span' => 4 * $timeout_span,
                                      'timeout_current_date' => undef,
                                      'results' => [],
                                      'current_state' => 'preload'
                                    }
                                   ],
                                     'results' => []
                             }
}

my ($retval, $timeout);
$retval = $state->state_init(initial_state());
is($retval, 0, 'Init succeeded');
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));

my $message_rs = model('TestrunDB')->resultset('Message');
$retval = $state->state_details->current_state();
is($retval, 'reboot_install', 'Current state at installation');

sleep 3;
($retval, $timeout) = $state->update_state($message_rs);
is($state->testrun_finished, 1, 'Timeout detected');
is_deeply($state->state_details->results,
          [{
           'msg' => 'timeout hit while waiting for installer booting',
           'error' => 1,
          }],
          'Timeout added to results list');

my $expected_timeout;
my $start_time = time();
$retval = $state->state_init(initial_state());
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
diag '';
diag '################################################# #';
diag 'Timeout tests! Might fail on heavy loaded         #';
diag 'machines due to pathological timing issues.       #';
diag 'Usually rerunning the tests succeeds.             #';
diag '################################################# #';

{
        local $TODO = "protect somewhat sensitive timeout handling";

        # we expect timeout_install_span
        $expected_timeout = 3*$timeout_span-(time() - $start_time);
        ($retval, $timeout) = $state->update_state(message_create({state => 'start-install'}));
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'Timeout returned after start-install within expected range');

        # we expect timeout_boot_span of PRC0
        $expected_timeout = 7*$timeout_span-(time() - $start_time);
        ($retval, $timeout) = $state->update_state(message_create({state => 'end-install'}));
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'Timeout returned after end-install within expected range');

        # we timeout_boot_span of PRC1,
        $expected_timeout = 2*$timeout_span-(time() - $start_time);
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 1}));
        is($retval, 0, '1. guest_started handled');
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'Timeout after booting first guest within expected range');

        # we still expect timeout_boot_span of PRC1, its lower than PRC2
        $expected_timeout = 2*$timeout_span-(time() - $start_time);
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 2}));
        is($retval, 0, '2. guest_started handled');
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'Timeout after booting second guest within expected range');

        # we still expect timeout_boot_span of PRC1, its lower than PRC2 and PRC3
        $expected_timeout = 2*$timeout_span-(time() - $start_time);
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 3}));
        is($retval, 0, '2. guest_started handled');
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'Timeout after booting third guest within expected range');


        $expected_timeout = 60;
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-testing', prc_number => 0}));
        $timeout = $state->state_details->prc_timeout_current_date(0) - time();
        ok(($expected_timeout - 1 <= $timeout   and $timeout <= $expected_timeout + 1),
           'PRC0 timeout for "end-testing"');
}

done_testing();
