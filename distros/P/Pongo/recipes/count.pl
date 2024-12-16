use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my $query = Pongo::BSON::new();

my $count = Pongo::Client::collection_count($collection, 0, $query, 0, 0, undef, undef);

print "Total documents in the collection: $count\n";

Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;
