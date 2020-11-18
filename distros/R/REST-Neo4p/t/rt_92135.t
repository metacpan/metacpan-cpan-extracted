#$Id$
use Test::More tests => 6;
use Module::Build;
use lib qw|../lib lib|;
use lib 't/lib';
use Neo4p::Connect;
use REST::Neo4p;
use REST::Neo4p::Batch;
use strict;
use warnings;
no warnings qw(once);

my $build;
my ($user,$pass) = @ENV{qw/REST_NEO4P_TEST_USER REST_NEO4P_TEST_PASS/};
my $dealerNode;
eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : $ENV{REST_NEO4P_TEST_SERVER} // 'http://127.0.0.1:7474';
my $num_live_tests = 6;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  my $version = REST::Neo4p->neo4j_version;
  my $VERSION_OK = REST::Neo4p->_check_version(2,0);
  my $source = 'flerb';
  SKIP : {
    skip "Server version $version < 2.0", $num_live_tests unless $VERSION_OK;
    skip 'batch unimplemented for Neo4j::Driver', $num_live_tests if ref(REST::Neo4p->agent) =~ /Neo4j::Driver/;
    eval {
      batch {
      ok $dealerNode = REST::Neo4p::Node->new({source => $source}), 'create node in batch';
      ok $dealerNode->set_labels("Dealer"), 'set label in batch';
    } 'keep_objs';
    };
    if ($@) { fail $@ } else { pass 'batch ran ok' }
    isa_ok $dealerNode, 'REST::Neo4p::Node';
    ok grep (/Dealer/,$dealerNode->get_labels), 'node label is set after batch run';
    is $dealerNode->get_property('source'), $source, 'source property is set after batch';
  }
  }


END {
  $dealerNode && $dealerNode->remove;
}
