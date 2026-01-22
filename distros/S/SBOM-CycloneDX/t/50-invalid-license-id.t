#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom isnt_valid_bom);

use SBOM::CycloneDX;
use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Component;

for my $spec_version (qw[1.2 1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Invalid License ID" => sub {

        my $bom_test_data = bom_test_data('invalid-license-id', $spec_version);

        my $bom = bom_spec($spec_version);

        $bom->components->push(SBOM::CycloneDX::Component->new(
            type      => 'library',
            publisher => 'Acme Inc',
            group     => 'com.acme',
            name      => 'tomcat-catalina',
            version   => '9.0.14',
            licenses  => [SBOM::CycloneDX::License->new(id => 'Apache-2')]
        ));

        is_bom $bom;
        is $bom->spec_version, $spec_version;
        isnt_valid_bom $bom;

    };

}
done_testing();
