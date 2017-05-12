use strict;
use warnings;
use 5.010;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Model 'model';

BEGIN{use_ok('Tapper::MCP::State')}

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

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $initial_state = {
                     'current_state' => 'started',
                     'install' => {
                                   'timeout_install_span' => 300,
                                   'timeout_boot_span'    => 100,
                                   'timeout_current_date' => undef
                                  },
                     'prcs' => [
                                {
                                 'timeout_boot_span' => 700,
                                 'timeout_current_date' => undef,
                                 'results' => [],
                                 'current_state' => 'preload'
                                },
                                {
                                 'timeout_testprograms_span' => [ 500, 200],
                                 'timeout_boot_span' => 200,
                                 'timeout_current_date' => undef,
                                 'results' => [],
                                 'current_state' => 'preload'
                                },
                                {
                                 'timeout_testprograms_span' => [ 1000, 400],
                                 'timeout_boot_span' => 3,
                                 'timeout_current_date' => undef,
                                 'results' => [],
                                 'current_state' => 'preload'
                                },
                                {
                                 'timeout_testprograms_span' => [ 1500, 600],
                                 'timeout_boot_span' => 400,
                                 'timeout_current_date' => undef,
                                 'results' => [],
                                 'current_state' => 'preload'
                                }
                               ],
                     'results' => []
                    };


my ($retval, $timeout);

{
        my $state = Tapper::MCP::State->new(23);
        isa_ok($state, 'Tapper::MCP::State');

        $retval = $state->state_init($initial_state);
        ($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
        ($retval, $timeout) = $state->update_state(message_create({state => 'start-install'}));
        ($retval, $timeout) = $state->update_state(message_create({state => 'end-install'}));
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 1}));
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 2}));
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-guest', prc_number => 3}));
        ($retval, $timeout) = $state->update_state(message_create({ state => 'start-testing', prc_number => 0}));
        $retval = $state->state_details->current_state();
        is($retval, 'testing', 'Current state after 3. guest started');

}

{
        my $state = Tapper::MCP::State->new(23);
        isa_ok($state, 'Tapper::MCP::State');

        $retval = $state->state_init(undef, 1);
        is( $state->state_details->current_state, 'testing', 'State after revive');

}

done_testing();
