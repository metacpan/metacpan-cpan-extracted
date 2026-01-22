#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom is_valid_bom);

use SBOM::CycloneDX::Metadata::Lifecycle;

for my $spec_version (qw[1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Metadata Lifecycle" => sub {

        my $bom_test_data = bom_test_data('valid-metadata-lifecycle', $spec_version);
        delete $bom_test_data->{components};    # Remove empty components

        my $bom = bom_spec($spec_version);

        $bom->metadata->lifecycles->add(
            SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'build'),
            SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'post-build'),
            SBOM::CycloneDX::Metadata::Lifecycle->new(
                name        => 'platform-integration-testing',
                description => 'Integration testing specific to the runtime platform'
            )
        );

        is_bom $bom;
        is $bom->spec_version, $spec_version;
        is_valid_bom $bom;
        is_deeply $bom->to_hash, $bom_test_data;

    };

}

done_testing();
