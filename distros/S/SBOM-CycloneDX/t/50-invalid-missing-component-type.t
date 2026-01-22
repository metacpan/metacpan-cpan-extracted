#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom isnt_valid_bom);

use SBOM::CycloneDX;
use SBOM::CycloneDX::Component;

for my $spec_version (qw[1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Invalid Missing Component Type" => sub {

        my $bom_test_data = bom_test_data('invalid-missing-component-type', $spec_version);

        my $bom = bom_spec($spec_version);

        eval { $bom->components->push(SBOM::CycloneDX::Component->new(name => 'acme-library', version => '1.0.0')) };

        isnt $@, '';
        diag $@;
        is_bom $bom;
        is $bom->spec_version, $spec_version;

    };

}

done_testing();
