#-*-perl-*-
use Test::More;
use Module::Build;
use lib qw|../lib lib|;
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);
my @cleanup;
use_ok('REST::Neo4p');

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


SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;

  # example code from the REST::Neo4p::Relationship synposis:

  my $n1 = REST::Neo4p::Node->new( {name => 'Harry'} );
  my $n2 = REST::Neo4p::Node->new( {name => 'Sally'} );
  ok $n1, 'Harry' and push @cleanup, $n1;
  ok $n2, 'Sally' and push @cleanup, $n2;
  my $r1 = $n1->relate_to($n2, 'met');
  ok $r1, 'met' and push @cleanup, $r1;
  $r1->set_property({ when => 'July' });

  my $r2;
  eval { $r2 = REST::Neo4p::Relationship->new( $n2 => $n1, 'dropped' ); };
  ok $r2, 'dropped' and push @cleanup, $r2;


  # more checks

  my ($r3, $r4, $r5, $r6, $r7);
  eval { $r3 = REST::Neo4p::Relationship->new( $n1 => $r1, 'fails' ); };
  isa_ok $@, 'REST::Neo4p::LocalException', '(node)-->[relationship]';
  eval { $r4 = REST::Neo4p::Relationship->new( $r1 => $n1, 'fails' ); };
  isa_ok $@, 'REST::Neo4p::LocalException', '[relationship]-->(node)';
  eval { $r5 = REST::Neo4p::Relationship->new( $n1 => undef, 'fails' ); };
  isa_ok $@, 'REST::Neo4p::LocalException', '(node)-->null';
  eval { $r6 = REST::Neo4p::Relationship->new( undef => $n1, 'fails' ); };
  isa_ok $@, 'REST::Neo4p::LocalException', 'null-->(node)';
  eval { $r7 = REST::Neo4p::Relationship->new( $n1 => $n1, 'selfref' ); };
  ok $r7, 'selfref';
  push @cleanup, ($r3, $r4, $r5, $r6, $r7);


  1;

}


END {
  CLEANUP : {
    ok $_->remove, 'entity removed' for reverse grep {ref $_ && $_->can('remove')} @cleanup;
  }
  done_testing;
}
