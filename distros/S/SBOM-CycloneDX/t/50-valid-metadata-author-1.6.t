#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_1_6 bom_test_data);

use SBOM::CycloneDX::License;
use SBOM::CycloneDX::OrganizationalContact;


my $bom_test_data = bom_test_data(__FILE__);
delete $bom_test_data->{components};    # Remove empty components

my $bom = bom_1_6();

$bom->metadata->authors->add(SBOM::CycloneDX::OrganizationalContact->new(
    name  => 'Samantha Wright',
    email => 'samantha.wright@example.com',
    phone => '800-555-1212'
));

diag 'CycloneDX 1.6 - Valid Metadata Author', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

diag $_ for @errors;

is scalar @errors, 0;

is_deeply $bom->to_hash, $bom_test_data;

done_testing();
