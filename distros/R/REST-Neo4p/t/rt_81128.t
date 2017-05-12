#-*-perl-*-
#$Id$
use Test::More tests => 14;
use Test::Exception;
use Module::Build;
use lib '../lib';
use lib 't/lib';
use Neo4p::Connect;
use strict;
use warnings;
no warnings qw(once);
# $SIG{__DIE__} = sub { print $_[0] };
my $build;
my @cleanup;
my ($user,$pass);
eval {
    $build = Module::Build->current;
    $user = $build->notes('user');
    $pass = $build->notes('pass');
};
my $TEST_SERVER = $build ? $build->notes('test_server') : 'http://127.0.0.1:7474
';
my $num_live_tests = 13;

use_ok('REST::Neo4p');

my $not_connected = connect($TEST_SERVER,$user,$pass);
diag "Test server unavailable (".$not_connected->message.") : tests skipped" if $not_connected;

SKIP : {
  skip 'no local connection to neo4j', $num_live_tests if $not_connected;
  
  ok my $n1 = REST::Neo4p::Node->new( {name => 'ricky'} ), 'new node 1';
  push @cleanup, $n1 if $n1;
  ok my $n2 = REST::Neo4p::Node->new( {name => 'lucy'} ), 'new node 2';
  push @cleanup, $n2 if $n2;
  ok my $q = REST::Neo4p::Query->new(<<Q), 'create query that returns an array';
start n = node($$n1,$$n2) return collect(n.name)
Q
  $q->{RaiseError} = 1;
  ok $q->execute, 'execute query';
  my $row;
  lives_ok { $row = $q->fetch } 'fetch lives';
  is_deeply $row, [qw(ricky lucy)], 'query response correct';
  ok $q = REST::Neo4p::Query->new(<<Q2), 'create query that returns an array of objects';
start n = node($$n1,$$n2) return collect(n)
Q2
  $q->{RaiseError} = 1;
  $q->execute;
  lives_ok { $row = $q->fetch } 'fetch lives';
  isa_ok($_,'REST::Neo4p::Node') for @$row;
  is_deeply [map {$_->get_property('name')} @$row], [qw(ricky lucy)], 'response correct';
}

END {
  CLEANUP : {
    ok $_->remove, 'entity removed' for reverse @cleanup;
  }
  }
