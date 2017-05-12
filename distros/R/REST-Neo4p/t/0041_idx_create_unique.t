#$Id$
use Test::More tests => 24;
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
my $num_live_tests = 23;

use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER, $user, $pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  my @cleanup;
  if ( my $i = REST::Neo4p->get_index_by_name('nidx555','node') ) { $i->remove }
  if ( my $i = REST::Neo4p->get_index_by_name('ridx555','relationship') ) { $i->remove }
  ok my $n1 = REST::Neo4p::Node->new({name => 'A', type => 'purine'}), "create a new node";
  push @cleanup, $n1;
  ok my $nidx = REST::Neo4p::Index->new('node', 'nidx555'), "create a node index";
  ok $nidx->add_entry( $n1, name => 'A' ), 'add created node to index';
  push @cleanup, $nidx;
  ok my $n2 = $nidx->create_unique( name => 'T', { name => 'T', type => 'pyrimidine' } ), 'create unique node with index';
  push @cleanup, $n2;
  ok my $n3 = $nidx->create_unique( name => 'A', { name => 'A', type => 'purine' } ), 'get a node from create_unique, same properties as first node created...';
  is $$n3, $$n1, "..and they are the same node in db";
  push @cleanup, $n3 unless ($$n3 == $$n1);
  ok my ($n4) = $nidx->find_entries(name => 'T'), 'second node was added to index by create_unique';
  is $$n4, $$n2, '..they are the same node';
  $n4 = $nidx->create_unique( name => 'T', { name => 'T', type => 'pyrimidine'}, 'fail');
  ok !$n4, 'create_unique returned nothing with on_not_found == fail';
  push @cleanup, $n4 unless !$n4;
  ok my $ridx = REST::Neo4p::Index->new('relationship', 'ridx555'), "create a relationship index";
  push @cleanup, $ridx;
  ok my $r = $n1->relate_to($n2, 'transversion'), 'create relationship';
  push @cleanup, $r;
  ok $ridx->add_entry($r, name => 'transversion'), 'add relationship to index';
  ok my $r1 = $ridx->create_unique( name => 'transversion', $n1 => $n2, 'transversion'), 'attempt to create same relationship with create_unique';
  is $$r, $$r1, '.. and get the same relationship object returned';
  push @cleanup, $r1 unless $$r == $$r1;
  my $r2;
    ok $r2 = $ridx->create_unique( name => 'transversion_back', $n2 => $n1, 'transversion', { extra => 'screlb' }), 'create_unique relationship with properties';
    is $r2->get_property('extra'), 'screlb', 'property correctly set';
  isnt $$r1, $$r2, 'this is a different, new relationship';
  push @cleanup, $r2;


END {
  CLEANUP : {
    ok ($_->remove, 'entity removed') for reverse @cleanup;
  }
  }
}
