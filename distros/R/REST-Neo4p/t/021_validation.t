#-*-perl-*-
#$Id$#
use Test::More;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use REST::Neo4p;
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
my $num_live_tests = 47;

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

use_ok ('REST::Neo4p::Constraint');
use_ok ('REST::Neo4p::Constraint::Property');
use_ok ('REST::Neo4p::Constraint::Relationship');
use_ok ('REST::Neo4p::Constraint::RelationshipType');

# test validation - property constraints

my $c1 = REST::Neo4p::Constraint::NodeProperty->new(
  'c1',
  {
    name => '',
    rank => [],
    serial_number => qr/^[0-9]+$/,
    army_of => 'one',
    options => [qr/[abc]/]
   }
 );

my @propset;
# 1
# valid for all, only
# invalid for none
push @propset, 
  [
    {
      name => 'Jones',
      rank => 'Corporal',
      serial_number => '147800934',
      army_of => 'one'
     },[1, 1, 0]
    ];
# 2
# valid for all, only
# invalid for none
push @propset, [
  {
    name => 'Jones',
    serial_number => '147800934',
    army_of => 'one'
   }, [1,1,0] 
];

# 3
# valid for all
# invalid for only, none
push @propset, [
  {
    name => 'Jones',
    serial_number => '147800934',
    army_of => 'one',
    extra => 'value'
   }, [1,0,0]
];

# 4
# invalid for all, only
# invalid for none
push @propset, [
  {
    name => 'Jones',
    rank => 'Corporal',
    serial_number => 'THX1138',
    army_of => 'one'
   }, [0,0,0]
];

# 5
# invalid for all, only
# valid for none
push @propset, [
  {
    different => 'altogether'
  }, [0,0,1]
];

# 6
# valid for all, only
# invalid for none
push @propset, [
   {
     name => 'Jones',
     rank => 'Corporal',
     serial_number => '147800934',
     army_of => 'one',
     options => 'a'
    }, [1,1,0]
];

# 7
# invalid for all, only, none
push @propset, [
  {
    name => 'Jones',
    rank => 'Corporal',
    serial_number => '147800934',
    options => 'e'
   }, [0,0,0]
];

my $ctr=0;
foreach (@propset) {
  my $propset = $_->[0];
  my $expected = $_->[1];
  $ctr++;
  $c1->set_condition('all');
  is $c1->validate($propset), $expected->[0], "propset $ctr : all";
  $c1->set_condition('only');
  is $c1->validate($propset), $expected->[1], "propset $ctr : only";
  $c1->set_condition('none');
  is $c1->validate($propset), $expected->[2], "propset $ctr : none";
}

# test validation : relationship constraints

REST::Neo4p::Constraint::NodeProperty->new
(
 'module',
 {
  _condition => 'all',
  entity => 'module',
  namespace => qr/([a-z0-9_]+)+(::[a-z0-9_])*/i,
  exports => []
 }
);

REST::Neo4p::Constraint::NodeProperty->new
(
 'variable',
 {
  _condition => 'all',
  entity => 'variable',
  name => qr/[a-z0-9_]+/i,
  sigil => qr/[\$\@\%]/,
 }
);

REST::Neo4p::Constraint::NodeProperty->new
(
 'method',
 {
  _condition => 'all',
  entity => 'method',
  name => qr/[a-z0-9_]+/i,
  return => qr/^(scalar|array|hash)(ref)?$/
 }
);

REST::Neo4p::Constraint::NodeProperty->new
(
 'parameter',
 {
  _condition => 'all',
  entity => 'parameter',
  type => qr/^(scalar|array|hash)(ref)?$/
 }
);

REST::Neo4p::Constraint::RelationshipProperty->new
(
 'position',
 {
  _condition => 'only',
  position => qr/[0-9]+/
 }
);

my $allowed_has_relns = REST::Neo4p::Constraint::Relationship->new
(
  'allowed_has_relns',
  {
    _condition => 'only',
    _relationship_type => 'has',
    _descriptors => [ {'module' => 'method'},
	     {'method' => 'parameter'} ]
  }
);

