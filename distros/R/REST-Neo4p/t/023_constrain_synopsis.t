#-*-perl-*-
#$Id$#
use Test::More qw(no_plan);
use Test::Exception;
use File::Temp qw(tempfile);
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use REST::Neo4p;
use REST::Neo4p::Constrain qw(:all);

use warnings;
no warnings qw(once);
$SIG{__DIE__} = sub { die $_[0] };
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

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j, live tests not performed', $num_live_tests if $not_connected;
 
 # create some constraints
 
  ok create_constraint (
    tag => 'owner',
    type => 'node_property',
    condition => 'only',
    constraints => {
      name => qr/[a-z]+/i,
      species => 'human'
     }
   ), 'create constraint 1';
  
  ok create_constraint(
    tag => 'pet',
    type => 'node_property',
    condition => 'all',
    constraints => {
      name => qr/[a-z]+/i,
      species => qr/^dog|cat|ferret|mole rat|platypus$/
     }
   ), 'create constraint 2';
  
  ok create_constraint(
    tag => 'owners2pets',
    type => 'relationship',
    rtype => 'OWNS',
    constraints =>  [{ owner => 'pet' }] # note arrayref
   ),'create constraint 3';
  
  ok create_constraint(
    tag => 'allowed_rtypes',
    type => 'relationship_type',
    constraints => [qw( OWNS FEEDS LOVES )]
   ),'create constraint 4';
  
  ok create_constraint(
    tag => 'ignore',
    type => 'relationship',
    rtype => 'IGNORES',
    constraints =>  [{ pet => 'owner' },
		     { owner => 'pet' }] # both directions ok
   ), 'create constraint 5';

  ok create_constraint(
    tag => 'love',
    type => 'relationship',
    rtype => 'LOVES',
    constraints =>  [{ pet => 'owner' },
		     { owner => 'pet' }] # both directions ok
   ), 'create constraint 6';

  ok create_constraint(
    tag => 'OWNS_props',
    type => 'relationship_property',
    rtype => 'OWNS',
    condition => 'all',
    constraints => {
      year_purchased => qr/^20[0-9]{2}$/
    }
   ), 'create constraint 7';

  # constrain by automatic exception-throwing
  
  ok constrain(), 'constrain()';
  
  ok my $fred = REST::Neo4p::Node->new( { name => 'fred', species => 'human' } ), 'fred';
  push @cleanup, $fred if $fred;
  ok my $fluffy = REST::Neo4p::Node->new( { name => 'fluffy', species => 'mole rat' } ), 'fluffy';
  push @cleanup, $fluffy if $fluffy;

  ok my $r1 = $fred->relate_to($fluffy, 'OWNS',{year_purchased => 2010}), 'reln 1 is valid,created';
  push @cleanup, $r1 if $r1;
  my $r2;

  throws_ok { $r2 = $fluffy->relate_to($fred, 'OWNS',{year_purchased => 2010}) } 'REST::Neo4p::ConstraintException', 'constrained';
  push @cleanup, $r2 if $r2;
  my $r3;
  throws_ok { $r3 = $fluffy->relate_to($fred, 'IGNORES') } 'REST::Neo4p::ConstraintException', 'constrained';

 # allow relationship types that are not explictly
 # allowed -- a relationship constraint is still required

 $REST::Neo4p::Constraint::STRICT_RELN_TYPES = 0;

  ok $r3 = $fluffy->relate_to($fred, 'IGNORES'), 'relationship types relaxed, create reln';
  push @cleanup, $r3 if $r3;

  ok relax(), 'relax'; # stop automatic constraints

  # use validation

  ok $r2 = $fluffy->relate_to($fred, 'OWNS',{year_purchased => 2010}),'relaxed, invalid relationship created'; # not valid, but auto-constraint not in force
  push @cleanup, $r2 if $r2;
  ok validate_properties($r2), 'r2 properties are valid';
  ok !validate_relationship($r2), 'r2 is invalid';
  # try a relationship
  ok validate_relationship( $fred => $fluffy, 'LOVES' ), 'fred LOVES fluffy valid';
  # try a relationship type
  ok !validate_relationship( $fred => $fluffy, 'EATS' ), 'relationship type not valid';
 # serialize all constraints
  my ($tmpfh, $tmpf) = tempfile();
  print $tmpfh serialize_constraints();
  close $tmpfh;
  
  # remove current constraints
  my %c = REST::Neo4p::Constraint->get_all_constraints;
  while ( my ($tag, $constraint) = 
	    each %c ) {
    ok $constraint->drop, "constraint dropped";
  }
  
  # restore constraints
  open $tmpfh,$tmpf;
  local $/ = undef;
  my $json = <$tmpfh>;
  ok load_constraints($json), 'load constraints';
  %c = REST::Neo4p::Constraint->get_all_constraints;
  is scalar values %c, 7, 'got back constraints';
  close $tmpfh;
  unlink $tmpf;

  constrain();
  my $r4;
  $REST::Neo4p::Constraint::STRICT_RELN_PROPS = 1;
  throws_ok { $r4 = $fred->relate_to($fluffy, 'OWNS') } 'REST::Neo4p::ConstraintException', 'fred -OWNS-> fluffy with no properties invalid';
  push @cleanup, $r4 if $r4;
  # create a free relationship property constraint
  ok create_constraint(
    tag => 'free_reln_prop',
    type => 'relationship_property',
    rtype => '*',
    condition => 'all',
    constraints => {}
   ), 'create free reln prop constraint';
  ok $r4 = $fred->relate_to($fluffy, 'OWNS'), 'now can create OWNS reln w/o props';
  push @cleanup, $r4 if $r4;

}

END {
  CLEANUP : {
    ok ($_->remove,'entity removed') for reverse @cleanup;
  }
  }
