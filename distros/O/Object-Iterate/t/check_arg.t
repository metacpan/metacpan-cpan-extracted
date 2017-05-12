use Test::More;

use Object::Iterate;
use Object::Iterate::Tester;

ok( Object::Iterate::_check_object(	
	Object::Iterate::Tester->new() ),
	'Tester object can use Object::Iterate' );

my $result = not eval{ Object::Iterate::_check_object( {} ) };
ok( $result, "Thought anonymous hash would work!" );

$result = not eval{ Object::Iterate::_check_object( [] ) };
ok( $result, "Thought anonymous array would work!" );

$result = not eval{ Object::Iterate::_check_object( bless {}, 'Foo' ) };
ok( $result, "Thought blessed hash would work!" );

$result = not eval{ Object::Iterate::_check_object( undef ) };
ok( $result, "Thought undef would work!" );

$result = not eval{ Object::Iterate::_check_object( ) };
ok( $result, "Thought empty arg list would work!" );

done_testing();
