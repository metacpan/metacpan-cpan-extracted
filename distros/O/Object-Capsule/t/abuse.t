use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
	use_ok("Object::Capsule");
}

eval { Object::Capsule->do_something(); };
like($@, qr/Can't locate object method/, "effectively no AUTOLOADING for class methods");
