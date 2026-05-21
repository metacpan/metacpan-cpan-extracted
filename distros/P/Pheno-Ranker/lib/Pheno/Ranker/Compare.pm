package Pheno::Ranker::Compare;

use strict;
use warnings;
use autodie;
use Pheno::Ranker::Compare::Alignment qw(create_alignment recreate_array);
use Pheno::Ranker::Compare::Encoding
  qw(create_binary_digit_string binary_to_base64 _base64_to_binary);
use Pheno::Ranker::Compare::Matrix qw(cohort_comparison);
use Pheno::Ranker::Compare::Ontology qw(parse_hpo_json);
use Pheno::Ranker::Compare::Prepare ();
use Pheno::Ranker::Compare::Prune
  qw(prune_excluded_included set_excluded_phenotypicFeatures prune_keys_with_weight_zero);
use Pheno::Ranker::Compare::Rank ();
use Pheno::Ranker::Compare::Remap qw(add_id2key guess_label);

use Exporter 'import';
our @EXPORT =
  qw(check_format cohort_comparison compare_and_rank create_glob_and_ref_hashes randomize_variables remap_hash create_binary_digit_string parse_hpo_json);

use constant DEVEL_MODE => 0;

our %nomenclature = ();

sub add_hpo_ascendants {
    return Pheno::Ranker::Compare::Ontology::add_hpo_ascendants(
        @_,
        \%nomenclature
    );
}

sub remap_hash {
    my $arg = shift;
    $arg->{nomenclature} ||= \%nomenclature;
    return Pheno::Ranker::Compare::Remap::remap_hash($arg);
}

sub compare_and_rank {
    my $arg = shift;
    $arg->{nomenclature} ||= \%nomenclature;
    return Pheno::Ranker::Compare::Rank::compare_and_rank($arg);
}

sub create_glob_and_ref_hashes {
    my ( $array, $weight, $self, $nomenclature ) = @_;
    $nomenclature ||= \%nomenclature;
    return Pheno::Ranker::Compare::Prepare::create_glob_and_ref_hashes(
        $array, $weight, $self, $nomenclature
    );
}

sub randomize_variables {
    return Pheno::Ranker::Compare::Prepare::randomize_variables(@_);
}

sub check_format {
    my $data = shift;
    return exists $data->[0]{subject} ? 'PXF' : 'BFF';
}

1;
