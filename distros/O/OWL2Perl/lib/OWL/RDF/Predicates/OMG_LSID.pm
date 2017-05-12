package OWL::RDF::Predicates::OMG_LSID;

use strict;

BEGIN {
    use vars qw /$VERSION/;
    $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

	use constant OMG_LSID_PREFIX => 'lsid';

	use constant OMG_LSID_URI => 'http://lsid.omg.org/predicates#';

################################
## Predicates for OMG         ##
################################

	use constant latest =>  OMG_LSID_URI . 'latest' ;

}
1;
