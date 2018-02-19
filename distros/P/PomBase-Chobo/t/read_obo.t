use strict;
use warnings;
use Test::More tests => 26;
use Test::Deep;

use PomBase::Chobo::ParseOBO;

my $parser = PomBase::Chobo::ParseOBO->new();

my $ontology_data = PomBase::Chobo::OntologyData->new();

$parser->parse(filename => 't/data/mini_test_fypo.obo',
               ontology_data => $ontology_data);

is ($ontology_data->get_terms(), 26);

my $lookup_name = 'elongated multinucleate cells';
my $lookup_id = 'FYPO:0000133';

my @fypo_0000133_terms = $ontology_data->get_terms_by_name($lookup_name);
is (@fypo_0000133_terms, 1);
my $fypo_0000133 = $fypo_0000133_terms[0];

is ($fypo_0000133->name(), $lookup_name);
is ($fypo_0000133->id(), $lookup_id);

cmp_deeply ([$fypo_0000133->subsets()], []);

$fypo_0000133 = $ontology_data->get_term_by_id($lookup_id);

is ($fypo_0000133->name(), $lookup_name);
is ($fypo_0000133->id(), $lookup_id);
is ($fypo_0000133->def()->{definition}, 'A cell phenotype in which cells contain more than one nucleus apiece and are elongated.');
cmp_deeply ($fypo_0000133->def()->{dbxrefs}, ['PomBase:mah', 'PMID:12381658']);
is ($fypo_0000133->comment(), 'Test comment.');

is ($ontology_data->get_namespaces(), 2);

is ($ontology_data->get_metadata_by_namespace("fission_yeast_phenotype")->{ontology}, 'fypo');

my @cv_names = sort $ontology_data->get_cv_names();

cmp_deeply(\@cv_names, ['external_cv', 'fission_yeast_phenotype']);

my @db_names = sort $ontology_data->get_db_names();

cmp_deeply(\@db_names, ['EXT', 'FYPO', 'PATO', 'PMID', 'PomBase', '_global']);

my @fypo_cvterms = $ontology_data->get_terms_by_cv_name('fission_yeast_phenotype');

is (@fypo_cvterms, 25);

my @fypo_relationships = grep { $_->is_relationshiptype(); } @fypo_cvterms;
is (@fypo_relationships, 5);

my @fypo_non_relationships = grep { !$_->is_relationshiptype(); } @fypo_cvterms;
is (@fypo_non_relationships, 20);

my @rels = sort {
  $a->[0] cmp $b->[0]
    ||
  $a->[1] cmp $b->[1]
    ||
  $a->[2] cmp $b->[2]
} $ontology_data->relationships();

is(@rels, 27);

cmp_deeply([@rels[0..2]], [
  ['FYPO:0000002', 'is_a', 'FYPO:0000001'],
  ['FYPO:0000005', 'is_a', 'FYPO:0000136'],
  ['FYPO:0000013', 'is_a', 'FYPO:0000005'],
]);


my $single_term_ontology_data = PomBase::Chobo::OntologyData->new();

$parser->parse(filename => 't/data/single_term.obo',
               ontology_data => $single_term_ontology_data);
$parser->parse(filename => 't/data/single_term.obo',
               ontology_data => $single_term_ontology_data);

is ($single_term_ontology_data->get_terms(), 1);


my $dodgy_term_ontology_data = PomBase::Chobo::OntologyData->new();

# check term with double quote in the name
$parser->parse(filename => 't/data/mini_go.obo',
               ontology_data => $dodgy_term_ontology_data);

is ($dodgy_term_ontology_data->get_terms(), 2);

my @dodgy_terms = sort map {
  $_->{name}
} $dodgy_term_ontology_data->get_terms();

cmp_deeply(\@dodgy_terms,
           [
             'cyanidin 3-O-glucoside-(2"-O-xyloside) 6\'\'-O-acyltransferase activity',
             'molecular_function'
           ]);


# test ->subsets() and ->synonyms()
my $fypo_0001320 = $ontology_data->get_term_by_id('FYPO:0001320');

is ($fypo_0001320->name(), 'vegetative cell phenotype');
is ($fypo_0001320->id(), 'FYPO:0001320');

cmp_deeply([sort $fypo_0001320->subsets()],
           ['qc_do_not_annotate', 'qc_do_not_manually_annotate']);

my @expected_synonyms =
  (
    {
      'synonym' => 'cell phenotype during vegetative growth',
      'scope' => 'NARROW',
      'dbxrefs' => []
    },
    {
      'dbxrefs' => [
        'PomBase:mah'
      ],
      'scope' => 'RELATED',
      'synonym' => 'fission yeast vegetative cell phenotype'
    },
    {
      'synonym' => 'vegetative cell phenotype during vegetative growth',
      'scope' => 'EXACT',
      'dbxrefs' => [
        'PomBase:mah'
      ]
    },
    {
      'scope' => 'EXACT',
      'type' => 'A_TYPE',
      'dbxrefs' => [
        'PomBase:mah'
      ],
      'synonym' => 'vegetative cell phenotype in vegetative growth'
    },
  );

  cmp_deeply(\@expected_synonyms,
             [sort { $a->{synonym} cmp $b->{synonym} } $fypo_0001320->synonyms()]);
