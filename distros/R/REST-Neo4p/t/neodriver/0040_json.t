use v5.10;
use Test::More;
use Test::Exception;
use Test::Warn;
use Set::Scalar;
use File::Spec;
use lib qw|. ../lib ../../lib/|;
use REST::Neo4p::Agent;
use strict;
use warnings;

my $dir = (-d 't' ? 'neodriver' : '.');

unless (eval "require NeoCon; 1") {
  diag "Issue with NeoCon: ".$@;
  diag "Need docker for these tests";
  pass;
  done_testing;
}

my $docker = NeoCon->new(
  tag => $ENV{NEOCON_TAG} // 'neo4j:3.4',
  delay => 5,
  reuse => 0,
  load => File::Spec->catfile($dir,'samples/test.cypher'),
 );

if (!$docker->start) {
  diag "Docker container startup error, skipping";
  diag $docker->error;
  pass;
  done_testing;
}

my ($agent, $result, $got, $exp, $node, $reln);

ok $agent = REST::Neo4p::Agent->new( agent_module => 'Neo4j::Driver' );
ok $agent->connect('http://localhost:'.$docker->ports->{7474});

# get ids of nodes and relationships
my %ids;
$agent->run_in_session('match (n) return n.name as name, id(n) as id');
while (my $rec = $agent->last_result->fetch) {
  $ids{$rec->get('name')} = 0+$rec->get('id');
}

my $msg;

$msg = $agent->get_propertykeys;
$got = Set::Scalar->new(@$msg);
$exp = Set::Scalar->new('state','date','name','rem');
ok $got >= $exp;


$msg = $agent->get_node($ids{'you'});
is_deeply $msg, { metadata => {id => $ids{you}, labels => ['person'] }, self => "node/$ids{you}", data => { name => 'you'} };

$msg = $agent->get_node($ids{'she'},'labels');
is_deeply $msg, ['person'];

$msg = $agent->get_node($ids{'he'}, 'properties');
is_deeply $msg, { name => 'he' };

$msg = $agent->get_node($ids{'it'}, 'properties', 'name');
is $msg, 'it';

$msg = $agent->get_node($ids{'I'}, 'relationships', 'all');
is scalar @$msg, 4;

$msg = $agent->get_node($ids{'I'}, 'relationships', 'out');
is scalar @$msg, 2;

$msg = $agent->get_node($ids{'I'}, 'relationships', 'in');
is scalar @$msg, 2;

$msg = $agent->get_node($ids{'I'}, 'relationships', 'all', 'best');
is scalar @$msg, 2;

$msg = $agent->get_node($ids{'I'}, 'relationships', 'in', 'good');
is scalar @$msg, 1;

$msg = $agent->get_node($ids{'noone'},'properties','rem');
is $msg, 'bye';

$msg = $agent->get_node($ids{'noone'}, 'labels'); 
is_deeply $msg, ['person'];

$msg = $agent->delete_node($ids{'noone'}, 'properties', 'rem');
ok !$msg;		  

$msg = $agent->delete_node($ids{'noone'}, 'labels', 'person');
ok !$msg;

$msg = $agent->delete_node($ids{'noone'});
ok !$msg;

$msg = $agent->get_relationship('types');
is_deeply [sort @$msg], [sort qw/bosom best umm fairweather good/];

my @rids;
$agent->run_in_session('match (a)-[r]->(b) where type(r)=$type and a.name = "I" and b.name = "you" return id(r) as id',{type=>'best'});
while (my $rec = $agent->last_result->fetch) {
  push @rids, 0+$rec->get('id');
}

$msg = $agent->get_relationship($rids[0]);
is_deeply $msg, { metadata => {id => $rids[0], type => 'best'},
		  self => "relationship/$rids[0]",
		  data => { date => '2/2/02', state => 'ME' },
		  start => "node/$ids{I}",
		  end => "node/$ids{you}",
		  type => 'best' };

