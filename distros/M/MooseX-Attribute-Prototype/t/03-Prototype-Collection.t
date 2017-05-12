package main;
	
	use Test::More tests => 13;

	use_ok 'MooseX::Attribute::Prototype::Object';
	use_ok 'MooseX::Attribute::Prototype::Collection';	
	
	my $o = MooseX::Attribute::Prototype::Object->new( 
		name => 'foo/bar' ,
	); 

	my $p = MooseX::Attribute::Prototype::Object->new( 
		name => 'fooz/baz' 
	);


# ----------------------------------------------------------------------
# COLLECTION 
# ----------------------------------------------------------------------
    
	my $oo = MooseX::Attribute::Prototype::Collection->new();
	isa_ok( $oo, 'MooseX::Attribute::Prototype::Collection' );

	ok( $oo->count ==  0, '... Empty prototypes collection' ); # 0


	$oo->add_prototype( $o );
	ok( $oo->count == 1, '... One prototype added' );

	$oo->add_prototype( $o );
	ok( $oo->count == 1, '... Clobbered prototype' );

	$oo->add_prototype( $p);
	ok( $oo->count == 2, '... Second prototype added'  );

	ok( $oo->keys == 2,  '... Got the correct number of keys' );

	ok( $oo->exists( "foo/bar" )    , '... foo/bar exists in prototype collection' );
	ok( ! $oo->exists( "foo/fail" ) , '... foo/fail does not exist in prototype collection' );	
	
	isa_ok( $oo->get( 'foo/bar' )  , 'MooseX::Attribute::Prototype::Object', '... got foo/bar' );
	isa_ok( $oo->get( 'fooz/baz' ) , 'MooseX::Attribute::Prototype::Object', '... got fooz/baz' );
	
	$oo->set_referenced( 'foo/bar' );
	ok( $oo->get( 'foo/bar' )->referenced, '... Attribute in collection set referenced' );

__END__
