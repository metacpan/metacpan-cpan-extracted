use Test::More;
use Test::Exception;
use Mock::Quick;
use v5.10;
use lib '../../lib'; # testing
use REST::Neo4p::Agent;
use strict;
use warnings;

my $neothing_ctrl = qclass( -implement => 'Neo4j::Driver::Thing',
			    new => sub { shift; bless {}, 'Neo4j::Driver::Thing' },
			    id => 1 );

my $neorec_ctrl = qclass( -implement => 'Neo4j::Driver::Record',
			  new => sub { shift; bless { items => [@_] },
					 'Neo4j::Driver::Record' },
			  get => sub { return shift->{items}[shift] },
			 );

my $neores_ctrl = qclass( -implement => 'Neo4j::Driver::StatementResult',
			  new => sub { shift; bless [@_],
					 'Neo4j::Driver::StatementResult' },
			  fetch => sub { shift; return Neo4j::Driver::Record->new( Neo4j::Driver::Thing->new()) },
			  peek => sub { shift; return Neo4j::Driver::Record->new( Neo4j::Driver::Thing->new()) },			  
			 );

my $neosess_ctrl = qclass( -implement => 'Neo4j::Driver::Session',
			   new => sub { bless {}, 'Neo4j::Driver::Session'; },
			   run => sub { shift;
					return Neo4j::Driver::StatementResult->new(@_); },
			  );
			   

my $neodrv_ctrl = qclass( -implement => 'Neo4j::Driver',
			  new => sub { bless {}, 'Neo4j::Driver'; },
			  basic_auth => sub { return $_[0]; },
			  session => sub { Neo4j::Driver::Session->new() }
			 );

ok my $agent = REST::Neo4p::Agent->new(agent_module => 'Neo4j::Driver');
eval {
  $agent->connect('http://boog:goob@localhost:7474');
};
is $agent->server_url, 'http://localhost:7474', 'server_url';
is $agent->user,'boog', 'user';
is $agent->pwd,'goob','pwd';

$agent->get_propertykeys();
is $agent->last_result->[0], 'call db.propertyKeys()', 'get_propertykeys';

$agent->get_node(12);
is_deeply $agent->last_result, ['match (n) where id(n)=$id return n', {id => 12}];
  
$agent->get_node(13,'labels');
is_deeply $agent->last_result, ['match (n) where id(n)=$id return labels(n)', {id => 13}];

$agent->get_node(12,'properties');
is_deeply $agent->last_result, ['match (n) where id(n)=$id return properties(n)', {id => 12}];

$agent->get_node(qw/12 properties blarg/);
is_deeply $agent->last_result, ['match (n) where id(n)=$id return n[$prop]', {id => 12, prop => 'blarg'}];

$agent->get_node(qw/12 relationships all/);
is_deeply $agent->last_result, ['match (n)-[r]-() where id(n)=$id  return r', {id => 12}];

$agent->get_node(qw/12 relationships in/);
is_deeply $agent->last_result, ['match (n)<-[r]-() where id(n)=$id  return r', {id => 12}];

$agent->get_node(qw/12 relationships out/);
is_deeply $agent->last_result, ['match (n)-[r]->() where id(n)=$id  return r', {id => 12}];

$agent->get_node(qw/12 relationships all LIKES/);
is_deeply $agent->last_result, ['match (n)-[r]-() where id(n)=$id and type(r) in [\'LIKES\'] return r', {id => 12}];

$agent->get_node(qw/12 relationships in LIKES&LOVES/);
is_deeply $agent->last_result, ['match (n)<-[r]-() where id(n)=$id and type(r) in [\'LIKES\',\'LOVES\'] return r', {id => 12}];

$agent->get_node(qw/12 relationships out MEH/);
is_deeply $agent->last_result, ['match (n)-[r]->() where id(n)=$id and type(r) in [\'MEH\'] return r', {id => 12}];
  
$agent->delete_node(22);
is_deeply $agent->last_result, ['match (n) where id(n)=$id delete n', {id => 22}];

$agent->delete_node(qw/22 properties/);
is_deeply $agent->last_result, ['match (n) where id(n)=$id set n = {}', {id => 22}];

$agent->delete_node(qw/22 properties flerb/);
is_deeply $agent->last_result, ['match (n) where id(n)=$id remove n.flerb', {id => 22}];

