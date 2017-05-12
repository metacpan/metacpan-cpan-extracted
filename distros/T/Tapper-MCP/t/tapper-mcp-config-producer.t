#! /usr/bin/env perl

use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use YAML;

use Tapper::Schema::TestTools;
use Tapper::Model 'model';

use Test::More;
use Test::Deep;

BEGIN { use_ok('Tapper::MCP::Config'); }


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_xenpreconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $producer = Tapper::MCP::Config->new(9);
isa_ok($producer, "Tapper::MCP::Config", 'Producer object created');

my $config = $producer->create_config();     # expects a port number

my $testrun = model('TestrunDB')->resultset('Testrun')->find(9);
my @preconditions = $testrun->ordered_preconditions;

is_deeply ($preconditions[0]->precondition_as_hash,
           {
            'guests' => [
                         {
                          'testprogram' => {
                                            'precondition_type' => 'no_option'
                                           },
                          'root' => {
                                     'precondition_type' => 'no_option'
                                    },
                          'config' => {
                                       'precondition_type' => 'no_option'
                                      }
                         }
                        ],
            'name' => 'automatically generated Xen test',
            'precondition_type' => 'virt',
            'host' => {
                       'preconditions' => [
                                           {
                                            'precondition_type' => 'no_option'
                                           },
                                           {
                                            'precondition_type' => 'second'
                                           },
                                           {
                                            precondition_type => 'nonproducer',
                                           },
                                          ],
                       'root' => {
                                  'precondition_type' => 'no_option'
                                 }
                      }
           },
           'All producers in virt precondition substituted');


$producer = Tapper::MCP::Config->new(8);

$config = $producer->create_config();
is(ref($config),'HASH', 'Config created');

cmp_deeply($config->{preconditions},
           supersetof(
                      {
                       'precondition_type' => 'no_option'
                      },
                      {
                       'precondition_type' => 'second'
                      },
                     ),
           'Single precondition producer');
$testrun = model('TestrunDB')->resultset('Testrun')->find(8);
is( int $testrun->ordered_preconditions, 3, 'Additional precondition still assigned');


done_testing();
