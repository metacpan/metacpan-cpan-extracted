#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use SBOM::CycloneDX;
use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Component;

my $bom = SBOM::CycloneDX->new(spec_version => 1.6);

$bom->components->push(SBOM::CycloneDX::Component->new(
    type        => 'library',
    name        => 'license-with-no-id-nor-name',
    version     => '23',
    description => 'testcase for issue#288',
    licenses    => [SBOM::CycloneDX::License->new]
));

diag 'CycloneDX 1.6 - Invalid License Missing ID and Name', "\n", "$bom";

isnt "$bom", '';

is $bom->spec_version, 1.6;

my @errors = $bom->validate;

isnt scalar @errors, 0;

done_testing();

__DATA__
{
  "$schema": "http://cyclonedx.org/schema/bom-1.6.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79",
  "version": 1,
  "components": [
    {
      "type": "library",
      "name": "license-with-no-id-nor-name",
      "version": "23",
      "description": "testcase for issue#288",
      "licenses": [
        {
          "license": {}
        }
      ]
    }
  ]
}
