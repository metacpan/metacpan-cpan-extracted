use Test::More tests => 7;
use Test::Moose;  

	use lib 't/lib';
	use lib 'lib';

{ 

    package MyClass;
	use Moose;
	use MooseX::Attribute::Prototype;
    
	has 'attr' => ( prototype => 'borrowed_role/borrowed_attr' );
	has 'attr_2' => ( prototype => 'MyRole' );
	
}

package main;

	my $o = MyClass->new();

	isa_ok( $o, 'MyClass' );
	meta_ok( $o );
	does_ok( $o->meta , 'MooseX::Attribute::Prototype::Meta' );

  # ATTRIBUTE: attr
	has_attribute_ok( $o, 'attr' );
	ok( $o->attr eq 'borrowed_role/borrowed_attr', '...got the correct default' );

  # ATTRIBTUE: myrole
	has_attribute_ok( $o, 'attr_2' );
	ok( $o->attr_2 eq 'myrole', '...got the correct default' );


	
