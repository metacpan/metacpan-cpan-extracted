package    # hide from pause
    SBOM::CycloneDX::Issue::Source;

use Carp;
use Moo;
extends 'SBOM::CycloneDX::Source';

sub BUILD {
    Carp::carp 'DEPRECATED: SBOM::CycloneDX::Issue::Source, use SBOM::CycloneDX::Source instead';
}

1;

