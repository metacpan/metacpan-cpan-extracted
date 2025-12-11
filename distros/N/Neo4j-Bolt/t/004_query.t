use v5.12;
use warnings;
use Test::More;
use blib;
use Cwd;
use URI::bolt;
use Neo4j::Bolt;
use File::Spec;


my $neo_info;
my $nif = File::Spec->catfile('t','neo_info');
if (-e $nif ) {
    local $/;
    open my $fh, "<", $nif or die $!;
    my $val = <$fh>;
    $val =~ s/^.*?(=.*)$/\$neo_info $1/s;
    eval $val;
}


unless (defined $neo_info) {
  plan skip_all => "DB tests not requested";
}

my $url = URI->new("bolt://".$neo_info->{host});

if ($neo_info->{user}) {
  $url->userinfo($neo_info->{user}.':'.$neo_info->{pass});
}

ok my $cxn = Neo4j::Bolt->connect($url->as_string), "attempt connection";
ok $cxn->connected, "server connection successful for requested DB tests";
unless ($cxn->connected) {
  diag $cxn->errmsg;
}

if ($cxn->connected) {
  like $cxn->protocol_version, qr/^[0-9]+\.[0-9]+$/, "protocol version returned";
  diag "Bolt version " . $cxn->protocol_version;  # debug aid
  ok my $stream = $cxn->run_query_(
    "MATCH (a) RETURN labels(a) as lbl, count(a) as ct",
    {},0,$Neo4j::Bolt::DEFAULT_DB
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
  if (defined $pth) {
    is ref $pth, 'Neo4j::Bolt::Path', 'got path as Neo4j::Bolt::Path';
    is scalar @$pth, 3, 'path array length';
    is ref $pth->[0], 'Neo4j::Bolt::Node', 'got start node as Neo4j::Bolt::Node';
    ok defined $pth->[0]->{element_id}, 'node element_id defined';
    diag $pth->[0]->{element_id};
    is ref $pth->[2], 'Neo4j::Bolt::Node', 'got end node as Neo4j::Bolt::Node';
    is ref $pth->[1], 'Neo4j::Bolt::Relationship', 'relationship is a Neo4j::Bolt::Relationship';
    is $pth->[1]->{start}, $pth->[0]->{id}, 'relationship start correct';
    is $pth->[1]->{end}, $pth->[2]->{id}, 'relationship end correct';
    ok defined $pth->[1]->{element_id}, 'relationship element id defined';
    diag $pth->[1]->{element_id};    
    ok defined $pth->[1]->{start_element_id}, 'relationship start element id defined';
    diag $pth->[1]->{start_element_id};    
    ok defined $pth->[1]->{end_element_id}, 'relationship end element id defined';
    diag $pth->[1]->{end_element_id};        
  }
  ok $stream = $cxn->run_query("MATCH p = (a)<--(b) RETURN p LIMIT 1"), 'path query 2';
  
  ($pth) = $stream->fetch_next;
  if (defined $pth) {  
    is ref $pth, 'Neo4j::Bolt::Path', 'got path 2 as Neo4j::Bolt::Path';
    is scalar @$pth, 3, 'path array length';
    is ref $pth->[0], 'Neo4j::Bolt::Node', 'got start node 2 as Neo4j::Bolt::Node';
    is ref $pth->[2], 'Neo4j::Bolt::Node', 'got end node 2 as Neo4j::Bolt::Node';
    is ref $pth->[1], 'Neo4j::Bolt::Relationship', 'relationship 2 is a Neo4j::Bolt::Relationship';
    is $pth->[1]->{end}, $pth->[0]->{id}, 'relationship 2 end correct';
    is $pth->[1]->{start}, $pth->[2]->{id}, 'relationship 2 start correct';
  }
  ok $stream = $cxn->run_query("CALL db.schlabels()"), 'call db.labels()';
  my $fd = $stream->get_failure_details;
  ok $fd, "got fd";
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
    skip "Add/delete tests not requested", 9 unless $neo_info->{tests};
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

