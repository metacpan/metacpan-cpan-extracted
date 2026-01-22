#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom is_valid_bom);

use SBOM::CycloneDX::License;
use SBOM::CycloneDX::OrganizationalContact;

for my $spec_version (qw[1.2 1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Metadata Author" => sub {

        my $bom_test_data = bom_test_data('valid-metadata-author', $spec_version);
        delete $bom_test_data->{components};    # Remove empty components

        my $bom = bom_spec($spec_version);

        $bom->metadata->authors->add(SBOM::CycloneDX::OrganizationalContact->new(
            name  => 'Samantha Wright',
            email => 'samantha.wright@example.com',
            phone => '800-555-1212'
        ));

        is_bom $bom;
        is $bom->spec_version, $spec_version;
        is_valid_bom $bom;
        is_deeply $bom->to_hash, $bom_test_data;

    };

}

done_testing();
