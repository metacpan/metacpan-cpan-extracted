#-*-perl-*-
#$Id$#
use Test::More;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 'lib';
use lib 't/lib';
use Neo4p::Connect;
use REST::Neo4p;
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
my $num_live_tests = 1;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

use_ok ('REST::Neo4p::Constrain');

ok my $c1 = create_constraint( 
  tag => 'module',
  type => 'node_property',
  condition => 'only',
  constraints => {
    entity => 'module',
    namespace => qr/([a-z0-9_]+)+(::[a-z0-9_])*/i,
    exports => []
   }
 ), 'create module node_property constraint';

isa_ok($c1,'REST::Neo4p::Constraint::NodeProperty');

ok my $c2 = create_constraint( 
  tag => 'method',
  type => 'node_property',
  condition => 'all',
  constraints => {
    entity => 'method',
    name => qr/[a-z0-9_]+/i,
    return => qr/^(scalar|array|hash)(ref)?$/
   }
 ), 'create method node_property constraint';

isa_ok($c2,'REST::Neo4p::Constraint::NodeProperty');

ok my $c3 = create_constraint( 
  tag => 'how_contained',
  type => 'relationship_property',
  rtype => 'contains',
  condition => 'all',
  constraints =>  {
    contained_by => qr/^declaration|import$/
   }
 ), 'create how_contained relationship_property constraint';

isa_ok($c3,'REST::Neo4p::Constraint::RelationshipProperty');

ok my $c4 = create_constraint(
  tag => 'contains',
  type => 'relationship',
  rtype => 'contains',
  constraints => [ {'module' => 'method'} ]
 ), 'create contains relationship constraint';

isa_ok($c4, 'REST::Neo4p::Constraint::Relationship');

ok my $c5 = create_constraint(
  tag => 'allowed_types',
  type => 'relationship_type',
  constraints => [ 'contains' ]
 ), 'create relationship type constraint';

isa_ok($c5, 'REST::Neo4p::Constraint::RelationshipType');

lives_ok { constrain() } 'set up automatic constraints';

SKIP : {
  skip 'no local connection to neo4j, live tests not performed', $num_live_tests if $not_connected;
  
  ok constrain(), 'turn on auto constraints';

  ok my $n1 = REST::Neo4p::Node->new(
    { entity => 'method',
      name => 'is_acme',
      return => 'scalar',
      notes => 'should work' }
   ), 'create a node within constraints';
  push @cleanup, $n1 if $n1;
  my $n2;
  throws_ok { $n2 = REST::Neo4p::Node->new(
    { name => 'is_not_acme',
      scalar => 'hashref' }) } 'REST::Neo4p::ConstraintException';
  like $@, qr/Specified properties violate/, 'correct message';
  
  ok my $n3 = REST::Neo4p::Node->new(
    { entity => 'module',
      namespace => 'Acme::Awesome' }
   ), 'create another node within constraints';
  push @cleanup, $n2 if $n2;
  push @cleanup, $n3 if $n3;
  
  ok $n3->set_property( {exports => 'is_awesome'} ), 'set node property within constraints';
  throws_ok { $n3->set_property( {bad => 'property'} ) } 'REST::Neo4p::ConstraintException';
  like $@, qr/Specified properties would violate/, 'correct message';
  
  ok my $r1 = $n3->relate_to($n1, 'contains', { contained_by => 'declaration' }), 'create relationship within constraints';
  
  push @cleanup, $r1 if $r1;
  my $r2;
  ok $REST::Neo4p::Constraint::STRICT_RELN_PROPS=1, 'set strict relationship properties';
  throws_ok { $r2 = $n3->relate_to($n1, 'contains') } 'REST::Neo4p::ConstraintException';
  like $@, qr/Relationship or its properties violate/, 'correct message (no properties does not match fact that contained_by is a required property';
  ok !($REST::Neo4p::Constraint::STRICT_RELN_PROPS=0), 'clear strict relationship properties';
  # create  constraint that is looser and add it will lower priority
  ok my $c6 = create_constraint( 
    tag => 'how_contained_loose',
    type => 'relationship_property',
    rtype => 'contains',
    condition => 'all',
    constraints => {
	contained_by => [qr/^declaration|import$/]
       }
   ), 'create how_contained_loose relationship_property constraint';
  $c6->set_priority(-1);
  ok $r2 = $n3->relate_to($n1, 'contains'), 'now relationship w/o properties can be created';
  ok $r2->set_property( { contained_by => 'import' } ), "set relationship properties that meet constraints for the relationship type";
  is REST::Neo4p::Constraint::validate_properties($r2)->tag, 'how_contained', "now relationship matches the first (and higher priority) relationship constraint";
  ok $r2->remove, 'relationship removed';

  my $r3;
  throws_ok { $r3 = $n1->relate_to($n3, 'contains') } 'REST::Neo4p::ConstraintException';
  like $@, qr/Relationship or its properties violate active/, 'correct message (type allowed, bad spec)';

  throws_ok { $r3 = $n3->relate_to($n1, 'nonexistent') } 'REST::Neo4p::ConstraintException';
  like $@, qr/Relationship type 'nonexistent' is not allowed/, 'correct message (type not registered)';

  ok relax(), 'relax auto constraints';

  ok $n2 = REST::Neo4p::Node->new(
    { name => 'is_not_acme',
      scalar => 'hashref' }
   ), 'bad node now permitted';
  push @cleanup, $n2 if $n2;
  ok $n3->set_property( {bad => 'property'} ), 'bad property set now permitted';

  ok $r3 = $n1->relate_to($n3, 'contains'), 'bad relationship now permitted';
  push @cleanup, $r3 if $r3;
  ok $r3 = $n3->relate_to($n1, 'nonexistent'), 'bad relationship type now permitted';
  push @cleanup, $r3 if $r3;

}

END {
  CLEANUP : {
    ok ($_->remove,'entity removed') for reverse @cleanup;
  }
  done_testing;
  }
