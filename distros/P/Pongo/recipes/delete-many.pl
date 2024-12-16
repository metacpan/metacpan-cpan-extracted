# mongosh
# use testdb
# db.createCollection("myCollection")
# db.myCollection.insertOne({
#   name: "Product 1",
#   category: "Electronics",
#   price: 99,
#   description: "Affordable electronic product"
# });

# db.myCollection.insertOne({
#   name: "Product 2",
#   category: "Home Appliances",
#   price: 199,
#   description: "Useful home appliance"
# });

# db.myCollection.insertOne({
#   name: "Product 3",
#   category: "Electronics",
#   price: 499,
#   description: "High-end electronic gadget"
# });

# db.myCollection.insertOne({
#   name: "Product 4",
#   category: "Furniture",
#   price: 159,
#   description: "Comfortable and stylish furniture"
# });

# db.myCollection.insertOne({
#   name: "Product 5",
#   category: "Clothing",
#   price: 49,
#   description: "Stylish clothing item"
# });

use strict;
use warnings;
use Pongo::Client;
use Pongo::BSON;

my $client = Pongo::Client::client_new("mongodb://localhost:27017");

my $collection = Pongo::Client::client_get_collection($client, "testdb", "myCollection");

my $query = Pongo::BSON::new();
Pongo::BSON::append_utf8($query, "category", -1, "Electronics", -1);

Pongo::Client::collection_delete_many($collection, $query, undef, undef, undef);

my $product = Pongo::BSON::new();
Pongo::BSON::append_utf8($product, "name", -1, "Sample Product", -1);
Pongo::BSON::append_utf8($product, "category", -1, "Electronics", -1);
Pongo::BSON::append_int32($product, "price", -1, 299);
Pongo::BSON::append_utf8($product, "description", -1, "A high-quality electronic gadget", -1);

Pongo::Client::collection_insert_one($collection, $product, undef, undef, undef);

Pongo::BSON::destroy($query);
Pongo::BSON::destroy($product);

Pongo::Client::collection_destroy($collection);
Pongo::Client::client_destroy($client);

1;
