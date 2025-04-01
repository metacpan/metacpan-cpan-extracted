#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use SBOM::CycloneDX;
use SBOM::CycloneDX::License;
use SBOM::CycloneDX::Component;

my $bom = SBOM::CycloneDX->new(spec_version => 1.6);

diag 'CycloneDX 1.6 - Invalid Missing Component Type', "\n";

eval { $bom->components->push(SBOM::CycloneDX::Component->new(name => 'acme-library', version => '1.0.0')) };

isnt $@, '';

diag $@;

isnt "$bom", '';

is $bom->spec_version, 1.6;

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
      "name": "acme-library",
      "version": "1.0.0"
    }
  ]
}
