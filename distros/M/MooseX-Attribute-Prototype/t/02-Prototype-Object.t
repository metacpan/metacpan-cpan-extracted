package main;

	
	use Test::More tests => 9;
	use_ok 'MooseX::Attribute::Prototype::Object';	
	
	my $o = MooseX::Attribute::Prototype::Object->new( 
		name => 'foo/bar' ,
	); 

	isa_ok( $o, "MooseX::Attribute::Prototype::Object" );
	ok( $o->name eq 'foo/bar'   , '... got the right prototype' );
	ok( $o->role eq 'foo'       , '... got the right prototype role' );
	ok( $o->attribute eq 'bar'  , '... got the right prototype attribute' );


	my $p = MooseX::Attribute::Prototype::Object->new( 
		name => 'fooz/baz' 
	);

	isa_ok( $p, "MooseX::Attribute::Prototype::Object" );
	ok( $p->name eq 'fooz/baz'  , '... got the right prototype' );
	ok( $p->role eq 'fooz'      , '... got the right prototype role' );
	ok( $p->attribute eq 'baz'  , '... got the right prototype attribute' );

__END__