package MooseX::Attribute::Prototype::Meta::Attribute::Trait::Prototype;

	use Moose::Role;
	
	has prototype => (
	    is  	  => 'ro' ,
	    isa 	  => 'Str' ,
	    predicate => 'has_prototype' ,
	    required  => 0 ,
	);

1;

	
package Moose::Meta::Attribute::Custom::Trait::Prototype;

  sub register_implementation {'MooseX::Attribute::Prototype::Meta::Attribute::Trait::Prototype'}

1;