package Pheno::Ranker::Compare::Ontology;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(add_hpo_ascendants parse_hpo_json);

use constant DEVEL_MODE => 0;

sub add_hpo_ascendants {
    my ( $key, $nodes, $edges, $nomenclature ) = @_;
    $nomenclature ||= {};

    # First we obtain the ontology (0000539) from HP:0000539
    $key =~ m/HP:(\w+)$/;
    my $ontology = $1;

    # We'll use it to build a string equivalent to a key from $edges
    my $hpo_url = 'http://purl.obolibrary.org/obo/HP_';
    my $hpo_key = $hpo_url . $ontology;

    # We will include all ascendants in an array
    my @ascendants;
    for my $parent_id ( @{ $edges->{$hpo_key} } ) {

        # We have to create a copy to not modify the original $parent_id
        # as it can appear in multiple individuals
        my $copy_parent_id = $parent_id;
        $copy_parent_id =~ m/\/(\w+)$/;
        $copy_parent_id = $1;
        $copy_parent_id =~ tr/_/:/;

# *** IMPORTANT ***
# We cannot add any label to the ascendants, otherwise they will
# not be matched by an indv down the tree
# Myopia
# Mild Myopia
# We want that 'Mild Myopia' matches 'Myopia', thus we can not add a label from 'Mild Myopia'
# Use the labels only for debug
        my $asc_key = DEVEL_MODE ? $key . '.HPO_asc_DEBUG_ONLY' : $key;
        $asc_key =~ s/HP:$ontology/$copy_parent_id/g;
        push @ascendants, $asc_key;

        # We finally add the label to %nomenclature
        my $hpo_asc_str = $hpo_url
          . $copy_parent_id;    # 'http://purl.obolibrary.org/obo/HP_HP:0000539
        $hpo_asc_str =~ s/HP://;    # 0000539
        $nomenclature->{$asc_key} = $nodes->{$hpo_asc_str}{lbl};
    }
    return \@ascendants;
}

sub parse_hpo_json {
    my $data = shift;

# The <hp.json> file is a structured representation of the Human Phenotype Ontology (HPO) in JSON format.
# The HPO is structured into a directed acyclic graph (DAG)
# Here's a brief overview of the structure of the hpo.json file:
# - graphs: This key contains an array of ontology graphs. In the case of HPO, there is only one graph. The graph has two main keys:
# - nodes: An array of objects, each representing an HPO term. Each term object has the following keys:
# - id: The identifier of the term (e.g., "HP:0000118").
# - lbl: The label (name) of the term (e.g., "Phenotypic abnormality").
# - meta: Metadata associated with the term, including definition, synonyms, and other information.
# - type: The type of the term, usually "CLASS".
# - edges: An array of objects, each representing a relationship between two HPO terms. Each edge object has the following keys:
# - sub: The subject (child) term ID (e.g., "HP:0000924").
# - obj: The object (parent) term ID (e.g., "HP:0000118").
# - pred: The predicate that describes the relationship between the subject and object terms, typically "is_a" in HPO.
# - meta: This key contains metadata about the HPO ontology as a whole, such as version information, description, and other details.

    my $graph = $data->{graphs}->[0];
    my %nodes = map { $_->{id} => $_ } @{ $graph->{nodes} };
    my %edges = ();

    for my $edge ( @{ $graph->{edges} } ) {
        my $child_id  = $edge->{sub};
        my $parent_id = $edge->{obj};
        push @{ $edges{$child_id} }, $parent_id;
    }
    return \%nodes, \%edges;
}

1;
