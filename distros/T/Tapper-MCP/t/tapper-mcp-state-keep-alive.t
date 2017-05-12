use strict;
use warnings;
use 5.010;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Model 'model';


BEGIN{use_ok('Tapper::MCP::State')}

######################################################################
#
# Test handling of keep-alive messages in Tapper::MCP::State
#
######################################################################



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


my $initial_state =  {
                      'keep_alive'    => {timeout_span => 3, timeout_date => undef },
                      'current_state' => 'started',
                      'install' => {
                                    'timeout_install_span' => '7200',
                                    'timeout_boot_span' => '7200',
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
                             };


my ($retval, $timeout, $db_state);

$retval = $state->state_init($initial_state);
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
ok($timeout <= 3, 'Keep_alive timeout returned'); # This test depends on the fact that there is less than 2 hours between state_init and update_state. Probably a reasonable assumption
sleep(3);
($retval, $timeout) = $state->update_state();
my $result = $state->state_details->results();
is_deeply($result, [{
                     error => 1,
                     msg => "No plugin defined in keep_alive. I deactivate keep-alive for this testrun.",
                    }],
          'Missing keepalive plugin detected'
         );

my $cfg = {mcp_callback_handler => {plugin => 'Dummy'},
           hostname => 'iring',
          };
$state = Tapper::MCP::State->new(testrun_id => $testrun_id, cfg => $cfg);
isa_ok($state, 'Tapper::MCP::State');

$retval = $state->state_init($initial_state);
($retval, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
ok($timeout <= 3, 'Keep_alive timeout returned'); # This test depends on the fact that there is less than 2 hours between state_init and update_state. Probably a reasonable assumption
sleep(3);
($retval, $timeout) = $state->update_state();
$result = $state->state_details->results();
is_deeply($result, [], 'No issues found for keep-alive');
done_testing();
