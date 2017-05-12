#-*-perl-*-
#$Id$
use Test::More tests => 25;
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
my $num_live_tests = 24;

use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  $REST::Neo4p::CREATE_AUTO_ACCESSORS = 1;
  ok my $n1 = REST::Neo4p::Node->new(), 'node 1';
  ok my $n2 = REST::Neo4p::Node->new(), 'node 2';
  ok my $r12 = $n1->relate_to($n2, "bubba"), 'relationship 1->2';
  push @cleanup, ($n1,$n2, $r12);

  ok $n1->set_property({ dressing => 'mayo' }), 'node prop set with set_property';
  lives_and { is $n1->dressing, 'mayo' } 'getter works';
  lives_and { ok $n1->set_dressing('italian') } 'setter called';
  lives_and { is $n1->dressing, 'italian' } 'setter works';
  ok $r12->set_property({ method => 'drizzled', amount => 'lots' }), 'reln prop set with set_property';
  lives_and { is $r12->method, 'drizzled' } 'getter works (1)';
  lives_and { is $r12->amount, 'lots' } 'getter works (2)';
  lives_and { ok $r12->set_amount('little bit') } 'setter called';
  lives_and { is $r12->amount, 'little bit' } 'setter works';

  ok my $n3 = REST::Neo4p::Node->new( {red => 1, yellow => 2, blue => 3} ), 'node3, properties created in constructor';
  push @cleanup, $n3 if $n3;
  lives_and { is $n3->red, 1 } 'red getter';
  lives_and { is $n3->yellow, 2 } 'yellow getter';
  lives_and { is $n3->blue, 3 } 'blue getter';
  lives_and { ok $n3->set_blue(5) } 'blue setter called';
  lives_and { is $n3->blue, 5 } 'blue setter works';
  my $idx;
  lives_ok {$idx = REST::Neo4p::Index->new('relationship','heydude')} 'index should be created np';
  push @cleanup, $idx if $idx;

}
END {
  CLEANUP : {
      ok ($_->remove, 'entity removed') for reverse @cleanup;
  }
}
