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
                        'timeout_install_span' => '7200',
                        'timeout_boot_span' => $timeout_span,
                        'timeout_current_date' => undef
                       },
                         'prcs' => [
                                    {
                                     'timeout_boot_span' => $timeout_span,
                                     'timeout_current_date' => undef,
                                     'results' => [],
                                     'current_state' => 'preload',
                                     # not evaluated, just needed to know the number of testprograms
                                     'timeout_testprograms_span' => [ 5, 5 ],
                                    },
                                   ],
                                     'results' => []
                             }
}

my ($error, $timeout);
$error = $state->state_init(initial_state());
is($error, 0, 'Init succeeded');
($error, $timeout) = $state->update_state(message_create({state => 'takeoff'}));
is($error, 0, 'State takeoff');
($error, $timeout) = $state->update_state(message_create({state => 'start-install'}));
is($error, 0, 'State start-install');
($error, $timeout) = $state->update_state(message_create({state => 'end-install'}));
is($error, 0, 'State end-install');
($error, $timeout) = $state->update_state(message_create({state => 'start-testing', prc_number=> 0}));
is($error, 0, 'State start-testing');
($error, $timeout) = $state->update_state(message_create({state => 'end-testprogram', prc_number=> 0, testprogram=> 0}));
is($error, 0, 'End first testprogram');
($error, $timeout) = $state->update_state(message_create({state => 'end-testprogram', prc_number=> 0, testprogram=> 1}));
is($error, 0, 'End second testprogram');
($error, $timeout) = $state->update_state(message_create({state => 'end-testing', prc_number=> 0}));
is($error, 1, 'End testing');


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

###########################################################
#                                                         #
# Check state handling for tests without Tapper Installer #
#                                                         #
###########################################################




my $no_install_state = {
                        'current_state' => 'started',
                        'prcs' => [
                                   {
                                    'timeout_boot_span' => $timeout_span,
                                    'timeout_current_date' => undef,
                                    'results' => [],
                                    'current_state' => 'preload',
                                    # not evaluated, just needed to know the number of testprograms
                                    'timeout_testprograms_span' => [ 5, 5 ],
                                   },
                                  ],
                        'results' => []

                       };
$error = $state->state_init($no_install_state);
is($error, 0, 'Init succeeded');
($error, $timeout) = $state->update_state(message_create({state => 'takeoff', skip_install => 1}));
is($error, 0, 'State takeoff');
($error, $timeout) = $state->update_state(message_create({state => 'start-testing', prc_number=> 0}));
is($error, 0, 'State start-testing');
($error, $timeout) = $state->update_state(message_create({state => 'end-testprogram', prc_number=> 0, testprogram=> 0}));
is($error, 0, 'End first testprogram');
($error, $timeout) = $state->update_state(message_create({state => 'end-testprogram', prc_number=> 0, testprogram=> 1}));
is($error, 0, 'End second testprogram');
($error, $timeout) = $state->update_state(message_create({state => 'end-testing', prc_number=> 0}));
is($error, 1, 'End testing');

done_testing();
