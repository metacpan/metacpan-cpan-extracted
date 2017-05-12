use lib 't/lib';
use strict;
use Test::Most;
use Test::Warnings;

#
# This runs a basic set of tests, using a mocked DynamoDB client.
#

use TestDynamoDB;

$ENV{AWS_ACCESS_KEY_ID} = 'ABABABABABABABABABAB';
$ENV{AWS_SECRET_ACCESS_KEY} = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
$ENV{AWS_DEFAULT_REGION} = 'us-east-1';

my $table_name = 'moosex-storage-io-amazondynamodb-'.time;

{
    package MyDoc;
    use Moose;
    use MooseX::Storage;

    with Storage(io => [ 'AmazonDynamoDB' => {
        client_class => 'TestDynamoDB',
        table_name   => $table_name,
        key_attr     => 'doc_id',
    }]);

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
    has 'body'    => (is => 'rw', isa => 'Str');
    has 'tags'    => (is => 'rw', isa => 'ArrayRef');
    has 'authors' => (is => 'rw', isa => 'HashRef');
    has 'deleted_date' => (is => 'rw', isa => 'Maybe[Str]');
}

TestDynamoDB->create_table(
    table_name => $table_name,
    key_name   => 'doc_id',
);

my $doc = MyDoc->new(
    doc_id   => 'foo12',
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
);

$doc->store();

my $doc2 = MyDoc->load('foo12');

cmp_deeply(
    $doc2,
    all(
        isa('MyDoc'),
        methods(
            doc_id   => 'foo12',
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
    'retrieved document looks good',
);

done_testing;
