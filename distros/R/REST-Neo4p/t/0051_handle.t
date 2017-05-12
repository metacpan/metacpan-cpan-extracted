#-*-perl-*-
#$Id#
use Test::More;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);

my @cleanup;
my $build;
my ($user,$pass);

eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';
my $num_live_tests = 1;

use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  $DB::single=1;
  ok my $n1 = REST::Neo4p::Node->new(), 'create node 1 in handle 0';
  is $n1->_handle, 0, 'node 1 handle correct';
  is (REST::Neo4p->create_and_set_handle, 1, 'created and set handle 1');
  is $REST::Neo4p::HANDLE, 1, 'active handle now 1';
  ok !REST::Neo4p->connected, 'handle 1 is active, but not connected';
  ok (!connect($TEST_SERVER,$user,$pass), 'connect with handle 1');
  ok (REST::Neo4p->connected, 'handle 1 now connected');
  is scalar @REST::Neo4p::HANDLES, 2, '2 handles exist...';
  isnt "$REST::Neo4p::HANDLES[0]->{_agent}","$REST::Neo4p::HANDLES[1]->{_agent}", '... and have different agents';
  my $agt = REST::Neo4p->agent;
  is "$REST::Neo4p::HANDLES[1]->{_agent}","$agt", 'current agent via REST::Neo4p-agent is handle 1 agent';
  ok my $n2 = REST::Neo4p::Node->new(), 'create node 2 in handle 1';
  is $n2->_handle, 1, 'correct handle';
  is (REST::Neo4p->set_handle(0), 0, 'set handle 0 active');
  is $REST::Neo4p::HANDLE, 0, 'active handle now 0';
  ok $n2->remove, 'remove n2 with its own handle (1)';
  is $REST::Neo4p::HANDLE, 0, 'active handle still handle 0';
  ok $n1->remove, 'remove n1 with its own handle (0)';

}

done_testing;
