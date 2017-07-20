use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::More;
use Test::Deep;
use Test::Warnings;

use PawsX::DynamoDB::DocumentClient;
use UUID::Tiny ':std';

#
# This runs tests against a real DynamoDB server.
# BE AWARE THIS WILL COST YOU MONEY EVERY TIME IT RUNS.
# You'll need to create a DynamoDB table with one partition key of 'doc_id',
# and put its name in the TEST_DYNAMODB_TABLE envar.
#

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

{
    package MyDoc;
    use Moose;
    use MooseX::Storage;

    with Storage(io => [ 'AmazonDynamoDB' => {
        table_name => $table_name,
        key_attr   => 'doc_id',
    }]);

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
    has 'body'    => (is => 'rw', isa => 'Str');
    has 'tags'    => (is => 'rw', isa => 'ArrayRef');
    has 'authors' => (is => 'rw', isa => 'HashRef');
    has 'deleted_date' => (is => 'rw', isa => 'Maybe[Str]');
}

my $doc_id = create_uuid_as_string();

my $old_item = {
    __CLASS__    => 'MyDoc',
    doc_id       => $doc_id,
    authors      => '$json$v1$:{"bsmith":{"email":"bsmith@yahoo.com","name":"Bob Smith","roles":["editor","reader"]},"jdoe":{"email":"jdoe@gmail.com","name":"John Doe","roles":["author","reader"]}}',
    body         => 'blah blah',
    deleted_date => '$json$v1$:null',
    tags         => '$json$v1$:["horse","yellow","angry"]',
    title        => 'Foo',
};

my $client = PawsX::DynamoDB::DocumentClient->new();

$client->put(
    TableName => $table_name,
    Item      => $old_item,
);

my $fetched = MyDoc->load($doc_id);

cmp_deeply(
    $fetched,
    all(
        isa('MyDoc'),
        methods(
            doc_id   => $doc_id,
            title    => 'Foo',
            body     => 'blah blah',
            tags     => [qw(horse yellow angry)],
            authors  => {
                jdoe => {
                    name  => 'John Doe',
                    email => 'jdoe@gmail.com',
                    roles => [qw(author reader)],
                },
                bsmith => {
                    name  => 'Bob Smith',
                    email => 'bsmith@yahoo.com',
                    roles => [qw(editor reader)],
                },
            },
            deleted_date => undef,
        ),
    ),
    'old JSON format is deserialized correctly',
);

$fetched->store();

my $new_item = $client->get(
    TableName => $table_name,
    Key       => {
        doc_id => $doc_id,
    },
);

cmp_deeply(
    $new_item,
    {
        __CLASS__    => 'MyDoc',
        doc_id   => $doc_id,
        title    => 'Foo',
        body     => 'blah blah',
        tags     => [qw(horse yellow angry)],
        authors  => {
            jdoe => {
                name  => 'John Doe',
                email => 'jdoe@gmail.com',
                roles => [qw(author reader)],
            },
            bsmith => {
                name  => 'Bob Smith',
                email => 'bsmith@yahoo.com',
                roles => [qw(editor reader)],
            },
        },
        deleted_date => undef,
    },
    're-stored without JSON hackery',
);

done_testing;
