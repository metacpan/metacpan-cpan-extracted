package Pheno::Ranker::Compare::Prepare;

use strict;
use warnings;
use feature qw(say);

use List::Util qw(shuffle);
use Pheno::Ranker::Compare::Prune qw(prune_keys_with_weight_zero);
use Pheno::Ranker::Compare::Remap qw(remap_hash);

use Exporter 'import';
our @EXPORT_OK = qw(create_glob_and_ref_hashes randomize_variables);

sub create_glob_and_ref_hashes {
    my ( $array, $weight, $self, $nomenclature ) = @_;
    my $primary_key = $self->{primary_key};
    my $glob_hash   = {};
    my $ref_hash_flattened;

    my $count = 1;
    for my $element ( @{$array} ) {

        # For consistency, we obtain the primary_key for both BFF/PXF
        # from $_->{id} (not from subject.id)
        my $id = $element->{$primary_key}
          or die
"Sorry but the JSON document [$count] does not have the primary_key <$primary_key> defined\n";

        # Remapping hash
        say "Flattening and remapping <id:$id> ..." if $self->{verbose};

        my $ref_hash = remap_hash(
            {
                hash         => $element,
                weight       => $weight,
                self         => $self,
                nomenclature => $nomenclature,
            }
        );

        # *** IMPORTANT ***
        # We eliminate keys with weight = 0 if defined $weight;
        prune_keys_with_weight_zero($ref_hash) if defined $weight;

        # Load big hash ref_hash_flattened
        $ref_hash_flattened->{$id} = $ref_hash;

        # The idea is to create a $glob_hash with unique key-values
        # Duplicates will be automatically merged
        $glob_hash = { %$glob_hash, %$ref_hash };

        # To keep track of array element indexes
        $count++;
    }
    return ( $glob_hash, $ref_hash_flattened );
}

sub randomize_variables {
    my ( $glob_hash, $self ) = @_;
    my $max  = $self->{max_number_vars};
    my $seed = $self->{seed};

    # set random seed
    srand($seed);

    # Randomize
    # NB:keys have to be sorted for srand to work!!!!
    # perl -MList::Util=shuffle -E 'srand 123; say shuffle 1 .. 5'
    my @items = ( shuffle sort keys %$glob_hash )[ 0 .. $max - 1 ];

    # Create a new hash with a hash slice
    my %new_glob_hash;
    @new_glob_hash{@items} = @{$glob_hash}{@items};

    # return reference
    return \%new_glob_hash;
}

1;
