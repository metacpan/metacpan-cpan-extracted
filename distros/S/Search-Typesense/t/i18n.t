#!/usr/bin/env perl

use utf8;
use lib 't/lib';
use Test::Most 'bail';
use Test::Search::Typesense;

my $test       = Test::Search::Typesense->new;
my $collection = $test->company_collection_name;
my $typesense  = $test->typesense;

explain <<'END';
This isn't much of a test right now. However, in the future, Typesense is
going to have an alternate tokenizer which doesn't require words to be
separated by spaces. This will allow words such as Chinese or Japanese to
work with Typesense.
END

$typesense->collections->create( $test->company_collection_definition );

#
# Documents
#

my $document = {
    'id'            => '124',
    'company_name'  => 'Stäçîa',
    'num_employees' => 5215,
    'country'       => 'USA'
};
my $response = $typesense->documents->create( $collection, $document, );
eq_or_diff $response, $document,
  'We should be able to call documents->create($collection, \%document)';

$response = $typesense->search(
    $collection,
    {
        q         => 'stacia',
        query_by  => 'company_name',
        filter_by => 'num_employees:>100',
        sort_by   => 'num_employees:desc',
    }
);

is $response->{found}, 1, 'We should have one response found from our search()';
eq_or_diff $response->{hits}[0]{document},
  {
    company_name    => 'Stäçîa',
    'country'       => 'USA',
    'id'            => '124',
    'num_employees' => 5215
  },
  '... and should match the document we were expecting';

done_testing;