$agent->delete_node(qw/22 labels goob/);
is_deeply $agent->last_result, ['match (n) where id(n)=$id remove n:goob', {id => 22}];

$agent->get_relationship('types');
is_deeply $agent->last_result->[0], 'call db.relationshipTypes()';

$agent->get_relationship(33);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id return r', {id => 33}];

$agent->get_relationship(qw/33 properties/);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id return properties(r)', {id => 33}];

$agent->get_relationship(qw/33 properties glarb/);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id return r[$prop]', {id => 33, prop => 'glarb'}];

$agent->delete_relationship(44);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id delete r', {id => 44}];

$agent->delete_relationship(qw/44 properties/);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id set r = {}', {id => 44}];

$agent->delete_relationship(qw/44 properties narb/);
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id remove r.narb', {id => 44}];

$agent->post_node();
is $agent->last_result->[0], 'create (n) return n';

$agent->post_node([],{ foo => 'bar' });
is $agent->last_result->[0], 'create (n) set n.foo = $foo return n';

$agent->post_node([qw/42 labels/],[qw/foo bar/]);
is_deeply $agent->last_result, ['match (n) where id(n)=$id set n:foo:bar',{id => 42}];

$agent->post_node([qw/42 labels/],'baz');
is_deeply $agent->last_result, ['match (n) where id(n)=$id set n:baz',{id => 42}];

$agent->post_node([qw/42 relationships/],{ to => 'http://localhost:7474/db/data/node/43', type => 'kludges'});
is_deeply $agent->last_result, ['match (n), (m) where id(n)=$fromid and id(m)=$toid create (n)-[r:kludges]->(m)  return r',{fromid => 42, toid => 43}];

$agent->post_node([qw/42 relationships/],{ to => 'http://localhost:7474/db/data/node/43', type => 'squirts', data => { foo => 12, bar => 'baz' }});

is_deeply $agent->last_result, ['match (n), (m) where id(n)=$fromid and id(m)=$toid create (n)-[r:squirts]->(m) set r.bar=\'baz\',r.foo=12 return r',{fromid => 42, toid => 43}];


$agent->put_node([qw/24 properties/], { foo => 'bar', baz => 'quux' });
is_deeply $agent->last_result, ['match (n) where id(n)=$id set n.baz=\'quux\',n.foo=\'bar\' return n', {id => 24}];
  
$agent->put_node([qw/24 properties baz/], 'quux');
is_deeply $agent->last_result, ['match (n) where id(n)=$id set n.baz=$value return n', {id => 24, value => 'quux'}];

$agent->put_relationship([qw/24 properties/], { foo => 'bar', baz => 'quux' });
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id set r.baz=\'quux\',r.foo=\'bar\' return r', {id => 24}];
  
#$agent->put_relationship([qw/24 properties baz/], 'quux');
$agent->put_data([qw/relationship 24 properties baz/], 'quux');
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id set r.baz=$value return r', {id => 24, value => 'quux'}];

$agent->get_labels();
is $agent->last_result->[0], 'call db.labels()';

$agent->get_label('Narf');
is $agent->last_result->[0], 'match (n:Narf) return n';

$agent->get_label('Blarf', { name => 'shroom', thing => 1 });

is_deeply $agent->last_result, ['match (n:Blarf) where n.name=$name and n.thing=$thing return n', {name => 'shroom', thing => 1}];

$agent->post_node_index([],{name => 'blarf'});
is_deeply $agent->last_result, ['call db.index.explicit.forNodes($name)', {name => 'blarf'}];

$agent->post_node_index(['blarf'],{key => 'test', value => 1, uri => 'http://localhost:7474/db/data/node/10'});
is_deeply $agent->last_result, ['match (n) where id(n)=$id call db.index.explicit.addNode($idx,n,$key,$value) yield success with n, success return case success when true then n else false end as result', {key => 'test', value => 1, idx => 'blarf', id => 10}];

$agent->post_relationship_index([],{name => 'flarb'});
is_deeply $agent->last_result, ['call db.index.explicit.forRelationships($name)', {name => 'flarb'}];

