package Table::Test;

use strict;
use warnings;

use ODS;

name "test";

options (
	custom => 1
);

column username => (
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

column first_name => (
	sortable => true,
	filterable => true,
	field => {
		attributes => {
			required => true,
		}
	}
);

column last_name => (
	sortable => true,
	filterable => true,
	field => {
		attributes => {
			required => true,
		}
	}
);

1;

__END__
