package OWL::RDF::Predicates::RDF;

use strict;
BEGIN {
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

use constant RDF_PREFIX => 'rdf';

use constant RDF_URI => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

################################
## Predicates for RDF         ##
################################

use constant type => RDF_URI . 'type';


}
1;
