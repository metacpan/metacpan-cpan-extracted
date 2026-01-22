#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_valid_bom is_bom);

use SBOM::CycloneDX::Component;

for my $spec_version (qw[1.2 1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Minimal Viable" => sub {

        my $bom_test_data = bom_test_data('valid-minimal-viable', $spec_version);

        my $bom       = bom_spec($spec_version);
        my $component = SBOM::CycloneDX::Component->new(type => 'library', name => 'acme-library');

        if ($spec_version <= 1.3) {
            $component->version('1.0.0');
        }

        $bom->components->add($component);

        is_bom $bom;
        is $bom->spec_version, $spec_version, 'Valid spec version';
        is_valid_bom($bom);
        is_deeply $bom->to_hash, $bom_test_data;

    };

}

done_testing();
