#-*-perl-*-
#$Id$#
use Test::More qw(no_plan);
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);
#$SIG{__DIE__} = sub { print $_[0] };

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
  ok my $agent = REST::Neo4p->agent, 'got agent';
  throws_ok { $agent->batch_length } 'REST::Neo4p::LocalException', 'not in batch mode ok';
  ok $agent->batch_mode(1), 'set batch mode';
  ok !$agent->batch_length, 'queue empty';
  is $agent->get_node(1), '{1}', 'add to batch queue with get_node';
  is $agent->get_relationship(3), '{2}', 'add to batch queue with get_relationship';
  is $agent->get_data(qw(node index fred)),'{3}', 'add to batch queue with get_data';
  is $agent->batch_length, 3, 'batch length';
  is @{$agent->{__batch_queue}}, 3, 'actual queue array length';
  my $response_content_handle;
  lives_ok { 
      $response_content_handle = $agent->execute_batch 
  } ;
  ok -e $response_content_handle->filename, 'got responses in tmpfile';
  is $agent->batch_length, 0, 'queue length reset to 0';
  ok !defined $agent->{__batch_queue}, 'queue reset';
}

