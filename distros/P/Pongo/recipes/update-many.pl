use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my @updates = (
    { name => "Eric Doe", age => 46, email => "eric.updated\@gmail.com" },
    { name => "Bob Johnson", age => 30, email => "bob.johnson\@example.com" },
);

foreach my $data (@updates) {
    my $selector = Pongo::BSON::new();
    Pongo::BSON::append_utf8($selector, "name", -1, $data->{name}, -1);

    my $update = Pongo::BSON::new();
    my $set = Pongo::BSON::new();
    Pongo::BSON::append_int32($set, "age", -1, $data->{age});
    Pongo::BSON::append_utf8($set, "email", -1, $data->{email}, -1);

    Pongo::BSON::append_document($update, "\$set", -1, $set);

    my $result = Pongo::Client::collection_update_one($collection, $selector, $update, undef, undef, undef);

    if ($result) {
        print "Document for $data->{name} updated successfully\n";
    } else {
        print "Failed to update document for $data->{name}\n";
    }

    Pongo::BSON::destroy($selector);
    Pongo::BSON::destroy($update);
    Pongo::BSON::destroy($set);
}

Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;
