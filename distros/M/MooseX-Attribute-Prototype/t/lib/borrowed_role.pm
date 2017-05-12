package borrowed_role;
	use Moose::Role;

	has borrowed_attr => ( 
		is => 'rw' , 
		isa => 'Str', 
		default => sub { __PACKAGE__ . "/borrowed_attr" } ,
		required => 1 ,
	);

	has borrowed_attr_unused => (
		is 		 => 'ro' ,
		isa 	 => 'Bool' ,
		default  => 1 ,
		required => 0 ,
	);

# borrowed attributes borrowing from attributes not supported yet.
#	has borrowed_attr_w_prototype => (
#		is		  => 'ro' ,
#		isa 	  => 'Str' ,
#		default   => sub { __PACKAGE__ . "/borrowed_borrowed_attr" } ,
#		prototype => 'borrowed_borrowed_role' ,
#	);

	sub blue { print "__PACKAGE: blue\n"; };

	
1;	