use strict;
use Test::Most;
use CHI;

my $datastore = {};

{
    package MyDoc;
    use Moose;
    use MooseX::Storage;

    with Storage(io => [ 'CHI' => {
        key_attr   => 'doc_id',
        key_prefix => 'mydoc-',
        cache_args => {
            driver    => 'Memory',
            datastore => $datastore,
        },
        expires_in => 10,
    }]);

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
    has 'body'    => (is => 'rw', isa => 'Str');
    has 'tags'    => (is => 'rw', isa => 'ArrayRef');
    has 'authors' => (is => 'rw', isa => 'HashRef');
}

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
        ),
    ),
    'retrieved document looks good',
);

my $cache = CHI->new(
    driver    => 'Memory',
    datastore => $datastore,
);

ok $cache->is_valid('mydoc-foo12'), 'stored with correct cachekey';
ok !$cache->is_valid('foo12'), 'not stored with incorrect cackekey';

done_testing;
