use strict;
use warnings;
use Test::More tests => 1;
use Test::Deep;
use Try::Tiny;
use Capture::Tiny qw(capture);

# test for failure when an alt_id matches an obsolete term
# See: https://github.com/pombase/pombase-chado/issues/1178

use PomBase::Chobo::ParseOBO;

my $parser = PomBase::Chobo::ParseOBO->new();

my $ontology_data = PomBase::Chobo::OntologyData->new();

my ($stdout, $stderr, $exit) = capture {
  $parser->parse(filename => 't/data/mondo_alt_bug.obo',
                 ontology_data => $ontology_data);
};

$parser->parse(filename => 't/data/mini_go.obo',
               ontology_data => $ontology_data);

is ($ontology_data->get_terms(), 4);
