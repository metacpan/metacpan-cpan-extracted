use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my @data = (
    { name => "Eric Doe", age => 45, email => "eric\@gmail.com" },
    { name => "Alice Smith", age => 30, email => "alice\@gmail.com" },
    { name => "Bob Johnson", age => 38, email => "bob\@gmail.com" },
);

foreach my $entry (@data) {
    my $query = Pongo::BSON::new();

    Pongo::BSON::append_utf8($query, "name", -1, $entry->{name}, -1);
    Pongo::BSON::append_int32($query, "age", -1, $entry->{age});
    Pongo::BSON::append_utf8($query, "email", -1, $entry->{email}, -1);

    Pongo::Client::collection_insert_one($collection, $query, undef, undef, undef);
    Pongo::BSON::destroy($query);
}

Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;