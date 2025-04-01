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
    type      => 'library',
    publisher => 'Acme Inc',
    group     => 'com.acme',
    name      => 'tomcat-catalina',
    version   => '9.0.14',
    licenses  => [SBOM::CycloneDX::License->new(id => 'Apache-2')]
));

diag 'CycloneDX 1.6 - Invalid License ID', "\n", "$bom";

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
      "publisher": "Acme Inc",
      "group": "com.acme",
      "name": "tomcat-catalina",
      "version": "9.0.14",
      "licenses": [
        {
          "license": {
            "id": "Apache-2"
          }
        }
      ]
    }
  ]
}
