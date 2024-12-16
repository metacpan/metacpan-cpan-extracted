# mongosh
# use testdb
# db.createCollection("myCollection")
# db.myCollection.insertOne({ name: "John Doe", age: 30, email: "john.doe@example.com" })

use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my $query = Pongo::BSON::new();
Pongo::BSON::append_utf8($query, "name", -1, "John Doe", -1);

Pongo::Client::collection_delete_one($collection, $query, undef, undef, undef);

Pongo::BSON::destroy($query);
Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;
