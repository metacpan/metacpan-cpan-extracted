use Test::More;
use lib '../lib';
use Tie::IxHash;
use Neo4j::Cypher::Abstract qw/cypher ptn/;

isa_ok(cypher, 'Neo4j::Cypher::Abstract');
isa_ok(ptn, 'Neo4j::Cypher::Pattern');

tie my %props, 'Tie::IxHash';
$DB::single=1;
 my $c = cypher->match('n')->where({ 'n.name' => 'Fred' })->return('n.spouse');
isa_ok($c, 'Neo4j::Cypher::Abstract');

is "$c", "MATCH (n) WHERE (n.name = 'Fred') RETURN n.spouse";

my $p = ptn->N(n);
$c = cypher->match($p)->where({ 'n.name' => 'Fred' })->return('n.spouse');
is "$c", "MATCH (n) WHERE (n.name = 'Fred') RETURN n.spouse";

#examples from https://neo4j.com/docs/developer-manual/current/cypher/clauses

is cypher->match(ptn->N('movie:Movie'))->return('movie.title'),
  'MATCH (movie:Movie) RETURN movie.title', '3.3.1.2';

is cypher->match(ptn->N(movie => ['Movie']))->return('movie.title'),
  'MATCH (movie:Movie) RETURN movie.title', '3.3.1.2 (2)';

is cypher->match(ptn->N('director',{name=>'Oliver Stone'})->R->N('movie'))
  ->return('movie.title'),
  , "MATCH (director {name:'Oliver Stone'})--(movie) RETURN movie.title",
  '3.3.1.2';

is cypher->match(ptn->N(':Person',{name=>'Oliver Stone'})->R("r>")->N('movie'))->return('type(r)'),
  "MATCH (:Person {name:'Oliver Stone'})-[r]->(movie) RETURN type(r)",'3.3.1.3';

is cypher->match(ptn->N("wallstreet:Movie",{title => 'Wall Street'})->R("<:ACTED_IN")->N('actor'))->return('actor.name'),
  "MATCH (wallstreet:Movie {title:'Wall Street'})<-[:ACTED_IN]-(actor) RETURN actor.name",'3.3.1.3';

is cypher->match(ptn->N('wallstreet',{title=>'Wall Street'})->R("<:ACTED_IN|:DIRECTED")->N('person'))->return('person.name'),
"MATCH (wallstreet {title:'Wall Street'})<-[:ACTED_IN|:DIRECTED]-(person) RETURN person.name",'3.3.1.3';

is cypher->match(ptn->N("a:Movie",{title=>'Wall Street'}))
  ->optional_match(ptn->N('a')->R("r:ACTS_IN>")->N)
  ->return('r'),
  "MATCH (a:Movie {title:'Wall Street'}) OPTIONAL MATCH (a)-[r:ACTS_IN]->() RETURN r",'3.3.2.4';
TODO: {
  local $TODO = 'fix literal quoting';
  is cypher->match(ptn->N('a',{name=>'A'}))
  ->return('a.age > 30', "\"I'm a literal\"",ptn->N('a')->R('>')->N()),
  "MATCH (a {name:'A'}) RETURN a.age > 30,\"I\'m a literal\",(a)-->()",'3.3.4.9';
}

is cypher->match(ptn->N(a => {name => 'A'})->R('>')->N('b'))
  ->return_distinct('b'),
  "MATCH (a {name:'A'})-->(b) RETURN DISTINCT b",'3.3.4.10';

is cypher->match(ptn->N(david => {name=>'David'})->_N('otherPerson')->to_N)->with('otherPerson', 'count(*) AS foaf')->where('foaf > 1')->return('otherPerson.name'),
  "MATCH (david {name:'David'})--(otherPerson)-->() WITH otherPerson,count(*) AS foaf WHERE foaf > 1 RETURN otherPerson.name", '3.3.5.2';

is cypher->match('(n)')->with('n')->order_by('n.name','desc')->limit(3)->return({ -collect => \'n.name' }),
  "MATCH (n) WITH n ORDER BY n.name DESC LIMIT 3 RETURN collect(n.name)",
  '3.3.5.3';

%props = (year => 'event.year',other=>'frelb');
my $c= cypher->unwind('$events' => 'event')
  ->merge(ptn('event')->N('y:Year' => \%props))
  ->merge(ptn('event')->N('y')->R("<:IN")->N('e:Event'=> { id => 'event.id' }))->return('e.id AS x')
  ->order_by('x');
is $c,
  'UNWIND $events AS event MERGE (y:Year {year:event.year,other:\'frelb\'}) MERGE (y)<-[:IN]-(e:Event {id:event.id}) RETURN e.id AS x ORDER BY x','3.3.6.4';
is_deeply [$c->parameters], ['$events'], '3.3.6.4 collect parms';

is cypher->match('n')->where(ptn->N(n => ['Swedish']))->return('n.name','n.age'),"MATCH (n) WHERE (n:Swedish) RETURN n.name,n.age",'3.3.7.2 (1)';

is cypher->match('n')->where({'n.age' => {'<' => 30}})->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.age < 30) RETURN n.name,n.age", '3.3.7.2 (2)';


