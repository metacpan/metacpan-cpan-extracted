use Test::More;
use Module::Build;
use Try::Tiny;
use blib;
use Cwd;
use URI::bolt;
use Neo4j::Bolt;
use strict;

my $build;
try {
  $build = Module::Build->current();
} catch {
  my $d = getcwd;
  chdir '..';
  $build = Module::Build->current();
  chdir $d;
};

unless (defined $build) {
  plan skip_all => "No build context. Run tests with ./Build test.";
}

unless (defined $build->notes('db_url')) {
  plan skip_all => "Local db tests not requested.";
}

my $url = URI->new($build->notes('db_url'));

if ($build->notes('db_user')) {
  $url->userinfo($build->notes('db_user').':'.$build->notes('db_pass'));
}

ok my $cxn = Neo4j::Bolt->connect($url->as_string), "attempt connection";
unless ($cxn->connected) {
  diag $cxn->errmsg;
}

SKIP: {
  skip "Couldn't connect to server", 1 unless $cxn->connected;
  ok my $stream = $cxn->run_query_(
    "MATCH (a) RETURN labels(a) as lbl, count(a) as ct",
    {},0
   ), 'label count query';
  ok $stream->success, "Succeeded";
  ok !$stream->failure, "Not failure";
  ok my @names = $stream->field_names;
  is_deeply \@names, [qw/lbl ct/], 'col names';
  my $total_nodes = 0;
  while ( my @row = $stream->fetch_next ) {
    unless ($total_nodes) {
      is ref $row[0], 'ARRAY', 'got array for labels()';
    }
    $total_nodes += $row[1];
  }
  
  ok $stream = $cxn->run_query("MATCH (a) RETURN count(a)"), 'total count query';
  is (($stream->fetch_next)[0], $total_nodes, "total nodes check");
  
  ok $stream = $cxn->run_query("MATCH p = (a)-->(b) RETURN p LIMIT 1"), 'path query';
  
  my ($pth) = $stream->fetch_next;
  is ref $pth, 'Neo4j::Bolt::Path', 'got path as Neo4j::Bolt::Path';
  is scalar @$pth, 3, 'path array length';
  is ref $pth->[0], 'Neo4j::Bolt::Node', 'got start node as Neo4j::Bolt::Node';
  is ref $pth->[2], 'Neo4j::Bolt::Node', 'got end node as Neo4j::Bolt::Node';
  is ref $pth->[1], 'Neo4j::Bolt::Relationship', 'relationship is a Neo4j::Bolt::Relationship';
  is $pth->[1]->{start}, $pth->[0]->{id}, 'relationship start correct';
  is $pth->[1]->{end}, $pth->[2]->{id}, 'relationship end correct';
  
  ok $stream = $cxn->run_query("MATCH p = (a)<--(b) RETURN p LIMIT 1"), 'path query 2';
  
  ($pth) = $stream->fetch_next;
  is ref $pth, 'Neo4j::Bolt::Path', 'got path 2 as Neo4j::Bolt::Path';
  is scalar @$pth, 3, 'path array length';
  is ref $pth->[0], 'Neo4j::Bolt::Node', 'got start node 2 as Neo4j::Bolt::Node';
  is ref $pth->[2], 'Neo4j::Bolt::Node', 'got end node 2 as Neo4j::Bolt::Node';
  is ref $pth->[1], 'Neo4j::Bolt::Relationship', 'relationship 2 is a Neo4j::Bolt::Relationship';
  is $pth->[1]->{end}, $pth->[0]->{id}, 'relationship 2 end correct';
  is $pth->[1]->{start}, $pth->[2]->{id}, 'relationship 2 start correct';
  
  ok $stream = $cxn->run_query("CALL db.labels()"), 'call db.labels()';
  my @lbl;
  while ( my @row = $stream->fetch_next ) {
    push @lbl, $row[0];
  }
  
  for (@lbl) {
    ok $stream = $cxn->run_query(
      'MATCH (a) WHERE $lbl in labels(a) RETURN count(a)',
      { lbl => $_}), 'query w/parameters';
    my $ct = ($stream->fetch_next)[0];
    cmp_ok( $ct, ">", 0, "label '$_' count positive ($ct)");
  }

  SKIP : {
    skip "Add/delete tests not requested", 1 unless $build->notes('ok_add_delete');
    ok $stream = $cxn->do_query('CREATE (a:Boog:Frelb {prop1: "goob"})'), 'create a node and a property';
    ok $stream->success, 'q succeeds';
#    $stream->fetch_next_;
    is_deeply [@{$stream->update_counts}{('nodes_created','properties_set','labels_added')}], [1,1,2];
    ok $stream = $cxn->do_query( 'MATCH (a:Boog) REMOVE a:Boog'), 'remove a label';
    ok $stream->success, 'q succeeds';
#    $stream->fetch_next;
    is $stream->update_counts->{labels_removed}, 1;
    ok $stream = $cxn->do_query('MATCH (a:Frelb) WHERE a.prop1 = "goob" DELETE a'), 'delete them';
    ok $stream->success, 'q succeeds';    
#    $stream->fetch_next;
    is_deeply [@{$stream->update_counts}{('nodes_created','properties_set','labels_added','nodes_deleted')}], [0,0,0,1];    

  }
  
  like $cxn->server_id, qr(^Neo4j/\d+\.\d+\.\d), 'server ID';
  
}
  
  
done_testing;

