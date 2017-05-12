package role;

	use Moose::Role;

	has role_attr => ( 
		is => 'rw' , 
		isa => 'Str', 
		default => sub { __PACKAGE__ . "/role_attr" } ,
		required => 1 ,
	);

	sub role_method { };
	    	
1;	