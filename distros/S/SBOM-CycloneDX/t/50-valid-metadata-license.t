#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom is_valid_bom);

use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Attachment;

for my $spec_version (qw[1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Metadata License" => sub {

        my $bom_test_data = bom_test_data('valid-metadata-license', $spec_version);
        delete $bom_test_data->{components};    # Remove empty components

        my $bom = bom_spec($spec_version);

        $bom->metadata->licenses->add(SBOM::CycloneDX::License->new(id => 'Apache-2.0'),);

        if ($spec_version >= 1.6) {

            $bom->metadata->licenses->add(SBOM::CycloneDX::License->new(
                name => 'My License',
                text => SBOM::CycloneDX::Attachment->new(content => 'My License Text')
            ));

        }

        is_bom $bom;
        is $bom->spec_version, $spec_version;
        is_valid_bom $bom;
        is_deeply $bom->to_hash, $bom_test_data;

    };

}

done_testing();
