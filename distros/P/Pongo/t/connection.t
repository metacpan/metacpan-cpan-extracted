use strict;
use warnings;
use Test::More tests => 2;
use Pongo::Client;

my $host = 'localhost';
my $port = 27017;

eval {
    Pongo::Client::connect_mongodb($host, $port);
};
ok(!$@, "Connected to MongoDB");

eval {
    Pongo::Client::disconnect_mongodb();
};
ok(!$@, "Disconnected from MongoDB");
