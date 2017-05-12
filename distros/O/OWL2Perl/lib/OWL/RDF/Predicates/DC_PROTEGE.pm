package OWL::RDF::Predicates::DC_PROTEGE;

use strict;

BEGIN {
	use vars qw /$VERSION/;
	$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

	use constant DC_PROTEGE_PREFIX => 'protege-dc';

	use constant DC_PROTEGE_URI =>
	  'http://protege.stanford.edu/plugins/owl/dc/protege-dc.owl#';

################################
## Predicates for DC_PROTEGE  ##
################################

	use constant identifier => DC_PROTEGE_URI . 'identifier';
	use constant creator    => DC_PROTEGE_URI . 'creator';
	use constant publisher  => DC_PROTEGE_URI . 'publisher';
	use constant format  	=> DC_PROTEGE_URI . 'format';

}
1;
