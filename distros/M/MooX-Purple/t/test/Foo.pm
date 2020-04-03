package Foo;
use MooX::Purple -prefix => 'Foo';
use MooX::Purple::G -lib => 't/test', -prefix => 'Foo', -module => 1;
use Foo::Roles;
class +Class with qw/~Role -One -Two -Three -Four/ {
	public print {
		return $_[1];
	}
}
