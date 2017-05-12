#!perl -w
package RDF::SIO::Utils::Constants;
{
  $RDF::SIO::Utils::Constants::VERSION = '0.003';
}
BEGIN {
  $RDF::SIO::Utils::Constants::VERSION = '0.003';
}

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(SIO_HAS_ATTR SIO_HAS_VALUE SIO_HAS_UNIT RDF_TYPE SIO_ATTRIBUTE SIO_HAS_MEASUREMENT_VALUE SIO_MEASUREMENT_VALUE);

use constant SIO_HAS_ATTR => 'http://semanticscience.org/resource/SIO_000008';
use constant SIO_HAS_VALUE => 'http://semanticscience.org/resource/SIO_000300';
use constant SIO_HAS_UNIT => 'http://semanticscience.org/resource/SIO_000221';
use constant SIO_ATTRIBUTE => 'http://semanticscience.org/resource/SIO_000614';
use constant SIO_HAS_MEASUREMENT_VALUE => 'http://semanticscience.org/resource/SIO_000216';
use constant SIO_MEASUREMENT_VALUE => 'http://semanticscience.org/resource/SIO_000070';

use constant RDF_TYPE => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
 