$agent->post_relationship_index(['flarb'],{key => 'test', value => 2, uri => 'http://localhost:7474/db/data/relationship/20'});
is_deeply $agent->last_result, ['match ()-[r]->() where id(r)=$id call db.index.explicit.addRelationship($idx,r,$key,$value) yield success with r, success return case success when true then r else false end as result', {key => 'test', value => 2, idx => 'flarb', id => 20}];

$neores_ctrl->override( has_next => 1 );

$agent->post_node_index(['blarf'],{key => 'test', value=>1, properties => { this => 10, that => 'other' }}, { uniqueness => 'get_or_create' });

is $agent->last_result->[0], "call db.index.explicit.seekNodes('blarf', 'test', 1)";

throws_ok { $agent->post_node_index(['blarf'],{key => 'test', value=>1, properties => { this => 10, that => 'other' }}, { uniqueness => 'create_or_fail' }); } 'REST::Neo4p::ConflictException';

$neores_ctrl->override( has_next => 0 );

$agent->post_node_index(['blarf'],{key => 'test', value=>1, properties => { this => 10, that => 'other' }}, { uniqueness => 'get_or_create' });

is $agent->last_result->[0], 'match (n) where id(n)=$id return n'; # "call db.index.explicit.seekNodes('blarf', 'test', 1)";

#TODO : {
#  local $TODO = 'mock correctly';
  eval {
    $agent->post_node_index(['blarf'],{key => 'test', value=>1, properties => { this => 10, that => 'other' }}, { uniqueness => 'create_or_fail' });
  };
    
  is $agent->last_result->[0], 'match (n) where id(n)=$id return n';
#}


$neores_ctrl->override( has_next => 1 );

$agent->post_relationship_index(['flarb'],{key => 'test', value=>2, start => 'http://localhost:7474/db/data/node/10', end => 'http://localhost:7474/db/data/node/20', type => 'ISA'}, { uniqueness => 'get_or_create' });

is $agent->last_result->[0], "call db.index.explicit.seekRelationships('flarb', 'test', 2)";

throws_ok { $agent->post_relationship_index(['flarb'],{key => 'test', value=>2, start => 'http://localhost:7474/db/data/node/10', end => 'http://localhost:7474/db/data/node/20', type => 'ISA'}, { uniqueness => 'create_or_fail' }); } 'REST::Neo4p::ConflictException';

$neores_ctrl->override( has_next => 0 );

$agent->post_relationship_index(['flarb'],{key => 'test', value=>2, start => 'http://localhost:7474/db/data/node/10', end => 'http://localhost:7474/db/data/node/20', type => 'ISA'}, { uniqueness => 'get_or_create' });

is $agent->last_result->[0], 'match ()-[r]->() where id(r)=$id return r'; #"call db.index.explicit.seekRelationships('flarb', 'test', 2)";

#TODO: {
#  local $TODO = 'mock correctly';
  eval {
    $agent->post_relationship_index(['flarb'],{key => 'test', value=>2, start => 'http://localhost:7474/db/data/node/10', end => 'http://localhost:7474/db/data/node/20', type => 'ISA'}, { uniqueness => 'create_or_fail' });
  };
  is $agent->last_result->[0], 'match ()-[r]->() where id(r)=$id return r';
# }

$agent->get_node_index();
is $agent->last_result->[0], 'call db.index.explicit.list()';

$agent->get_node_index('blarf', 'test', "this%20is%202");
is_deeply $agent->last_result, ['call db.index.explicit.seekNodes($idx,$key,$value)',
				{ idx => 'blarf', key => 'test', value => 'this is 2' } ];

$agent->get_node_index('blarf', {query => "this%20is%202"});
is_deeply $agent->last_result, ['call db.index.explicit.searchNodes($idx,$query)',
				{ idx => 'blarf', query => 'this is 2' } ];

$agent->delete_node_index('blarf');
is_deeply $agent->last_result, ['call db.index.explicit.drop($idx)',{idx => 'blarf'}];

$agent->delete_relationship_index('flarb');
is_deeply $agent->last_result, ['call db.index.explicit.drop($idx)',{idx => 'flarb'}];

$agent->delete_node_index('blarf', 55);
is_deeply $agent->last_result, ['call db.index.explicit.removeNode( $idx, $id )', {idx => 'blarf', id => 55}];

