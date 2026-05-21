package Pheno::Ranker::Compare::Prune;

use strict;
use warnings;

use List::Util qw(any);

use Exporter 'import';
our @EXPORT_OK =
  qw(prune_excluded_included set_excluded_phenotypicFeatures prune_keys_with_weight_zero);

sub prune_excluded_included {
    my ( $hash, $self ) = @_;
    my @included = @{ $self->{include_terms} };
    my @excluded = @{ $self->{exclude_terms} };

    # Die if we have both options at the same time
    die "Sorry, <--include> and <--exclude> are mutually exclusive\n"
      if ( @included && @excluded );

    # *** IMPORTANT ***
    # Original $hash is modified

    # INCLUDED
    if (@included) {
        for my $key ( keys %$hash ) {
            delete $hash->{$key} unless any { $_ eq $key } @included;
        }
    }

    # EXCLUDED
    if (@excluded) {
        for my $key (@excluded) {
            delete $hash->{$key} if exists $hash->{$key};
        }
    }

    # We will do nothing if @included = @excluded = [] (DEFAULT)
    return 1;
}

sub set_excluded_phenotypicFeatures {
    my ( $hash, $switch, $format ) = @_;

    # Ensure phenotypicFeatures exist before processing
    return 1 unless exists $hash->{phenotypicFeatures};

    foreach my $feature ( @{ $hash->{phenotypicFeatures} } ) {

        # Skip if 'excluded' is not set or false
        next unless $feature->{excluded};

        # NB: remaining phenotypicFeatures:1.excluded
        #     will be discarded by $exclude_variables_regex_qr later
        if ($switch) {

            # Determine the correct ID field based on the format
            my $id_field = $format eq 'BFF' ? 'featureType' : 'type';

            # Append '_excluded' to the appropriate ID
            $feature->{$id_field}{id} .= '_excluded';
        }
        else {
            # Remove the feature by setting it to undef
            $feature = undef;

  # Due to properties being set to undef, it's possible for the coverage file to
  # report phenotypicFeatures as 100% by all "excluded" = true
        }
    }

    return 1;
}

sub prune_keys_with_weight_zero {
    my $hash_ref = shift;

    # Iterate over the keys of the hash
    foreach my $key ( keys %{$hash_ref} ) {

        # Delete the key if its value is 0
        delete $hash_ref->{$key} if $hash_ref->{$key} == 0;
    }
}

1;
