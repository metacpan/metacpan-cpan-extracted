use strict;
use warnings;
use Test::More tests => 3;
use Test::Deep;

use PomBase::Chobo::ParseOBO;

my $parser = PomBase::Chobo::ParseOBO->new();

my $ontology_data = PomBase::Chobo::OntologyData->new();

$parser->parse(filename => 't/data/mini_chebi.obo',
               ontology_data => $ontology_data);

$parser->parse(filename => 't/data/mini_cl.obo',
               ontology_data => $ontology_data);

# test that CHEBI:33853 merges correctly
is ($ontology_data->get_terms(), 1);


my $same_file_ontology_data = PomBase::Chobo::OntologyData->new();

$parser->parse(filename => 't/data/dodgy_ro.obo',
               ontology_data => $same_file_ontology_data);
$same_file_ontology_data->finish();


my @same_file_terms = $same_file_ontology_data->get_terms();
is (@same_file_terms, 4);

cmp_deeply([sort map { $_->name(); } @same_file_terms],
           [
             'catalytic activity',
             'continuant',
             'quality',
             'specifically dependent continuant'
           ]);
