#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom is_valid_bom);

use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::Component::SWID;

for my $spec_version (qw[1.2 1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Component SWID" => sub {

        my $bom_test_data = bom_test_data('valid-component-swid', $spec_version);

        my $bom = bom_spec($spec_version);

        $bom->components->add(SBOM::CycloneDX::Component->new(
            type    => 'application',
            author  => 'Acme Super Heros',
            name    => 'Acme Application',
            version => '9.1.1',
            swid    => SBOM::CycloneDX::Component::SWID->new(
                tag_id  => 'swidgen-242eb18a-503e-ca37-393b-cf156ef09691_9.1.1',
                name    => 'Acme Application',
                version => '9.1.1'
            )
        ));

        is_bom $bom;
        is $bom->spec_version, $spec_version;
        is_valid_bom $bom;
        is_deeply $bom->to_hash, $bom_test_data;

    };

}

done_testing();
