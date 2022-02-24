package Table::Spec::Other;

use strict;
use warnings;

use ODS;

use Table::Spec::Other::A;

name "other";

options (
	custom => 1
);

column a => (
	type => 'object',
	object_class => 'Table::Spec::Other::A'
);

column c => (
	type => 'integer',
	field => {
		attributes => {
			required => true,
		}
	}
);


1;

__END__
