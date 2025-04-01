#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_1_6 bom_test_data);

use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Attachment;


my $bom_test_data = bom_test_data(__FILE__);
delete $bom_test_data->{components};    # Remove empty components

my $bom = bom_1_6();

$bom->metadata->licenses->add(
    SBOM::CycloneDX::License->new(id => 'Apache-2.0'),
    SBOM::CycloneDX::License->new(
        name => 'My License',
        text => SBOM::CycloneDX::Attachment->new(content => 'My License Text')
    ),
);

diag 'CycloneDX 1.6 - Valid Metadata License', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

diag $_ for @errors;

is scalar @errors, 0;

is_deeply $bom->to_hash, $bom_test_data;

done_testing();
