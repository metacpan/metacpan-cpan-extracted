#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_spec bom_test_data is_bom is_valid_bom);

use SBOM::CycloneDX::Component;

for my $spec_version (qw[1.2 1.3 1.4 1.5 1.6 1.7]) {

    subtest "CycloneDX $spec_version - Valid Dependency" => sub {

        my $bom_test_data = bom_test_data('valid-dependency', $spec_version);

        my $bom = bom_spec($spec_version);

        my %DEFAULTS = (type => 'library', version => '1.0.0');

        my $component_a = SBOM::CycloneDX::Component->new(%DEFAULTS, name => 'library-a', bom_ref => 'library-a');
        my $component_b = SBOM::CycloneDX::Component->new(%DEFAULTS, name => 'library-b', bom_ref => 'library-b');
        my $component_c = SBOM::CycloneDX::Component->new(%DEFAULTS, name => 'library-c', bom_ref => 'library-c');

        $bom->components->add($component_a);
        $bom->components->add($component_b);
        $bom->components->add($component_c);

        $bom->add_dependency($component_b, [$component_c]);

        is_bom $bom;
        is $bom->spec_version, $spec_version, 'Valid spec version';
        is_valid_bom($bom);

    TODO: {
            local $TODO = 'SBOM::CycloneDX add empty dependency entry if not exists "ref"';
            is_deeply $bom->to_hash, $bom_test_data;
        }

    };

}

done_testing();
