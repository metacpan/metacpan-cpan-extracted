use strict;
use Test::More qw(no_plan);
use Object::AutoAccessor;

my $hashref = {
	foo => {
		bar => {
			baz => 'BAZ',
		},
		baz => 'BAZ',
	},
	bar => 'BAR',
};

{
	my $obj = Object::AutoAccessor->build($hashref);
	
	is ( $obj->bar => 'BAR' );
	is ( $obj->foo->baz => 'BAZ' );
	is ( $obj->foo->bar->baz => 'BAZ' );
	
	is_deeply( $obj->as_hashref => $hashref );
}
