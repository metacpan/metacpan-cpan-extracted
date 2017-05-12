use Test::More tests => 19;
use Test::Moose;  

	use lib 't/lib';

{
    package MyClass;

        use Moose;
		use MooseX::Attribute::Prototype;
		with 'role';

		has class_attr_w_prototype => ( 
			is => 'ro', 
			isa => 'Str', 
			prototype => 'borrowed_role/borrowed_attr' ,
		);

		has class_attr_wo_prototype => (
			is => 'rw' ,
			isa => 'Str' ,
			default => 'class_attr_wo_prototype' ,
			required => 1 ,
		);

}


package main;

    my $o = MyClass->new(  );

	isa_ok( $o, 'MyClass' );
	meta_ok( $o );
    does_ok( $o->meta , 'MooseX::Attribute::Prototype::Meta' );
	has_attribute_ok( $o->meta, 'prototypes', '... meta has slot: prototypes' );
	has_attribute_ok( $o->meta, 'prototype_queue', '... meta has slot: prototype_queue' );

  # Class Attributes
	has_attribute_ok( $o, 'class_attr_wo_prototype', '... normal attribute' );
	ok( $o->class_attr_wo_prototype eq 'class_attr_wo_prototype', '... got default for normal attribute' );


  # Role Attribute
	does_ok( $o, 'role' );
	has_attribute_ok( $o, 'role_attr', '... got attribute from role' ) ;
	ok( $o->role_attr eq 'role/role_attr', '... got attribute default from role' );
	can_ok( $o, 'role_method' ); #  '... does role_method' );

  # Prototype Attributes
	does_ok( $o, 'borrowed_role' );
	ok( $o->meta->prototypes->count == 2 , '... got correct prototype count' );
	isa_ok( $o->meta->prototypes->get( 'borrowed_role/borrowed_attr' ) , 'MooseX::Attribute::Prototype::Object' );
	isa_ok( $o->meta->prototypes->get( 'borrowed_role/borrowed_attr_unused' ) , 'MooseX::Attribute::Prototype::Object' );
	has_attribute_ok( $o, 'class_attr_w_prototype', '... has_attribute class_attr_w_prototype' );
	ok( $o->class_attr_w_prototype eq 'borrowed_role/borrowed_attr', '... correct default borrowed' );


  # Borrowed Unused Attribute
	ok( ! $o->meta->has_attribute( 'borrowed_attr' )       , '... borrowed_role/borrowed_attr is not an attribute' );
	ok( ! $o->meta->has_attribute( 'borrowed_attr_unused' ), '... borrowed_role/borrowed_attr_unused is not an attribute' );


__END__