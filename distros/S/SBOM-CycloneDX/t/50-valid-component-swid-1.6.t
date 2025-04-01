#!perl

use strict;
use warnings;
use v5.10;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::More;
use Test::CycloneDX qw(bom_1_6 bom_test_data);

use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::Component::SWID;


my $bom_test_data = bom_test_data(__FILE__);

my $bom = bom_1_6();

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

diag 'CycloneDX 1.6 - Valid Component SWID', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

diag $_ for @errors;

is scalar @errors, 0;

is_deeply $bom->to_hash, $bom_test_data;

done_testing();
