package Table::Spec;

use strict;
use warnings;

use ODS;

use Table::Spec::Other;
use Table::Spec::Disallowed;

name "spec";

options (
	custom => 1
);

column kaput => (
	type => 'string',
	mandatory => true,
	min_length => 3,
	max_length => 30,
	sortable => { active => true, direction => "desc" },
	filterable => true,
	keyfield => true,
	field => {
		attributes => {
			required => true,
		},
		editable => {
			attributes => {
				readonly => true
			}
		}
	}
);

column allowed => (
	type => 'array',
	field => {
		attributes => {
			required => true,
		}
	}
);

column disallowed => (
	type => 'arrayObject',
	object_class => 'Table::Spec::Disallowed',
	field => {
		attributes => {
			required => true,
		}
	}
);

column other => (
	type => 'object',
	object_class => 'Table::Spec::Other',
	field => {
		attributes => {
			required => true,
		}
	}
);

column hashref => (
	type => 'hash',
);

1;

__END__
