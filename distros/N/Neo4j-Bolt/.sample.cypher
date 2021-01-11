create (n:thing {name:"I"})-[r:friend_of {type:"bosom"}]->(b:thing {name:"you"});
match (a:thing {name:"I"}),(b:thing {name:"you"}) with a, b create (a)-[:friend_of {type:"best"}]->(b),(b)-[:friend_of {type:"best"}]->(a);
create (n:thing {name:"he"})-[r:friend_of {type:"umm"}]->(b:thing {name:"she"});
create (n:thing {name:"it"});
match (a:thing {name:"she"}),(b:thing {name:"it"}) with a, b create (a)-[r:friend_of {type:"fairweather"}]->(b);
match (a:thing {name:"she"}), (b:thing {name:"I"}) with a, b create (a)-[r:friend_of {type:"good"}]->(b);
:exit
