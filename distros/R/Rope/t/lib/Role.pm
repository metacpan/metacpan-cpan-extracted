package Role;

use Rope::Role;

prototyped (
	one => 1
);

property two => (
	value => 2,
	writeable => 0,
	enumerable => 0,
);

function three => sub { 
	my ($self, $int) = @_;
	$self->{two} + $int;
};

1;
