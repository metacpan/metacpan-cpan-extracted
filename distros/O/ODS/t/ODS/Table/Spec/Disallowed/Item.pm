package Table::Spec::Disallowed::Item;

use strict;
use warnings;

use ODS;

name "item";

options (
	custom => 1
);

column a => (
	type => 'integer',
);

column b => (
	type => 'integer',
);

column c => (
	type => 'integer',
);

1;

__END__