my $allowed_contains_relns = REST::Neo4p::Constraint::Relationship->new
(
 'allowed_contains_relns',
 {
     _condition => 'only',
     _relationship_type => 'contains',
     _descriptors  => [ {'module' => 'method'},
		       {'module' => 'variable'},
		       {'method' => 'variable'} ]
 }
);

ok my $allowed_reln_types = REST::Neo4p::Constraint::RelationshipType->new( 
  'allowed_reln_types',
  { _condition => 'only', 
    _type_list => [qw(contains has)] }
), 'relationship type constraint';


my $module = {
  entity => 'module',
  namespace => 'Acme::BeesKnees'
};

my $teh_shizznit = {
  entity => 'method',
  name => 'is_teh_shizznit',
  return => 'scalar'
    
};

my $bizzity_bomb = {
  entity => 'method',
  name => 'is_the_bizzity_bomb',
  return => 'scalar'
};

my $variable = {
  entity => 'variable',
  name => 'self',
  sigil => '$'
};

my $parameter = {
  entity => 'parameter',
  name => 'extra',
  type => 'arrayref'
};

my $position = {
  position => 0
};

isa_ok( REST::Neo4p::Constraint->drop_constraint('c1'), 'REST::Neo4p::Constraint');
ok my $position_constraint = REST::Neo4p::Constraint->get_constraint('position');
is_deeply $position_constraint->rtype, [], 'position constraint rtype is wildcard';

ok $position_constraint->validate($position), 'relationship property constraint satisfied by \'position\'';
$DB::single=1;
is $allowed_has_relns->validate( $module => $teh_shizznit, 'has' ), 1, 'module can have method (1)';
is $allowed_has_relns->validate( $module => $bizzity_bomb, 'has'), 1,  'module can have method (2)';
is $allowed_contains_relns->validate( $module => $teh_shizznit, 'contains' ), 1, 'module can also contain a method';
is $allowed_contains_relns->validate( $teh_shizznit => $variable, 'contains'), 1, 'method can contain a variable';
is $allowed_contains_relns->validate( $bizzity_bomb => $parameter, 'contains'),0, 'method cannot contain a parameter';
is $allowed_has_relns->validate( $bizzity_bomb => $variable, 'has'), 0, 'method cannot "have" a variable';
is $allowed_has_relns->validate( $variable => $bizzity_bomb, 'has'), 0, 'variable cannot contain a method';

# test validation : relationship type constraints

is $allowed_reln_types->validate('contains'), 1, 'contains is a valid type';
is $allowed_reln_types->validate('has'), 1, 'has is a valid type';
is $allowed_reln_types->validate('blarfs'), 0, 'blarfs is not a valid type';

#class methods

ok my $c = REST::Neo4p::Constraint::validate_properties($variable), 'validate_properties';
isa_ok($c,'REST::Neo4p::Constraint::NodeProperty');
is $c->tag, 'variable', 'correct constraint tag';
ok !REST::Neo4p::Constraint::validate_properties({glarb => 'foo'}), 'unmatched property hash returns false';

ok $c = REST::Neo4p::Constraint::validate_relationship($module => $bizzity_bomb,'contains');
isa_ok($c, 'REST::Neo4p::Constraint::Relationship');
is $c->tag, 'allowed_contains_relns', 'correct constraint tag';
ok !REST::Neo4p::Constraint::validate_relationship($bizzity_bomb => $module, 'contains'), 'unallowed relationship returns false';

ok $c = REST::Neo4p::Constraint::validate_relationship_type('has');
isa_ok($c, 'REST::Neo4p::Constraint::RelationshipType');
is $c->tag, 'allowed_reln_types', 'correct constraint tag';
ok !REST::Neo4p::Constraint::validate_relationship_type('freb'), 'unallowed rtype returns false';

