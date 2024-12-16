use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");
my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");
my $query = Pongo::BSON::new();

my $cursor = Pongo::Client::collection_find($collection, 0, 0, 10, 0, $query, Pongo::BSON::new(), undef);

my @bson_data;

while (Pongo::Client::cursor_next($cursor, \@bson_data)) {
    my $bson = $bson_data[0];
    print "Document: ", $bson, "\n";
    @bson_data = ();
}

Pongo::Client::cursor_destroy($cursor);
Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);
