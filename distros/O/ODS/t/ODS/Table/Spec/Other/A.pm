package Table::Spec::Other::A;

use strict;
use warnings;

use ODS;

name "a";

options (
	custom => 1
);

column b => (
	type => 'string',
	sortable => true,
	filterable => true
);

1;

__END__
