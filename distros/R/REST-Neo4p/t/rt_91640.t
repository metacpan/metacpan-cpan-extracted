#$Id$
use utf8;
use Test::More tests => 27;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 'lib';
use lib 't/lib';
use REST::Neo4p;
use Neo4p::Test;
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);
my @cleanup;

my $build;
my ($user,$pass) = @ENV{qw/REST_NEO4P_TEST_USER REST_NEO4P_TEST_PASS/};

eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
};

my $TEST_SERVER = $build ? $build->notes('test_server') : $ENV{REST_NEO4P_TEST_SERVER} // 'http://127.0.0.1:7474';
my $num_live_tests = 27;
my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;


#SKIP : {
#  skip "Neo4j server version >= 2.0.0-M02 required, skipping...", $num_live_tests unless  REST::Neo4p->_check_version(2,0,0,2);

my $neo4p = 'REST::Neo4p';
my ($n, $m, $t);
SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  ok $t = Neo4p::Test->new, 'test graph object';
  ok $t->create_sample, 'create sample graph';
  ok my ($n) = $t->find_sample( name => 'I' ), 'get I node';
  ok my $cyr_string = 'Сохранить', 'create $cyr_string in utf8 context';
  diag('use utf8');
  lives_ok { $n->set_property( { utf8 => $cyr_string } ); } 'cyrillic $string allowed by set_property';
  is $n->get_property('utf8'), $cyr_string, 'cyrillic value correctly set';
  lives_ok { $n->set_property( { utf8lit => 'Сохранить' } ) } 'cyrillic literal allowed by set_property';
  is $n->get_property('utf8lit'), $cyr_string, 'cyrillic literal value correctly set';
  ok my $stmt =<<STMT1, 'create $stmt in utf8 context';
 MATCH (n) 
 WHERE id(n) = $$n 
 AND n.utf8 = 'Сохранить'
 RETURN n
STMT1
  my $q;
  lives_ok { $q = REST::Neo4p::Query->new($stmt) } 'create query containing cyrillic literal';
  lives_ok { $q->execute } 'execute query containing cyrillic literal';
  ok my $r = $q->fetch, 'obtained match';
  isa_ok $$r[0],'REST::Neo4p::Node';
  is $$r[0]->get_property('utf8'), 'Сохранить', 'cyrillic property value retrieved correctly';
  $n->remove_property('utf8','utf8lit');
  ok !$n->get_property('utf8'),'property removed';
  ok !$n->get_property('utf8lit'),'property removed';
  no utf8;
  diag('no utf8');
  ok $cyr_string = 'Сохранить', 'create $cyr_string in no utf8 context';
  ok $stmt =<<STMT1, 'create $stmt in no utf8 context';
 MATCH (n) 
 WHERE id(n) = $$n 
 AND n.utf8 = 'Сохранить'
 RETURN n
STMT1
  lives_ok { $n->set_property( { utf8 => $cyr_string } ); } 'cyrillic $string allowed by set_property';
  is $n->get_property('utf8'), $cyr_string, 'cyrillic value correctly set';
  lives_ok { $n->set_property( { utf8lit => 'Сохранить' } ) } 'cyrillic literal allowed by set_property';
  is $n->get_property('utf8lit'), $cyr_string, 'cyrillic literal value correctly set';
  lives_ok { $q = REST::Neo4p::Query->new($stmt) } 'create query containing cyrillic literal';
  lives_ok { $q->execute } 'execute query containing cyrillic literal';
  ok $r = $q->fetch, 'obtained match';
  isa_ok $$r[0],'REST::Neo4p::Node';
  is $$r[0]->get_property('utf8'), 'Сохранить', 'cyrillic property value retrieved correctly';

}
#}

  END {
    
    eval { $t && $t->delete_sample; };
  }
