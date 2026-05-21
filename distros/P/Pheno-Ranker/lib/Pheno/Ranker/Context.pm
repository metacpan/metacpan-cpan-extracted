package Pheno::Ranker::Context;

use strict;
use warnings;

use Moo;

my @FIELDS = qw(
  age align array_regex_qr array_terms_regex_qr config_file debug
  exclude_terms exclude_variables_regex_qr format id_correspondence
  graph_max_weight graph_min_weight include_terms max_matrix_records_in_ram
  matrix_format max_number_vars max_out
  nodes edges out_file primary_key retain_excluded_phenotypicFeatures
  seed similarity_metric_cohort sort_by verbose
);

has \@FIELDS => ( is => 'ro' );

sub from_ranker {
    my ( $class, $ranker ) = @_;
    my %context = map { $_ => $ranker->{$_} } grep { exists $ranker->{$_} } @FIELDS;
    return $class->new(%context);
}

1;