$msg = $agent->get_relationship($rids[0],'properties');
is_deeply $msg, { date => '2/2/02', state => 'ME' };

$msg = $agent->get_relationship($rids[0],'properties','state');
is $msg, 'ME';

$msg = $agent->delete_relationship($rids[0],'properties','state');
ok !$msg;

$msg = $agent->get_relationship($rids[0],'properties');
is_deeply $msg, { date => '2/2/02' };

$msg = $agent->delete_relationship($rids[0]);
ok !$msg;

# post node, relationship

$msg = $agent->post_node();

$msg = $agent->post_node([],{ foo => 'bar' });

$msg = $agent->post_node([$msg->{metadata}{id}, 'labels'],['alien']);

# $msg = $agent->post_node([$n->id, 'relationships'], { to => 'node/'.$m->id, type => 'squirts', data => {narf => 'crelb'} });

#$msg = $agent->put_relationship([ $r->id, 'properties'], {bar => 'quux'});
#ok !$msg;

#$msg = $agent->get_relationship($r->id, 'properties');
#is_deeply $msg,  {narf => 'crelb', bar => 'quux'};

# get by label

$msg = $agent->get_labels();
is_deeply [sort @$msg], ['alien','person'];


$msg = $agent->get_label('person');
is scalar @$msg, 5;

$msg = $agent->get_label('person', { value => 10 });
is scalar @$msg, 1;

# node, relationship explicit indexes

$msg = $agent->post_node_index([], {name => 'people'});
is_deeply $msg, { template => 'index/node/people/{key}/{value}' };

$msg = $agent->post_node_index(['people'], {key => 'they', value => 'I', uri => "node/$ids{I}"});
is_deeply $msg, { metadata => { id => $ids{I} }, self => "node/$ids{I}",
		  data => {name => 'I'},
		  indexed => "index/node/people/they/I/$ids{I}" };

$agent->post_node_index(['people'], {key => 'they', value => 'he', uri => "node/$ids{he}"});
$agent->post_node_index(['people'], {key => 'they', value => 'it', uri => "node/$ids{it}"});


$msg = $agent->post_node_index(['people'], { key => 'they', value => 'alter', properties => {name => 'alter'} },
			{ uniqueness => 'get_or_create' });
is_deeply $msg->{data}, {name => 'alter'};

$msg = $agent->post_relationship_index([],{name => 'friendships'});
is_deeply $msg, { template => 'index/relationship/friendships/{key}/{value}' };

# $agent->post_relationship_index(['friendships'],{key => 'squirty', value => 1, uri => "relationship/".$r->id});
# ok $agent->last_result->fetch->get(0);

#$agent->get_relationship_index('friendships','squirty',1);
#is $agent->last_result->fetch->get(0)->type, 'squirts';

$msg = $agent->post_relationship_index(['friendships'], {key => 'squirty', value => 2, start => "node/".$ids{'she'},
						    end => "node/".$ids{'he'}, type => 'squirts', properties => { mucho => "bueno" }},
				{uniqueness => 'get_or_create'});

my $rid = $msg->{metadata}{id};
my %part;
@part{qw/metadata self data type indexed/} = @{$msg}{qw/metadata self data type indexed/};
is_deeply \%part, { metadata => { id => $rid }, self => "relationship/$rid",
		  data => { mucho => 'bueno' }, type => 'squirts',
		    indexed => "index/relationship/friendships/squirty/2/$rid" };
ok $msg->{start_id};
ok $msg->{end_id};


# schema constraints

$msg = $agent->post_schema_constraint(['person','uniqueness'], {property_keys => ['name']});
is_deeply $msg, { label => 'person', type => 'UNIQUENESS', property_keys => ['name'] };

$msg = $agent->get_schema_constraint();
ok grep { $_->{type} eq 'UNIQUENESS' } @$msg;


done_testing;


