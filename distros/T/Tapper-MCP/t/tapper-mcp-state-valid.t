use strict;
use warnings;
use 5.010;

#################################################
#                                               #
# This test contains a number of checks for the #
# function MCP::State::is_msg_valid()           #
#                                               #
#################################################

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

BEGIN{use_ok('Tapper::MCP::State')}

my $state = Tapper::MCP::State->new(23);


my $timeout_span = 1;

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
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload'
                                    },
                                     {
                                     'timeout_boot_span' => $timeout_span,
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
$retval = $state->is_msg_valid({state => 'takeoff'});
is($retval, 1, 'Takeoff message valid');

$state->state_details->current_state('reboot_install');
isnt($state->testrun_finished, 1, 'Set current state to reboot-install');
$retval = $state->is_msg_valid({state => 'start-install'});
is($retval, 1, 'Start-install message valid');


$state->state_details->current_state('testing');
isnt($state->testrun_finished, 1, 'Set current state to testing');

$retval = $state->is_msg_valid({state => 'start-guest', prc_number => 1});
is($retval, 1, 'Message valid in last element of set of states');

$retval = $state->is_msg_valid({state => 'end-install'});
is($retval, 0, 'Invalid message detected');
ok($state->testrun_finished, 'Invalid message/testrun finished');


$retval = $state->is_msg_valid({state => 'end-testprogram', prc_number => 0, testprogram => 1});
is($retval, 0, 'Out of order testprogram detected');
is($state->state_details->prc_state(0), 'finished', 'PRC finished after out-of-order message');

done_testing();
