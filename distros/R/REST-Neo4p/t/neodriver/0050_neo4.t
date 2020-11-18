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
  tag => 'neo4j:4.0',
  delay => 5,
  load => File::Spec->catfile($dir,'samples/test.4.cypher'),
  reuse => 0
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

$agent->get_propertykeys;
$got = Set::Scalar->new();
$exp = Set::Scalar->new('state','date','name','rem');
while (my $rec = $agent->last_result->fetch) {
  $got->insert( $rec->get(0) );
}

ok $got >= $exp;

$agent->get_node($ids{'you'});
$node = $agent->last_result->fetch->get(0);
is $node->id, $ids{you};
is $node->get('name'), 'you';

$agent->get_node($ids{'she'},'labels');
my $lbls = $agent->last_result->fetch->get(0);
is_deeply $lbls, ['person'];

$agent->get_node($ids{'he'}, 'properties');
my $props = $agent->last_result->fetch->get(0);
is_deeply $props, { name => 'he' };

$agent->get_node($ids{'it'}, 'properties', 'name');
is $agent->last_result->fetch->get(0), 'it';

$agent->get_node($ids{'I'}, 'relationships', 'all');
my @rec;
while (my $rec = $agent->last_result->fetch) {
  push @rec, $rec->get(0);
}
is scalar @rec, 4;

$agent->get_node($ids{'I'}, 'relationships', 'out');
@rec = ();
while (my $rec = $agent->last_result->fetch) {
  push @rec, $rec->get(0);
}
is scalar @rec, 2;

$agent->get_node($ids{'I'}, 'relationships', 'in');
@rec = ();
while (my $rec = $agent->last_result->fetch) {
  push @rec, $rec->get(0);
}
is scalar @rec, 2;

$agent->get_node($ids{'I'}, 'relationships', 'all', 'best');
@rec = ();
while (my $rec = $agent->last_result->fetch) {
  push @rec, $rec->get(0);
}
is scalar @rec, 2;

$agent->get_node($ids{'I'}, 'relationships', 'in', 'good');
@rec = ();
while (my $rec = $agent->last_result->fetch) {
  push @rec, $rec->get(0);
}
is scalar @rec, 1;

$agent->get_node($ids{'noone'},'properties','rem');
is $agent->last_result->fetch->get(0), 'bye';

$agent->get_node($ids{'noone'}, 'labels'); # why does this query return no results (using HTTP endpoint), when executed after delete_node/properties/rem below?
is $agent->last_result->fetch->get(0)->[0], 'person';

$agent->delete_node($ids{'noone'}, 'properties', 'rem');
$agent->get_node($ids{'noone'},'properties','rem');
ok !$agent->last_result->fetch->get(0);

$agent->delete_node($ids{'noone'}, 'labels', 'person');
$agent->get_node($ids{'noone'}, 'labels');
ok !@{$agent->last_result->fetch->get(0)};

$agent->get_node($ids{'noone'});
ok $agent->last_result->fetch;
$agent->delete_node($ids{'noone'});
$agent->get_node($ids{'noone'});
ok !$agent->last_result->fetch;

$agent->get_relationship('types');
is_deeply [ sort map { $_->get(0) } $agent->last_result->list ], [sort qw/bosom best umm fairweather good/];

my @rids;
$agent->run_in_session('match ()-[r]->() where type(r)=$type return id(r) as id',{type=>'best'});
while (my $rec = $agent->last_result->fetch) {
  push @rids, 0+$rec->get('id');
}

$agent->get_relationship($rids[0]);
my $r = $agent->last_result->fetch->get(0);
is $r->type, 'best';

$agent->get_relationship($rids[0],'properties');
is_deeply $r->properties, $agent->last_result->fetch->get(0);

$agent->get_relationship($rids[0],'properties','state');
is $r->get('state'),$agent->last_result->fetch->get(0);

$agent->delete_relationship($rids[0],'properties','state');
$agent->get_relationship($rids[0],'properties');
is_deeply ['date'], [ keys %{$agent->last_result->fetch->get(0)} ];

$agent->delete_relationship($rids[0],'properties');
$agent->get_relationship($rids[0],'properties');
is_deeply {}, $agent->last_result->fetch->get(0);

$agent->delete_relationship($rids[0]);
$agent->get_relationship($rids[0]);
ok !$agent->last_result->fetch;

# post node, relationship

$agent->post_node();
ok my $n = $agent->last_result->fetch->get(0);

$agent->post_node([],{ foo => 'bar' });
ok my $m = $agent->last_result->fetch->get(0);
$agent->get_node($m->id,'properties');
is_deeply $agent->last_result->fetch->get(0), { foo => 'bar' };

$agent->post_node([$n->id, 'labels'],['alien']);
$agent->get_node($n->id,'labels');
is_deeply $agent->last_result->fetch->get(0), ['alien'];

