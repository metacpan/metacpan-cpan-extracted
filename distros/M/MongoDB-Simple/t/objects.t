#!/usr/bin/perl

use Test::More tests => 2;
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

subtest 'Update a document - objects' => sub {
    plan tests => 5;

    SKIP: {
        skip 'MongoDB connection required for test', 5 if !$client;

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
        }, 'Correct document returned by MongoDB driver');
       
        $obj->metadata->type('new meta type');
        $obj->save;
        $obj->load($id);
        is($obj->metadata->type, 'new meta type', 'String inside object is updated');

        my $label2 = new MongoDB::Simple::Test::Label;
        $label2->text('test label');
        $obj->metadata->label($label2);
        $obj->save;
        $obj->load($id);
        is($obj->metadata->label->text, 'test label', 'String inside object inside object is set');

        $obj->metadata->label->text('new label');
        $obj->save;
        $obj->load($id);
        is($obj->metadata->label->text, 'new label', 'String inside object inside object is updated');
    }
};

subtest 'Update a document - hash objects' => sub {
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
        }, 'Correct document returned by MongoDB driver');
       
        $obj->hash({
            'type' => 'plain',
            'size' => 230,
            'expires' => 3600
        });
        $obj->save;
        $obj->load($id);
        is(ref $obj->hash, 'HASH', 'Object set to hash');

        $obj->hash->{type} = 'spotted';
        $obj->save;
        $obj->load($id);
        is($obj->hash->{type}, 'spotted', 'String inside a hash is updated');

        $obj->hash->{info}->{cake}->{panda} = 1;
        $obj->save;
        $obj->load($id);
        is($obj->hash->{info}->{cake}->{panda}, 1, 'Nested hash values can be set');

        $obj->hash->{info}->{cake}->{panda} = 2;
        $obj->save;
        $obj->load($id);
        is($obj->hash->{info}->{cake}->{panda}, 2, 'Nested hash values can be updated');

        $obj->hash->{test}->{array} = [];
        push $obj->hash->{test}->{array}, 'Inner push';
        $obj->save;
        $obj->load($id);
        is($obj->hash->{test}->{array}->[0], 'Inner push', 'Arrays nested in hashes can be set');

        $obj->hash->{test}->{array}->[0] = 'Inner update';
        $obj->save;
        $obj->load($id);
        is($obj->hash->{test}->{array}->[0], 'Inner update', 'Arrays nested in hashes can be updated');
    }
};
