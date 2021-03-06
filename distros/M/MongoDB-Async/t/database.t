use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use MongoDB::Async::Timestamp; # needed if db is being run as master

use MongoDB::Async;

my $conn;
eval {
    my $host = "localhost";
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    $conn = MongoDB::Async::MongoClient->new(host => $host, ssl => $ENV{MONGO_SSL});
};

if ($@) {
    plan skip_all => $@;
}
else {
    plan tests => 13;
}

isa_ok($conn, 'MongoDB::Async::MongoClient');

my $db = $conn->get_database('test_database');
$db->drop;

isa_ok($db, 'MongoDB::Async::Database');

$db->drop;

is(scalar $db->collection_names, 0, 'no collections');
my $coll = $db->get_collection('test');
is($coll->count, 0, 'collection is empty');

is($coll->find_one, undef, 'nothing for find_one');

my $id = $coll->insert({ just => 'another', perl => 'hacker' });

is(scalar $db->collection_names, 2, 'test, system.indexes, and test.$_id_');
ok((grep { $_ eq 'test' } $db->collection_names), 'collection_names');
is($coll->count, 1, 'count');
is($coll->find_one->{perl}, 'hacker', 'find_one');
is($coll->find_one->{_id}->value, $id->value, 'insert id');

my $result = $db->run_command({ foo => 'bar' });
ok ($result =~ /no such cmd/, "run non-existent command: $result");

# getlasterror
SKIP: {
    my $admin = $conn->get_database('admin');
    my $buildinfo = $admin->run_command({buildinfo => 1});

    #skip "MongoDB 1.5+ needed", 1 if $buildinfo->{version} =~ /(0\.\d+\.\d+)|(1\.[1234]\d*.\d+)/;
    #my $result = $db->last_error({w => 20, wtimeout => 1});
    #is($result, 'timed out waiting for slaves', 'last error timeout');

    skip "MongoDB 1.5+ needed", 2 if $buildinfo->{version} =~ /(0\.\d+\.\d+)|(1\.[1234]\d*.\d+)/;

    my $result = $db->last_error({fsync => 1});
    is($result->{ok}, 1);
    is($result->{err}, undef);
}


END {
    if ($conn) {
        $conn->get_database( 'foo' )->drop;
    }
    if ($db) {
        $db->drop;
    }
}
