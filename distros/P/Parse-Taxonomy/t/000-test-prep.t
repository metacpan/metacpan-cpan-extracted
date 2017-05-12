# perl
# t/000-test-prep.t - verify presence of files needed for testing of
# Parse::Taxonomy::MaterializedPath
use strict;
use warnings;
use Test::More tests => 1;

my @dummy = qw(
  alpha.csv
  alt_path_col_sep.csv
  bad_row_count.csv
  beta.csv
  delta.csv
  duplicate_field.csv
  duplicate_header_field.csv
  duplicate_id.csv
  duplicate_path.csv
  epsilon.csv
  eta.csv
  extra_wordspace.csv
  gamma.csv
  ids_missing_parents.csv
  iota.csv
  kappa.csv
  lambda.csv
  missing_parents.csv
  mu.csv
  nameless_leaf.csv
  non_numeric_ids.csv
  non_path_col_sep_start_to_path.csv
  non_sibling_same_name.csv
  path_sibling_same_name.csv
  reserved_field_names.csv
  sibling_same_name.csv
  small_path.csv
  small_sibling_same_name.csv
  theta.csv
  wrong_row_count.csv
  zeta.csv
);

my %seen_bad;
for my $f (@dummy) {
    my $path = "./t/data/$f";
    $seen_bad{$path}++ unless (-f $path);
}
is(scalar(keys(%seen_bad)), 0,
    "Found all dummy data files needed for testing")
    or diag("Could not locate: " .
        join(' ' => sort keys %seen_bad)
);

