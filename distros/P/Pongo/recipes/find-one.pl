use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my $query = Pongo::BSON::new();
my $key = "name";
my $value = "Eric Doe";

Pongo::BSON::append_utf8($query, $key, length($key), $value, length($value));

my $cursor = Pongo::Client::collection_find($collection, 0, 0, 1, 0, $query, Pongo::BSON::new(), undef);

my @bson_data;

if (Pongo::Client::cursor_next($cursor, \@bson_data)) {
    my $bson = $bson_data[0];
    print "Found Document: ", $bson, "\n";
} else {
    print "No document found matching the query.\n";
}

Pongo::Client::cursor_destroy($cursor);
Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);
