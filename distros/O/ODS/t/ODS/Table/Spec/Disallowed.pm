package Table::Spec::Disallowed;

use strict;
use warnings;

use ODS;

use Table::Spec::Disallowed::Item;

name "disallowed";

item (
	type =>  'object',
	object_class => 'Table::Spec::Disallowed::Item'
);

1;

__END__