$agent->post_node([$n->id, 'relationships'], { to => 'node/'.$m->id, type => 'squirts', data => {narf => 'crelb'} });
$agent->get_node($m->id, qw/relationships in/);
$r = $agent->last_result->fetch->get(0);
is $r->type, 'squirts';
is_deeply $r->properties, {narf => 'crelb'};
is $r->start_id, $n->id;
is $r->end_id, $m->id;

$agent->put_relationship([ $r->id, 'properties'], {bar => 'quux'});
$agent->get_relationship($r->id, 'properties');
is_deeply $agent->last_result->fetch->get(0), {narf => 'crelb', bar => 'quux'};

# get by label

$agent->get_labels();
is_deeply [ sort map {$_->get(0)} $agent->last_result->list], ['alien','person'];

$agent->get_label('person');
is scalar @{$agent->last_result->list}, 5;

$agent->get_label('person', { value => 10 });
is scalar @{$agent->last_result->list}, 1;

# node, relationship explicit indexes
$agent->post_node_index([], {name => 'people'});
ok $agent->last_result->fetch->get(0);

$agent->post_node_index(['people'], {key => 'they', value => 'I', uri => "node/$ids{I}"});
#is $agent->last_result->fetch->get(0)->get('name'), 'I';
ok $agent->last_result->fetch->get(0);

$agent->post_node_index(['people'], {key => 'they', value => 'he', uri => "node/$ids{he}"});
#is $agent->last_result->fetch->get(0)->get('name'),'he';
ok $agent->last_result->fetch->get(0);

$agent->post_node_index(['people'], {key => 'they', value => 'it', uri => "node/$ids{it}"});
#is $agent->last_result->fetch->get(0)->get('name'), 'it';
ok $agent->last_result->fetch->get(0);

$agent->get_node_index();
ok grep { $_->get(1) eq 'people' } @{$agent->last_result->list};

$agent->get_node_index('people',they => 'he');
is $agent->last_result->fetch->get(0)->get('name'), 'he';

throws_ok {
  $agent->post_node_index(['people'], { key => 'they', value => 'I', properties => {name => 'alter'} },
			  { uniqueness => 'create_or_fail' })
} 'REST::Neo4p::ConflictException';

$agent->post_node_index(['people'], { key => 'they', value => 'I', properties => {name => 'alter'} },
			{ uniqueness => 'get_or_create' });
$n = $agent->last_result->fetch->get(0);
$agent->get_node($n->id);
is $agent->last_result->fetch->get(0)->get('name'), 'I';

$agent->post_node_index(['people'], { key => 'they', value => 'alter', properties => {name => 'alter'} },
			{ uniqueness => 'get_or_create' });
$n = $agent->last_result->fetch->get(0);
$agent->get_node($n->id);
is $agent->last_result->fetch->get(0)->get('name'), 'alter';

$agent->post_relationship_index([],{name => 'friendships',type => 'squirts'});
$agent->get_relationship_index();
ok grep { $_->get(1) eq 'friendships' } @{$agent->last_result->list};

$agent->post_relationship_index(['friendships'],{key => 'squirty', value => 1, uri => "relationship/".$r->id});
ok $agent->last_result->fetch->get(0);

$agent->get_relationship_index('friendships','squirty',1);
is $agent->last_result->fetch->get(0)->type, 'squirts';

throws_ok {
  $agent->post_relationship_index(['friendships'], {key => 'squirty', value => 1, start => "node/".$ids{'she'},
						    end => "node/".$ids{'he'}, properties => { mucho => "bueno" }},
				  {uniqueness => 'create_or_fail'});
} 'REST::Neo4p::ConflictException';

$agent->post_relationship_index(['friendships'], {key => 'squirty', value => 1, start => "node/".$ids{'she'},
						    end => "node/".$ids{'he'}, properties => { mucho => "bueno" }},
				{uniqueness => 'get_or_create'});
$agent->get_relationship($agent->last_result->fetch->get(0)->id);
is $agent->last_result->fetch->get(0)->get('narf'), 'crelb';

$agent->post_relationship_index(['friendships'], {key => 'squirty', value => 2, start => "node/".$ids{'she'},
						    end => "node/".$ids{'he'}, type => 'squirts', properties => { mucho => "bueno" }},
				{uniqueness => 'get_or_create'});

$agent->get_relationship($agent->last_result->fetch->get(0)->id);
is $agent->last_result->fetch->get(0)->get('mucho'), 'bueno';

# schema constraints

$agent->post_schema_constraint(['person','uniqueness'], {property_keys => ['name']});

throws_ok {
  $agent->post_schema_constraint(['alien','existence'], {property_keys => ['planet']})
} 'REST::Neo4p::Neo4jTightwadException';

$result = $agent->get_schema_constraint();
ok grep { $_->{type} eq 'UNIQUENESS' } @$result;

$agent->delete_schema_constraint('person','uniqueness','name');
$result = $agent->get_schema_constraint();
ok !@$result;

done_testing;


