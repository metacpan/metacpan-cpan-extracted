use Test::More;
use lib '../lib';
use Tie::IxHash;
use Neo4j::Cypher::Abstract qw/cypher ptn/;
my $c;
tie my %props, 'Tie::IxHash';

is cypher->create( ptn->C(ptn->N('n'),ptn->N('m')) ),
  "CREATE (n),(m)",
  '3.3.11.1 (1)';

is cypher->create('n:Person'),
  "CREATE (n:Person)",
  '3.3.11.1 (2)';

is cypher->create('n:Person:Swedish'),
  "CREATE (n:Person:Swedish)",
  '3.3.11.1 (3)';

%props = ( name => 'Andres', title=>'Developer' );
is cypher->create(ptn->N('n:Person' => \%props)),
  "CREATE (n:Person {name:'Andres',title:'Developer'})",
  '3.3.11.1 (4)';

%props = ( 'a.name' => 'Node A', 'b.name' => 'Node B' );
is cypher->match(ptn->C( ptn->N('a:Person'), ptn->N('b:Person') ))
  ->where( \%props )
  ->create( ptn->N('a')->R('r:RELTYPE>')->N('b') )
  ->return('r'),
  "MATCH (a:Person),(b:Person) WHERE ((a.name = 'Node A') AND (b.name = 'Node B')) CREATE (a)-[r:RELTYPE]->(b) RETURN r",
  '3.3.11.2';

is cypher->match(ptn->C( ptn->N('a:Person'), ptn->N('b:Person') ))
  ->where( \%props )
  ->create( ptn->N('a')->R('r:RELTYPE>' => {name => \"a.name + '<->' + b.name"})->N('b') )
  ->return('r'),
  "MATCH (a:Person),(b:Person) WHERE ((a.name = 'Node A') AND (b.name = 'Node B')) CREATE (a)-[r:RELTYPE {name:a.name + '<->' + b.name}]->(b) RETURN r";


is cypher->create( ptn->N('andres' => {name => 'Andres'})
		     ->R(':WORKS_AT>')->N('neo')->R('<:WORKS_AT')
		     ->N('michael' => {name => 'Michael'})->as('p') )
  ->return('p'),
  "CREATE p = (andres {name:'Andres'})-[:WORKS_AT]->(neo)<-[:WORKS_AT]-(michael {name:'Michael'}) RETURN p",
  '3.3.11.3';

is $c = cypher->unwind('$props' => 'map')
  ->create('n')->set('n = map'),
  'UNWIND $props AS map CREATE (n) SET n = map',
  '3.3.11.4';
is_deeply [$c->parameters], [qw/$props/];

is cypher->match('n:Useless')->delete('n'),
  'MATCH (n:Useless) DELETE n',
  '3.3.12.1';

is cypher->match(ptn->N(n=>{name=>'Andres'}))
  ->detach_delete('n'),
"MATCH (n {name:'Andres'}) DETACH DELETE n",
  '3.3.12.4';

is cypher->match(ptn->N(n =>{name=>'Andres'})->R('r:KNOWS>')->N())
  ->delete('r'),
"MATCH (n {name:'Andres'})-[r:KNOWS]->() DELETE r",
  '3.3.12.5';

is cypher->match(ptn->N(n =>{name=>'Andres'}))
  ->set({'n.surname' => 'Taylor'})
  ->return('n'),
"MATCH (n {name:'Andres'}) SET n.surname = 'Taylor' RETURN n",
  '3.3.13.2';

is cypher->match(ptn->N(n =>{name=>'Andres'}))
  ->set({'n.position' => 'Developer'},{'n.surname' => 'Taylor'}),
  "MATCH (n {name:'Andres'}) SET n.position = 'Developer',n.surname = 'Taylor'",
  '3.3.13.8';

is cypher->match(ptn->N(n =>{name=>'Emil'}))
  ->set('n :Swedish:Bossman')->return('n'),
  "MATCH (n {name:'Emil'}) SET n :Swedish:Bossman RETURN n",
  '3.3.13.10';

is cypher->match(ptn->C(ptn->N(n =>{name=>'Emil'}),
			ptn->N(m=>{name=>'Andres'})))
  ->set('n :Swedish:Bossman','m :Minion')->return('n','m'),
  "MATCH (n {name:'Emil'}),(m {name:'Andres'}) SET n :Swedish:Bossman,m :Minion RETURN n,m",
  '3.3.13.10 (2)';

is cypher->match(ptn->N(andres =>{name=>'Andres'}))
  ->remove(qw/andres.age andres.frelb/)
  ->return('andres'),
  "MATCH (andres {name:'Andres'}) REMOVE andres.age,andres.frelb RETURN andres",
  '3.3.14.2';

%props = ('begin.name'=>'A', 'end.name'=>'D');
is cypher->match(ptn->N('begin')->R('>'=>[])->N('end')->as('p'))
  ->where(\%props)
  ->foreach( 'n' => 'nodes(p)', cypher->set({'n.marked' => \'TRUE'})),
  "MATCH p = (begin)-[*]->(end) WHERE ((begin.name = 'A') AND (end.name = 'D')) FOREACH (n IN nodes(p) | SET n.marked = TRUE)",
  '3.3.15.2';

is cypher->merge(ptn->N('keanu:Person'=>{name=>'Keanu Reeves'}))
  ->on_create( cypher->set({'keanu.created' => \'timestamp()'}) )
  ->return(qw/keanu.name keanu.created/),
"MERGE (keanu:Person {name:'Keanu Reeves'}) ON CREATE SET keanu.created = timestamp() RETURN keanu.name,keanu.created",
  '3.3.16.3';

is cypher->merge('person:Person')
  ->on_match(cypher->set({'person.found' => \'TRUE'}))
  ->return(qw/person.name person.found/),
"MERGE (person:Person) ON MATCH SET person.found = TRUE RETURN person.name,person.found",
  '3.3.16.3 (2)';

is cypher->merge('person:Person')
  ->on_match(cypher->set({'person.found'=>\'TRUE'},{'person.lastAccessed'=>\'timestamp()'}))
  ->return(qw/person.name person.found person.lastAccessed/),
"MERGE (person:Person) ON MATCH SET person.found = TRUE,person.lastAccessed = timestamp() RETURN person.name,person.found,person.lastAccessed",
  '3.3.16.3 (3)';

%props = (name=>'$param.name',role=>'$param.role');
is $c = cypher->merge(ptn->N('person:Person'=>\%props) )
  ->return(qw/person.name person.role/),
'MERGE (person:Person {name:$param.name,role:$param.role}) RETURN person.name,person.role',
  '3.3.16.6';

is_deeply [$c->parameters],['$param','$param'];

is cypher->match(ptn->N('root'=>{name=>'root'}))
  ->create_unique(ptn->N('root')->R(':LOVES')->N('someone'))
  ->return('someone'),
"MATCH (root {name:'root'}) CREATE UNIQUE (root)-[:LOVES]-(someone) RETURN someone",
  '3.3.18.1';

is cypher->match('n:Actor')->return('n.name AS name')
  ->union_all
  ->match('n:Movie')->return('n.title AS name'),
"MATCH (n:Actor) RETURN n.name AS name UNION ALL MATCH (n:Movie) RETURN n.title AS name",
  '3.3.19.2 (1)';
is cypher->match('n:Actor')->return('n.name AS name')
  ->union
  ->match('n:Movie')->return('n.title AS name'),
"MATCH (n:Actor) RETURN n.name AS name UNION MATCH (n:Movie) RETURN n.title AS name",
  '3.3.19.2 (2)';

done_testing;
