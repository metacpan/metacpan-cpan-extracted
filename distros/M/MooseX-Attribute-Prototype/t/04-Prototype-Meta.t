package main;
   use Test::More tests => 5;
   use Test::Moose;  

	use lib 't/lib';
	use_ok 'MooseX::Attribute::Prototype::Meta';

	is_deeply( 
        MooseX::Attribute::Prototype::Meta::_parse_prototype_name( 'M::X/foo' ) ,
		{ role => 'M::X', attribute => 'foo' } ,
		'... standard prototype specification'
	);

	is_deeply( 
        MooseX::Attribute::Prototype::Meta::_parse_prototype_name( 'M::Foo' ) ,
		{ role => 'M::Foo', attribute => 'foo' } ,
		'... abbreviated prototype specification'
	);

	ok( 
        MooseX::Attribute::Prototype::Meta::_parse_prototype_name( 'M::X/foo' )->{role} eq 'M::X' ,
        '... Address role'
    );

	ok( 
        MooseX::Attribute::Prototype::Meta::_parse_prototype_name( 'M::X/foo' )->{attribute} eq 'foo' ,
        '... Address attribute'
    );

