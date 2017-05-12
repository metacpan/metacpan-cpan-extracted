use strict;
use warnings;
use 5.010;

#################################################
#                                               #
# This test checks whether messages in order    #
# are handled correctly.                        #
#                                               #
#################################################

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Model 'model';

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

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


my $state = Tapper::MCP::State->new(23);

# ignore timeout handling in this test
my $timeout_span = 1000;

sub initial_state
{

        {'current_state' => 'started',
          'install' => {
                        'timeout_install_span' => $timeout_span,
                        'timeout_boot_span' => $timeout_span,
                        'timeout_current_date' => undef
                       },
                         'prcs' => [
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload',
                                     'timeout_testprograms_span' => [ $timeout_span ],
                                    },
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload',
                                     'timeout_testprograms_span' => [ 1 ],
                                    },
                                   ],
                                     'results' => []
                             }
}

my ($error, $timeout);
$error = $state->state_init(initial_state());
($error, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
($error, $timeout) = $state->update_state(message_create({state => 'start-install'}));
($error, $timeout) = $state->update_state(message_create({state => 'end-install'}));
($error, $timeout) = $state->update_state(message_create({state => 'start-testing', prc_number=> 0}));
($error, $timeout) = $state->update_state(message_create({state => 'end-testprogram', prc_number=> 0, testprogram=> 0}));
($error, $timeout) = $state->update_state(message_create({state => 'end-testing', prc_number=> 0}));
($error, $timeout) = $state->update_state(message_create({state => 'start-guest', prc_number=> 1}));
($error, $timeout) = $state->update_state(message_create({state => 'start-testing', prc_number=> 1}));


is_deeply($state->state_details->state_details->{results},
          [
           {
            'msg' => 'Installation finished',
            'error' => 0
           },
           {
            'msg' => 'Testing finished in PRC 0',
            'error' => 0
           }
          ], 'MCP results');

sleep 2; # make sure timeout of test0 in PRC1 hits
my $message = model('TestrunDB')->resultset('Message')->search({message => 'does not exist' , testrun_id => 23});
($error, $timeout) = $state->update_state($message);

# This is some kind of a hack. When all runs as expected PRC1 is now in
# state lasttest, i.e. it waits for "end-testing". It has 60 seconds
# timeout for this message (which is hardcoded because no config is
# available at the relevant point). We do not want to wait that long and
# thus simply force a timeout_date in the past.
$state->state_details->state_details->{prcs}->[1]->{timeout_current_date} = 1;

($error, $timeout) = $state->update_state($message);
is($state->state_details->current_state(), 'finished', 'Timeout of testprogram handles correctly in PRC1');

done_testing();
