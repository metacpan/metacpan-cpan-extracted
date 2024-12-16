use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;
use JSON;

sub print_distinct_values {
    my ($documents, $field) = @_;
    my %distinct_values;

    foreach my $doc (@$documents) {
        if (ref($doc) eq 'HASH' && exists $doc->{$field}) {
            $distinct_values{$doc->{$field}} = 1;
        }
    }

    print "Distinct values for field '$field':\n";
    foreach my $value (keys %distinct_values) {
        print "$value\n";
    }
}

my $client = Pongo::Client::client_new("mongodb://localhost:27017");
my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");
my $query = Pongo::BSON::new();

my $cursor = Pongo::Client::collection_find($collection, 0, 0, 0, 0, $query, Pongo::BSON::new(), undef);

my @bson_data;
my @documents;

while (Pongo::Client::cursor_next($cursor, \@bson_data)) {
    my $json_str = $bson_data[0];
    my $decoded_doc = decode_json($json_str);
    push @documents, $decoded_doc;
    @bson_data = ();
}

my $field = "age";
print_distinct_values(\@documents, $field);

Pongo::Client::cursor_destroy($cursor);
Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);
