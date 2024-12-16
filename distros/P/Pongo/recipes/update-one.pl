use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my $selector = Pongo::BSON::new();
Pongo::BSON::append_utf8($selector, "name", -1, "Eric Doe", -1);

my $update = Pongo::BSON::new();
my $set = Pongo::BSON::new();
Pongo::BSON::append_int32($set, "age", -1, 46);
Pongo::BSON::append_utf8($set, "email", -1, "eric.updated\@gmail.com", -1);

Pongo::BSON::append_document($update, "\$set", -1, $set);

my $result = Pongo::Client::collection_update_one($collection, $selector, $update, undef, undef, undef);

if ($result) {
    print "Document updated successfully\n";
} else {
    print "Failed to update document\n";
}

Pongo::BSON::destroy($selector);
Pongo::BSON::destroy($update);
Pongo::BSON::destroy($set);
Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;
