#-*-perl-*-
use Test::More tests => 35;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
my @cleanup;
use_ok('REST::Neo4p');

my $build;
my ($user,$pass);

eval {
  $build = Module::Build->current;
  $user = $build->notes('user');
  $pass = $build->notes('pass');
};

my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474';

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;


SKIP : {
  skip 'no local connection to neo4j', 34 if $not_connected;

  my $n1 = REST::Neo4p::Node->new();
  ok $n1, 'new node' and push @cleanup, $n1;
  my $q = REST::Neo4p::Query->new("MATCH (n) WHERE id(n) = {id} RETURN n");
  $q->{RaiseError} = 1;
  my $row;

  # Make sure node IDs provided by REST::Neo4p will work with Cypher queries
  # as-is. Note that upon parsing the response from the Neo4j server,
  # REST::Neo4p::Entity will return any blessed objects from its internal
  # entity table rather than the server's JSON response if possible, thus
  # objects can be compared for identity.
  # 
  # Example code:
  # 
  #  my $q = REST::Neo4p::Query->new("MATCH (n) WHERE id(n) = {id} RETURN n");
  #  my $id = REST::Neo4p::Node->new()->id();
  #  $q->execute( id => $id );
  #  $q->fetch;

  eval {
    ok $q->execute( id => $n1->id() ), 'execute node query with ->id()';
  };
  is $@, '', 'no error raised';
  is $q->err, undef, 'no HTTP error code';
  is $q->errstr, undef, 'no Neo4j error message';
  lives_ok { $row = $q->fetch } 'fetch';
  isa_ok $row && $row->[0], 'REST::Neo4p::Node', 'got a node';
  ok $row && $row->[0] == $n1, 'got same node';

  eval {
    ok $q->execute( id => $n1->as_simple()->{_node} ), 'execute node query with ->as_simple()';
  };
  is $@, '', 'no error raised';
  is $q->err, undef, 'no HTTP error code';
  is $q->errstr, undef, 'no Neo4j error message';
  lives_ok { $row = $q->fetch } 'fetch';
  isa_ok $row && $row->[0], 'REST::Neo4p::Node', 'got a node';
  ok $row && $row->[0] == $n1, 'got same node';


  # Same for relationships:

  my $n2 = REST::Neo4p::Node->new();
  ok $n2, '2nd node' and push @cleanup, $n2;
  my $r = REST::Neo4p::Relationship->new( $n1 => $n2, 'TEST' );
  ok $r, 'new rel' and push @cleanup, $r;
  $q = REST::Neo4p::Query->new("MATCH ()-[r]->() WHERE id(r) = {id} RETURN r");
  $q->{RaiseError} = 1;

  eval {
    ok $q->execute( id => $r->id() ), 'execute rel query with ->id()';
  };
  is $@, '', 'no error raised';
  is $q->err, undef, 'no HTTP error code';
  is $q->errstr, undef, 'no Neo4j error message';
  lives_ok { $row = $q->fetch } 'fetch';
  isa_ok $row && $row->[0], 'REST::Neo4p::Relationship', 'got a rel';
  ok $row && $row->[0] == $r, 'got same rel';

  eval {
    ok $q->execute( id => $r->as_simple()->{_relationship} ), 'execute rel query with ->as_simple()';
  };
  is $@, '', 'no error raised';
  is $q->err, undef, 'no HTTP error code';
  is $q->errstr, undef, 'no Neo4j error message';
  lives_ok { $row = $q->fetch } 'fetch';
  isa_ok $row && $row->[0], 'REST::Neo4p::Relationship', 'got a rel';
  ok $row && $row->[0] == $r, 'got same rel';

}

CLEANUP : {
  ok $_->remove, 'entity removed' for reverse grep {ref $_ && $_->can('remove')} @cleanup;
}

done_testing;