is cypher->match(ptn->N('n')->R('k:KNOWS>')->N('f'))
  ->where( { 'k.since' => { '<' => 2000 }} )
  ->return('f.name','f.age','f.email'),
  "MATCH (n)-[k:KNOWS]->(f) WHERE (k.since < 2000) RETURN f.name,f.age,f.email",
  '3.3.7.2 (3)';

TODO : {
  local $TODO = "think about node indexing with []";
  is cypher->with("'AGE' AS propname")
    ->match('n')
    ->where( { 'n[toLower(propname)]' => { '<' => 30 }})
    ->return(qw/n.name n.age/),
"WITH 'AGE' AS propname MATCH (n) WHERE (n[toLower(propname)] < 30) RETURN n.name,n.age", '3.3.7.2 (4)'
}

is cypher->match('n')->where({ -exists => \'n.belt' })
  ->return(qw/n.name n.belt/),
  "MATCH (n) WHERE exists(n.belt) RETURN n.name,n.belt",'3.3.7.2 (5)';

is cypher->match('n')->where({ 'n.name' => { -starts_with => 'Pet'}})
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name STARTS WITH 'Pet') RETURN n.name,n.age",
  '3.3.7.3';

is cypher->match('n')->where([ -starts_with => \'n.name', 'Pet'])
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name STARTS WITH 'Pet') RETURN n.name,n.age",
  '3.3.7.3 (2)';
is cypher->match('n')->where( {'n.name' => { -ends_with => 'ter' }} )
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name ENDS WITH 'ter') RETURN n.name,n.age",
  '3.3.7.3 (3)';
is cypher->match('n')->where( {'n.name' => { -contains => 'ete' }} )
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name CONTAINS 'ete') RETURN n.name,n.age",
  '3.3.7.3 (4)';

is cypher->match('n')
  ->where( { -not => { 'n.name' => { -ends_with => 's'}}} )
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE NOT (n.name ENDS WITH 's') RETURN n.name,n.age",
  '3.3.7.3 (5)';

is cypher->match('n')
  ->where( { 'n.name' => { '=~' => 'Tob.*' } } )
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name =~ 'Tob.*') RETURN n.name,n.age",
  '3.3.7.4 (1)';

is cypher->match('n')
  ->where( { 'n.name' => { '=~' => '(?i)ANDR.*' } } )
  ->return(qw/n.name n.age/),
  "MATCH (n) WHERE (n.name =~ '(?i)ANDR.*') RETURN n.name,n.age",
  '3.3.7.4 (2)';

is cypher->match(
  ptn->C( ptn->N(tobias => {name=>'Tobias'}),
	  ptn->N('others') )
 )
  ->where([ -and => {'others.name' => { -in => ['Andres','Peter'] }},
	    ptn->N('tobias')->from_N('others') ])
  ->return( qw/others.name others.age/ ),
  "MATCH (tobias {name:'Tobias'}),(others) WHERE ((others.name IN ['Andres','Peter']) AND (tobias)<--(others)) RETURN others.name,others.age",
  '3.3.7.5';

is cypher->match('n')
  ->where( [ 'n.belt' => 'white', 'n.belt' => undef ])
  ->return(qw/n.name n.age n.belt/)
  ->order_by('n.name'),
"MATCH (n) WHERE ((n.belt = 'white') OR n.belt IS NULL) RETURN n.name,n.age,n.belt ORDER BY n.name",
  '3.3.7.7 (1)';

%props = ( 'person.name' => 'Peter', 'person.belt' => undef );
is cypher->match('person')
  ->where(\%props)
  ->return(qw/person.name person.age person.belt/),
"MATCH (person) WHERE ((person.name = 'Peter') AND person.belt IS NULL) RETURN person.name,person.age,person.belt",
  '3.3.7.7 (2)';

is cypher->match('a')
  ->where([ -and => { 'a.name' => {'>' => 'Andres'}},
	    {'a.name' => {'<' => 'Tobias'}} ])
  ->return(qw/a.name a.age/),
  "MATCH (a) WHERE ((a.name > 'Andres') AND (a.name < 'Tobias')) RETURN a.name,a.age",
  '3.3.7.8';

is cypher->match('n')->return(qw/n.name n.age/)->order_by(qw/n.age n.name/),
  "MATCH (n) RETURN n.name,n.age ORDER BY n.age,n.name",
  '3.3.8.3';

is cypher->match('n')->return(qw/n.name n.age/)
  ->order_by( 'n.name'=>'desc', 'n.age' ),
  "MATCH (n) RETURN n.name,n.age ORDER BY n.name DESC,n.age",
  '3.3.8.4';

is cypher->match('n')->return('n.name')
  ->order_by('n.name')->skip(1)->limit(2),
"MATCH (n) RETURN n.name ORDER BY n.name SKIP 1 LIMIT 2",
  '3.3.9.3';


is cypher->match('n')->return('n.name')
  ->order_by('n.name')->skip(\'toInt(3*rand())+1'),
"MATCH (n) RETURN n.name ORDER BY n.name SKIP toInt(3*rand())+1",
  '3.3.9.4';

done_testing;
