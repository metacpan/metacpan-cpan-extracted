#!perl

use strict;
use warnings;
use v5.10;

use Test::More;

use SBOM::CycloneDX;

my @SPEC_VERSIONS = qw[1.2 1.3 1.4 1.5 1.6 1.7];

for my $spec_version (@SPEC_VERSIONS) {

    my $bom = SBOM::CycloneDX->new(spec_version => $spec_version);

    diag 'CycloneDX ', $bom->spec_version, "\n";

    isnt "$bom", '';

    is $bom->spec_version, $spec_version;

    my @errors = $bom->validate;

    diag $_ for @errors;

    is scalar @errors, 0;

}


done_testing();
