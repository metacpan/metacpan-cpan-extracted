#!/usr/bin/perl

use Test::More tests => 5;
use Test::Warn;

use strict;
use warnings;

use Data::Dumper;
use MongoDB;
use DateTime;
use DateTime::Duration;
use MongoDB::Simple qw/ oid /;
use MongoDB::Simple::Test;
use boolean;

# Make sure we have mongodb installed, otherwise skip all tests
my $client;
my $db;
eval {
    my $host = "localhost";
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    $client = MongoDB::MongoClient->new(host => $host, ssl => $ENV{MONGO_SSL});
    $db = $client->get_database('mtest');
    $db->drop if $db;
} if !$ENV{MONGODB_SIMPLE_TEST_NOCONNECTION};


# Helper method to create a new object
sub makeNewObject {
    my $obj = new MongoDB::Simple::Test(client => $client);

    my $dt = shift || DateTime->now;
    my $meta = new MongoDB::Simple::Test::Meta;
    $meta->type('meta type');
    my $label = new MongoDB::Simple::Test::Label;
    $label->text('test label');

    $obj->name('Test name');
    $obj->created($dt);
    $obj->available(true);
    $obj->attr({ key1 => 'key 1', key2 => 'key 2' });
    $obj->tags(['tag1', 'tag2']);
    $obj->metadata($meta);
    $obj->labels([]);
    push $obj->labels, $label;

    my $id = $obj->save;
    return ($id, $dt, $meta, $label);
}

subtest 'MongoDB methods' => sub {
    plan tests => 2;

    SKIP: {
        skip 'MongoDB connection required for test', 2 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        my $obj = $db->get_collection('items')->find_one({'_id' => $id})->as('MongoDB::Simple::Test');
        isa_ok($obj, 'MongoDB::Simple::Test', 'Object returned by find_one');

        my $cursor = $db->get_collection('items')->find;
        my $obj2 = $cursor->next->as('MongoDB::Simple::Test');
        isa_ok($obj2, 'MongoDB::Simple::Test', 'Object returned by cursor');
    }
};

subtest 'Object methods' => sub {
    plan tests => 7;

    my $obj = new_ok('MongoDB::Simple::Test');
    isa_ok($obj, 'MongoDB::Simple');

    # Has mongodb related methods
    can_ok($obj, "dump", "locator", "load", "save");

    # Has static methods
    can_ok($obj, "addmeta", "addfieldmeta", "getmeta", "package_start", "oid", "import", "new");

    # Has accessor methods
    can_ok($obj, "defaultAccessor", "stringAccessor", "booleanAccessor", "dateAccessor", "arrayAccessor", "objectAccessor", "dbrefAccessor");

    # Has helper keywords from MongoDB::Simple
    can_ok($obj, "database", "collection", "parent", "string", "date", "dbref", "boolean", "array", "object");

    # Has methods declared with keywords
    can_ok($obj, "name", "created", "available", "tags", "metadata", "labels");
};

subtest 'Accessors' => sub {
    plan tests => 13;

    my $obj = new MongoDB::Simple::Test;

    is($obj->name, undef, 'String is undef');
    $obj->name('Test name');
    is($obj->name, 'Test name', 'String has been changed');

    is($obj->created, undef, 'Date is undef');
    my $dt = DateTime->now;
    $obj->created($dt);
    is($obj->created, $dt, 'Date has been changed');

    is($obj->available, undef, 'Boolean is undef');
    $obj->available(true);
    is($obj->available, true, 'Boolean has been changed');

    is($obj->tags, undef, 'Array is undefined');

    is($obj->metadata, undef, 'Object is undef');
    my $meta = new MongoDB::Simple::Test::Meta;
    $obj->metadata($meta);
    is($obj->metadata, $meta, 'Object has been changed');

    my $label = new MongoDB::Simple::Test::Label;
    $obj->labels([]);
    is(scalar @{$obj->labels}, 0, 'Array length is zero');
    like(ref($obj->labels), qr/ARRAY/, 'Array is array reference');
    push $obj->labels, $label;
    is(scalar @{$obj->labels}, 1, 'Array length is 1');
    is($obj->labels->[0], $label, 'Array contains object');
};

subtest 'Insert a document' => sub {
    plan tests => 2;

    SKIP: {
        skip 'MongoDB connection required for test', 2 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        is(ref($id), 'MongoDB::OID', 'Save returned MongoDB::OID');

        my $doc = $client->get_database('mtest')->get_collection('items')->find_one({'_id' => $id});
        is_deeply($doc, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag1', 'tag2'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver');
    }
};

subtest 'Fetch a document' => sub {
    plan tests => 13;

    SKIP: {
        skip 'MongoDB connection required for test', 13 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        my $obj = new MongoDB::Simple::Test(client => $client);
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');

        is($obj->name, 'Test name', 'Name retrieved');
        is($obj->created, $dt, 'Date retrieved');
        is($obj->available, true, 'Boolean retrieved');
        is_deeply($obj->tags, ['tag1','tag2'], 'Array retrieved');
        is($obj->tags->[0], 'tag1', 'Array item[0] retrieved');
        is($obj->tags->[1], 'tag2', 'Array item[1] retrieved');
        is_deeply($obj->metadata->{doc}, $meta->{doc}, 'Object retrieved');
        is($obj->metadata->type, 'meta type', 'Object property retrieved');
        is(ref $obj->metadata, 'MongoDB::Simple::Test::Meta', 'Typed object retrieved');
        is(ref $obj->labels->[0], 'MongoDB::Simple::Test::Label', 'Typed array item[0] retrieved');
        is($obj->labels->[0]->text, 'test label', 'Typed array item[0] string retrieved');
        is_deeply($obj->attr, { key1 => 'key 1', key2 => 'key 2' }, 'Anonymous object retrieved');
    }
};
