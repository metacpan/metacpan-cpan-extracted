match (n) detach delete n;
create (n:person) set n.name="I";
create (n:person) set n.name="you";
create (n:person) set n.name="he";
create (n:person) set n.name="she", n.value=10;
create (n:person) set n.name="it";
create (n:person) set n.name="noone", n.rem="bye";

match (n:person {name:"I"}),(m:person {name:"you"}) create (n)-[:bosom]->(m);
match (n:person {name:"I"}),(m:person {name:"you"}) create (n)-[r:best]->(m) set r.date = '2/2/02', r.state = 'ME';
match (n:person {name:"I"}),(m:person {name:"you"}) create (n)<-[r:best]-(m) set r.date = '1/1/01', r.state = 'DE';
match (n:person {name:"he"}),(m:person {name:"she"}) create (n)-[:umm]->(m);
match (n:person {name:"she"}),(m:person {name:"it"}) create (n)-[:fairweather]->(m);
match (n:person {name:"she"}),(m:person {name:"I"}) create (n)-[:good]->(m);