SKIP : {
  skip 'no local connection to neo4j, live tests not performed', $num_live_tests if $not_connected;
  my @nodeset;
  foreach (@propset) {
      push @cleanup, my $n = REST::Neo4p::Node->new($_->[0]);
      push @nodeset, [$n,$_->[1]];
  }
  my $ctr=0;
  foreach (@nodeset) {
      my $nodeset = $_->[0];
      my $expected = $_->[1];
      $ctr++;
      $c1->set_condition('all');
      is $c1->validate($nodeset), $expected->[0], "nodeset $ctr : all";
      $c1->set_condition('only');
      is $c1->validate($nodeset), $expected->[1], "nodeset $ctr : only";
      $c1->set_condition('none');
      is $c1->validate($nodeset), $expected->[2], "nodeset $ctr : none";
  }
  push @cleanup, my $bad_node_no_biscuit = REST::Neo4p::Node->new( { bad => 'node' } );
  push @cleanup, my $module_node = REST::Neo4p::Node->new($module);
  push @cleanup, my $teh_shizznit_node = REST::Neo4p::Node->new($teh_shizznit);
  push @cleanup, my $bizzity_bomb_node = REST::Neo4p::Node->new($bizzity_bomb);
  push @cleanup, my $variable_node = REST::Neo4p::Node->new($variable);
  push @cleanup, my $parameter_node = REST::Neo4p::Node->new($parameter);

  push @cleanup, my $r1 = $module_node->relate_to($teh_shizznit_node, 'has');
  push @cleanup, my $r2 = $module_node->relate_to($bizzity_bomb_node, 'has');
  push @cleanup, my $r3 = $module_node->relate_to($teh_shizznit_node, 'contains');
  push @cleanup, my $r4 = $teh_shizznit_node->relate_to($variable_node,'contains');
  push @cleanup, my $r5 = $bizzity_bomb_node->relate_to($parameter_node,'contains');
  push @cleanup, my $r6 = $bizzity_bomb_node->relate_to($variable_node,'has');
  push @cleanup, my $r7 = $variable_node->relate_to($bizzity_bomb_node,'has');
  push @cleanup, my $r8 = $variable_node->relate_to($bizzity_bomb_node,'frelb');
  push @cleanup, my $r9 = $bizzity_bomb_node->relate_to($parameter_node,'has',{ position => 0});

  is $allowed_has_relns->validate( $r1 ), 1, 'module can have method (1)';
  is $allowed_has_relns->validate( $r2 ), 1,  'module can have method (2)';
  is $allowed_contains_relns->validate( $r3 ), 1, 'module can also contain a method';
  is $allowed_contains_relns->validate( $r4), 1, 'method can contain a variable';
  is $allowed_contains_relns->validate( $r5 ),0, 'method cannot contain a parameter';
  is $allowed_has_relns->validate( $r6 ), 0, 'method cannot "have" a variable';
  is $allowed_has_relns->validate( $r7 ), 0, 'variable cannot contain a method';
  is $allowed_reln_types->validate($r7), 1, 'relationship r7 type is allowed';
  is $allowed_reln_types->validate($r8), 0, 'relationship r8 type is not allowed';

#exported methods

  ok my $c = REST::Neo4p::Constraint::validate_properties($variable_node), 'validate_properties';
  isa_ok($c,'REST::Neo4p::Constraint::NodeProperty');
  is $c->tag, 'variable', 'correct constraint tag';
  ok !REST::Neo4p::Constraint::validate_properties($bad_node_no_biscuit), 
    'unclassified node returns false';


  ok $c = REST::Neo4p::Constraint::validate_properties($r9), 'validate relationship properties';
  isa_ok($c, 'REST::Neo4p::Constraint::RelationshipProperty');
  is $c->tag, 'position', 'correct constraint tag';
  ok !REST::Neo4p::Constraint::validate_properties($r8), 'unclassified relationship properties return false';

  ok $c = REST::Neo4p::Constraint::validate_relationship($r3);
  isa_ok($c, 'REST::Neo4p::Constraint::Relationship');
  is $c->tag, 'allowed_contains_relns', 'correct constraint tag';
  ok !REST::Neo4p::Constraint::validate_relationship($r8), 'unallowed relationship returns false';

}

END {
  CLEANUP : {
    for (reverse @cleanup) {
      ok $_->remove, 'entity removed from db';
    }
    done_testing;
  }
  }
