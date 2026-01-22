#!perl

use strict;
use warnings;

use Test::More;

use_ok 'SBOM::CycloneDX::Enum';

my @ENUMS = qw[
    COMMON_EXTENSION_NAME
    COMPONENT_TYPE
    CRYPTO_ASSET_TYPE
    CRYPTO_CERTIFICATION_LEVEL
    CRYPTO_FUNCTION
    CRYPTO_IMPLEMENTATION_PLATFORM
    CRYPTO_MODE
    CRYPTO_PADDING
    CRYPTO_PRIMITIVE
    EXTERNAL_REFERENCE_TYPE
    HASH_ALGORITHM
    IMPACT_ANALYSIS_JUSTIFICATION
    IMPACT_ANALYSIS_STATE
    LICENSE_TYPE
    LIFECYCLE_PHASE
    PATENT_ASSERTION_TYPE
    PATENT_LEGAL_STATUS
    PROTOCOL_TYPE
    RELATED_CRYPTO_MATERIAL_STATE
    RELATED_CRYPTO_MATERIAL_TYPE
    TLP_CLASSIFICATION
];

for my $enum_const (@ENUMS) {
    subtest $enum_const => sub {

        my $enum_values  = SBOM::CycloneDX::Enum->values($enum_const);
        my $enum_class   = SBOM::CycloneDX::Enum->$enum_const;
        my $total_values = scalar @{$enum_values};

        use_ok($enum_class);
        isa_ok($enum_values, 'ARRAY', $enum_const);
        isnt($total_values, 0, "$total_values enum values in $enum_const / $enum_class");

    }
}

done_testing();
