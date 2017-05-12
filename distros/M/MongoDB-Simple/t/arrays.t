#!/usr/bin/perl

use Test::More tests => 4;
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

subtest 'Update a document - scalar arrays' => sub {
    plan tests => 6;

    SKIP: {
        skip 'MongoDB connection required for test', 6 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        my $obj = new MongoDB::Simple::Test(client => $client);
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');

        is_deeply($obj->{doc}, {
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
        }, 'Correct document returned by MongoDB driver after makeNewObject');

        for(my $i = 0; $i < 5; $i++) { 
            push $obj->tags, 'new tag ' . ($i+1);;
        }
        is(scalar @{$obj->tags}, 7, 'New items are in array');
        $obj->save;
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');
        is(scalar @{$obj->tags}, 7, 'New items can be retrieved from array');

        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag1', 'tag2', 'new tag 1', 'new tag 2', 'new tag 3', 'new tag 4', 'new tag 5'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                { "text" => 'test label' }
            ]
        }, 'Correct document returned by MongoDB driver after adding item to scalar array');
    }
};

subtest 'Update a document - scalar array operators' => sub {
    plan tests => 9;

    SKIP: {
        skip 'MongoDB connection required for test', 9 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;
        my $obj = new MongoDB::Simple::Test(client => $client);
        $obj->load($id);
        push $obj->tags, 'Push test';
        $obj->save;
        $obj->load($id);
        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag1', 'tag2', 'Push test'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver after makeNewObject');

     
        # Tests the behaviour that unshift actually implements
        # i.e., that unshift behaves like push
        ($id, $dt, $meta, $label) = makeNewObject;
        $obj->load($id);
        warning_is { unshift $obj->tags, 'Unshift test'; } 'unshift on MongoDB::Simple::ArrayType behaves like push (including callbacks - \'pop\' is called instead of \'unshift\'). you can disable this warning by setting \'warnOnUnshiftOperator\'', 'Use of unshift without forceUnshiftOperator generates warning';
        $obj->save;
        $obj->load($id);
        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag1', 'tag2', 'Unshift test'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver after array unshift (as push)');

        $obj->{warnOnUnshiftOperator} = 0;
        warning_is { unshift $obj->tags, 'Unshift test'; } undef, 'Use of unshift with warnOnUnshiftOperator disabled generates no warnings';
        $obj->{warnOnUnshiftOperator} = 1;

        # Test the force array unshift option, which basically rewrites the
        # entire array in mongodb to get the item at the start
        ($id, $dt, $meta, $label) = makeNewObject;
        $obj->load($id);
        $obj->{forceUnshiftOperator} = 1;
        unshift $obj->tags, 'Unshift test';
        $obj->save;
        $obj->{forceUnshiftOperator} = 0;
        $obj->load($id);
        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['Unshift test', 'tag1', 'tag2'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver after unshift (forceUnshiftOperator)');

        ($id, $dt, $meta, $label) = makeNewObject;
        $obj->load($id);
        my $tag = pop $obj->tags;
        $obj->save;
        $obj->load($id);
        is($tag, 'tag2', 'Correct tag popped off array');
        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag1'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver after array pop');

        ($id, $dt, $meta, $label) = makeNewObject;
        $obj->load($id);
        my $tag2 = shift $obj->tags;
        $obj->save;
        $obj->load($id);
        is($tag2, 'tag1', 'Correct tag shifted from array');
        is_deeply($obj->{doc}, {
            "_id" => $id,
            "name" => 'Test name',
            "created" => DateTime::Format::W3CDTF->parse_datetime($dt),
            "available" => true,
            "attr" => { key1 => 'key 1', key2 => 'key 2' },
            "tags" => ['tag2'],
            "metadata" => {
                "type" => 'meta type'
            },
            "labels" => [
                {
                    "text" => 'test label'
                }
            ]
        }, 'Correct document returned by MongoDB driver after array shift');
    }
};

subtest 'Update a document - typed arrays' => sub {
    plan tests => 8;

    SKIP: {
        skip 'MongoDB connection required for test', 8 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        my $obj = new MongoDB::Simple::Test(client => $client);
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');

        is_deeply($obj->{doc}, {
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
        }, 'Correct document returned by MongoDB driver after makeNewObject');

        my @labels = ();
        for(my $i = 0; $i < 5; $i++) { 
            my $l = new MongoDB::Simple::Test::Label;
            $l->text('Label ' . ($i+1));
            push @labels, $l;
        }
        push $obj->labels, @labels;
        is(scalar @{$obj->labels}, 6, 'New items are in array');
        $obj->save;
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');
        is(scalar @{$obj->labels}, 6, 'New items can be retrieved');
        is(ref $obj->labels->[3], 'MongoDB::Simple::Test::Label', 'Retrieved object has correct type');
        is_deeply($obj->{doc}, {
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
                { "text" => 'test label' },
                { "text" => 'Label 1' },
                { "text" => 'Label 2' },
                { "text" => 'Label 3' },
                { "text" => 'Label 4' },
                { "text" => 'Label 5' },
            ]
        }, 'Correct document returned by MongoDB driver after typed array push');

        $obj->labels->[1]->text('Updated label');
        $obj->save;
        $obj->load($id);
        is($obj->labels->[1]->text, 'Updated label', 'Scalar values in typed array items are updated');
    }
};

subtest 'Identify correct document type in array' => sub {
    plan tests => 7;

    SKIP: {
        skip 'MongoDB connection required for test', 7 if !$client;

        my ($id, $dt, $meta, $label) = makeNewObject;

        my $obj = new MongoDB::Simple::Test(client => $client);
        $obj->load($id);
        is($obj->hasChanges, 0, 'Loaded document has no changes');

        is_deeply($obj->{doc}, {
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
        }, 'Correct document returned by MongoDB driver after makeNewObject');

        my $label1 = new MongoDB::Simple::Test::Label;
        $label1->text('Label test');
        my $meta1 = new MongoDB::Simple::Test::Meta;
        $meta1->type('Meta test');
        $obj->multi([]);
        push $obj->multi, $label1, $meta1;
        $obj->save;
        $obj->load($id);

        is(scalar @{$obj->multi}, 2, 'Both objects were saved in array');
        is(ref $obj->multi->[0], 'MongoDB::Simple::Test::Label', 'First object is correct type');
        is(ref $obj->multi->[1], 'MongoDB::Simple::Test::Meta', 'Second object is correct type');

        is_deeply($obj->{doc}, {
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
            ],
            "multi" => [
                { "text" => 'Label test' },
                { "type" => 'Meta test' },
            ],
        }, 'Correct document returned by MongoDB driver after multi-type array push');

        $obj->multi->[0]->text('New label test');
        $obj->save;
        $obj->load($id);
        is($obj->multi->[0]->text, 'New label test', 'String inside object inside array is updated');
    }
};
