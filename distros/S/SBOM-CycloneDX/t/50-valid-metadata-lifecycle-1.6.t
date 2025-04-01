#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_1_6 bom_test_data);

use SBOM::CycloneDX::Metadata::Lifecycle;


my $bom_test_data = bom_test_data(__FILE__);
delete $bom_test_data->{components};    # Remove empty components

my $bom = bom_1_6();

$bom->metadata->lifecycles->add(
    SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'build'),
    SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'post-build'),
    SBOM::CycloneDX::Metadata::Lifecycle->new(
        name        => 'platform-integration-testing',
        description => 'Integration testing specific to the runtime platform'
    )
);

diag 'CycloneDX 1.6 - Valid Metadata Author', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

diag $_ for @errors;

is scalar @errors, 0;

is_deeply $bom->to_hash, $bom_test_data;

done_testing();
