#$Id#
use Test::More tests => 29;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 'lib';
use lib 't/lib';
use Neo4p::Connect;
use REST::Neo4p;
use REST::Neo4p::Schema;
use strict;
use warnings;
no warnings qw(once);

my $test_label =  'L79ed3b3a_515d_4f2b_89dc_9d1f0868b50c';
my ($n1, $n2);
my $build;
my ($user,$pass) = @ENV{qw/REST_NEO4P_TEST_USER REST_NEO4P_TEST_PASS/};

eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : $ENV{REST_NEO4P_TEST_SERVER} // 'http://127.0.0.1:7474';
my $num_live_tests = 29;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  my $version = REST::Neo4p->neo4j_version;
  my $VERSION_OK = REST::Neo4p->_check_version(2,0,1);
  SKIP : {
    skip "Server version $version < 2.0.1", $num_live_tests unless $VERSION_OK;
    ok my $schema = REST::Neo4p::Schema->new, 'new Schema object';
    isa_ok $schema, 'REST::Neo4p::Schema';
    is $schema->_handle, REST::Neo4p->handle, 'handle correct';
    isa_ok $schema->_agent, 'REST::Neo4p::Agent';
    ok $schema->create_index($test_label,'name'), 'create name index on test label';

    is_deeply [$schema->get_indexes($test_label)],['name'], 'name index listed';
    ok $schema->create_index($test_label => 'number'), 'create number index on test label';
    is_deeply [sort $schema->get_indexes($test_label)], [sort qw/name number/], 'both indexes now listed';
    ok $schema->create_index($test_label, 'street', 'city'), 'create multiple indexes in single call';
    is_deeply [sort $schema->get_indexes($test_label)], [sort qw/name number street city/], 'both indexes now listed';
    for (qw/name number street city/) {
      eval {
	ok $schema->drop_index($test_label, $_), "drop index on '$_'";
      };
      if (my $e = REST::Neo4p::Exception->caught) {
	diag $e->message || $e->neo4j_message;
      }
      elsif ($e = Exception::Class->caught) {
	die $e;
      }
    }
    ok !$schema->get_indexes($test_label), 'indexes gone';
    ok $schema->create_unique_constraint($test_label, 'name'), 'create unique name constraint';
    ok $schema->create_unique_constraint($test_label, 'street', 'city'), 'create multiple contraints';
    is_deeply [sort $schema->get_constraints($test_label)], [sort qw/name street city/], 'all constraints now listed';
    ok $n1 = REST::Neo4p::Node->new(), 'create node';
    ok $n1->set_labels($test_label), 'set label on node';
    ok $n1->set_property({name => 'Fred'}), 'set name property on node';

    ok $n2 =  REST::Neo4p::Node->new(), 'create second node';
    ok $n2->set_labels($test_label), 'set label on second node';
    ok $n2->set_property({name => 'Wilma'}), 'set name property on node';
# The following should work; instead it hangs the server-
    throws_ok { $n2->set_property({ name => "Fred" }) } 'REST::Neo4p::ConflictException', 'setting non-unique name property throws conflict exception';
#    my $q = REST::Neo4p::Query->new("MATCH (n:$test_label) WHERE n.name = 'Wilma' SET n.name = 'Fred'");
#    $q->execute;
#    like $q->errstr, qr/already exists.*and property/, 'cypher query to set Wilma to Fred (non-unique) fails ok';
    1;
    is $n2->get_property('name'), 'Wilma', 'name property not modified on second node';
    ok $schema->drop_unique_constraint($test_label, qw/name street city/), 'drop all constraints';
    ok $n2->set_property({name=>"Fred"}), 'constraint lifted, can set label';
    is $n2->get_property('name'), 'Fred', 'property now set';
    1;
  }

}

END {
  $n1 && $n1->remove;
  $n2 && $n2->remove;
}

