package SBOM::CycloneDX::Enum::CryptoCertificationLevel;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        NONE         => 'none',
        FIPS140_1_L1 => 'fips140-1-l1',
        FIPS140_1_L2 => 'fips140-1-l2',
        FIPS140_1_L3 => 'fips140-1-l3',
        FIPS140_1_L4 => 'fips140-1-l4',
        FIPS140_2_L1 => 'fips140-2-l1',
        FIPS140_2_L2 => 'fips140-2-l2',
        FIPS140_2_L3 => 'fips140-2-l3',
        FIPS140_2_L4 => 'fips140-2-l4',
        FIPS140_3_L1 => 'fips140-3-l1',
        FIPS140_3_L2 => 'fips140-3-l2',
        FIPS140_3_L3 => 'fips140-3-l3',
        FIPS140_3_L4 => 'fips140-3-l4',
        CC_EAL1      => 'cc-eal1',
        CC_EAL1_PLUS => 'cc-eal1+',
        CC_EAL2      => 'cc-eal2',
        CC_EAL2_PLUS => 'cc-eal2+',
        CC_EAL3      => 'cc-eal3',
        CC_EAL3_PLUS => 'cc-eal3+',
        CC_EAL4      => 'cc-eal4',
        CC_EAL4_PLUS => 'cc-eal4+',
        CC_EAL5      => 'cc-eal5',
        CC_EAL5_PLUS => 'cc-eal5+',
        CC_EAL6      => 'cc-eal6',
        CC_EAL6_PLUS => 'cc-eal6+',
        CC_EAL7      => 'cc-eal7',
        CC_EAL7_PLUS => 'cc-eal7+',
        OTHER        => 'other',
        UNKNOWN      => 'unknown',
    );

    require constant;
    constant->import(\%ENUM);

    @EXPORT_OK   = sort keys %ENUM;
    %EXPORT_TAGS = (all => \@EXPORT_OK);

}

sub values { sort values %ENUM }


1;
