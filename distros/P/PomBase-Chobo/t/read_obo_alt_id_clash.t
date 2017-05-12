use strict;
use warnings;
use Test::More tests => 1;
use Test::Deep;
use Try::Tiny;

use PomBase::Chobo::ParseOBO;

my $parser = PomBase::Chobo::ParseOBO->new();

my $ontology_data = PomBase::Chobo::OntologyData->new();

$parser->parse(filename => 't/data/mini_test_fypo.obo',
               ontology_data => $ontology_data);
use Capture::Tiny qw(capture);

my ($stdout, $stderr, $exit) = capture {
  $parser->parse(filename => 't/data/bogus_alt_id_fypo.obo',
                 ontology_data => $ontology_data);
};

like ($stderr, qr/name" tag of this stanza .* differs from previously/);