$agent->delete_node_index('blarf', 'narb', 55);
is_deeply $agent->last_result, ['call db.index.explicit.removeNode( $idx, $id, $key )', {idx => 'blarf', id => 55, key => 'narb'}];

$agent->delete_node_index('blarf', 'narb', 5, 55);
is_deeply $agent->last_result, ['call db.index.explicit.removeNode( $idx, $id, $key )', {idx => 'blarf', id => 55, key => 'narb'}];

$agent->delete_relationship_index('flarb', 66);
is_deeply $agent->last_result, ['call db.index.explicit.removeRelationship( $idx, $id )', {idx => 'flarb', id => 66}];

$agent->delete_relationship_index('flarb', 'narf', 66);
is_deeply $agent->last_result, ['call db.index.explicit.removeRelationship( $idx, $id, $key )', {idx => 'flarb', id => 66, key => 'narf'}];

$agent->delete_relationship_index('flarb', 'narf', 7, 66);
is_deeply $agent->last_result, ['call db.index.explicit.removeRelationship( $idx, $id, $key )', {idx => 'flarb', id => 66, key => 'narf'}];

my @tst_c = (
  'CONSTRAINT ON (thing:thing) ASSERT exists(thing.exist_item)',
  'CONSTRAINT ON (thing:thing) ASSERT thing.unique_item IS UNIQUE',
  'CONSTRAINT ON ()-[l:rel_type]-() ASSERT exists(l.rel_prop)',
 );

my @ret = @tst_c;
$neores_ctrl->override( fetch => sub {
			  my $s = shift @ret;
			  return Neo4j::Driver::Record->new($s) if defined $s;
			} );

is_deeply $agent->get_schema_constraint(),
  [ { label => 'thing', property_keys => ['exist_item'], type => 'NODE_PROPERTY_EXISTENCE' },
    { label => 'thing', property_keys => ['unique_item'], type => 'UNIQUENESS' },
    { relationshipType => 'rel_type', property_keys => ['rel_prop'], type => 'RELATIONSHIP_PROPERTY_EXISTENCE'} ];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing'),
  [ { label => 'thing', property_keys => ['exist_item'], type => 'NODE_PROPERTY_EXISTENCE' },
    { label => 'thing', property_keys => ['unique_item'], type => 'UNIQUENESS' } ];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing', 'uniqueness'),
  [ { label => 'thing', property_keys => ['unique_item'], type => 'UNIQUENESS' } ];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing','existence'),
  [ { label => 'thing', property_keys => ['exist_item'], type => 'NODE_PROPERTY_EXISTENCE' } ];

@ret = @tst_c;
#$agent->get_schema_constraint('thing', 'uniqueness', 'unique_item'),
is_deeply $agent->get_data('schema','constraint','thing', 'uniqueness', 'unique_item'),
  [ { label => 'thing', property_keys => ['unique_item'], type => 'UNIQUENESS' } ];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing', 'uniqueness', 'unique_blarf'), [];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing','existence','exist_item'),
  [ { label => 'thing', property_keys => ['exist_item'], type => 'NODE_PROPERTY_EXISTENCE' } ];

@ret = @tst_c;
is_deeply $agent->get_schema_constraint('thing','existence','exist_blarf'), [];

#$agent->delete_schema_constraint('thing','existence','exist_blarf');
$agent->delete_data('schema','constraint','thing','existence','exist_blarf');
is $agent->last_result->[0], 'drop constraint on (n:thing) assert exists(n.exist_blarf)';

$agent->delete_schema_constraint('thing','uniqueness','exist_blarf');
is $agent->last_result->[0], 'drop constraint on (n:thing) assert n.exist_blarf is unique';

#$agent->post_schema_constraint(['thing','existence'],{ property_keys => ['exist_blarf'] });
$agent->post_data(['schema','constraint','thing','existence'],{ property_keys => ['exist_blarf'] });
is $agent->last_result->[0], 'create constraint on (n:thing) assert exists(n.exist_blarf)';

$agent->post_schema_constraint(['thing','uniqueness'],{ property_keys => ['exist_blarf'] });
is $agent->last_result->[0], 'create constraint on (n:thing) assert n.exist_blarf is unique';

# TODO: test unhappy paths

# TODO:
# $agent->get_data();
# $agent->delete_data();
# $agent->post_data();
# $agent->put_data();
  
done_testing;

1;

