package MyRole;

	use Moose::Role;

	has myrole => ( 
		is => 'rw' ,
		isa => 'Str' ,
		default => 'myrole' ,
		required => 1 
	);

1;