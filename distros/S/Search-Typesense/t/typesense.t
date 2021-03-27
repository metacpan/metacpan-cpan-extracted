#!/usr/bin/env perl

use lib 't/lib';
use Test::Most 'bail';
use Test::Search::Typesense;

my $test       = Test::Search::Typesense->new;
my $collection = $test->company_collection_name;
my $typesense  = $test->typesense;

#
# collection management
#

lives_ok { $typesense->collections->delete_all }
'We should be able to purge all typesense collections';

my $collections = $typesense->collections->get;
eq_or_diff $collections, [],
  '... and collections->get() should tell us we have no collections';

$typesense->collections->create( $test->company_collection_definition );

$collections = $typesense->collections->get;
is @$collections, 1, 'We should have a collection after creating it';
is $collections->[0]{name}, $collection,
  '... and it should be the collection we have created';

#
# Documents
#

my $document = {
    'id'            => '124',
    'company_name'  => 'Stark Industries',
    'num_employees' => 5215,
    'country'       => 'USA'
};
my $response = $typesense->documents->create( $collection, $document, );
eq_or_diff $response, $document,
  'We should be able to call documents->create($collection, \%document)';

$document = {
    'id'            => '125',
    'company_name'  => 'All Around the World',
    'num_employees' => 20,
    'country'       => 'France'
};
$response = $typesense->documents->upsert( $collection, $document, );
eq_or_diff $response, $document,
  'We should be able to call documents->upsert($collection, \%document) with a non-existent document';

$document = {
    'id'            => '125',
    'company_name'  => 'All Around the World',
    'num_employees' => 10,
    'country'       => 'France'
};
$response = $typesense->documents->upsert( $collection, $document );
eq_or_diff $response, $document,
  'We should be able to call documents->upsert($collection, \%document) and update an existing document';

$response = $typesense->documents->update(
    $collection, 125,
    { num_employees => 15 }
);
eq_or_diff $response, { id => 125, num_employees => 15 },
  'We should be able to documents->upsert()';

$response = $typesense->documents->delete( $collection, 125 );
my $deleted = {
    'company_name'  => 'All Around the World',
    'country'       => 'France',
    'id'            => '125',
    'num_employees' => 15
};
eq_or_diff $response, $deleted,
  'We should be able to call documents->delete($collection, $id) and delete a document';

$response = $typesense->collections->search(
    $collection,
    {
        q         => 'stark',
        query_by  => 'company_name',
        filter_by => 'num_employees:>100',
        sort_by   => 'num_employees:desc',
    }
);

is $response->{found}, 1,
  'We should have one response found from our collections->search()';
is $response->{out_of}, 1, '... out of the total number of records';
eq_or_diff $response->{hits}[0]{document},
  {
    company_name    => 'Stark Industries',
    'country'       => 'USA',
    'id'            => '124',
    'num_employees' => 5215
  },
  '... and should match the document we were expecting';

my $documents = [
    {
        "id"            => "124",
        "company_name"  => "Stark Industries",
        "num_employees" => 5215,
        "country"       => "US"
    },
    {
        "id"            => "125",
        "company_name"  => "Future Technology",
        "num_employees" => 1232,
        "country"       => "UK"
    },
    {
        "id"            => "126",
        "company_name"  => "Random Corp.",
        "num_employees" => 531,
        "country"       => "AU"
    },
];

lives_ok {
    $response
      = $typesense->documents->import( $collection, 'upsert', $documents );
}
'We should be able to import documents';

$response = $typesense->documents->export($collection);
eq_or_diff $response, $documents,
  '... and we should be able to documents->export($collection)';
$response = $typesense->documents->export('compani');
ok !defined $response,
  '... but trying to export documents from a non-existing collection should fail';

done_testing;
