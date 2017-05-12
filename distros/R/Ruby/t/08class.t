#!perl

use warnings;
use strict;

use Test::More tests => 13;

BEGIN{ use_ok('Ruby') }

use Ruby -eval => <<'EOT';

# exported as main::TestObject
class TestObject

	def TestObject.class_method
		"class method"
	end

	def upcase(str)
		String(str).upcase
	end

	def full_name
		"main::TestObject"
	end
end

EOT


is(TestObject->class_method, "class method", "class method");
isa_ok(TestObject->new, "Ruby::Object");
isa_ok(TestObject->new, "TestObject");

is(TestObject->new->upcase("test_test"), "TEST_TEST", "instance method");

is(TestObject->new->full_name, "main::TestObject");


use Ruby -eval => <<'EOT';


class TestObject

	def ext_method
		"ext method"
	end
end

EOT

is(TestObject->new->full_name,  "main::TestObject");
is(TestObject->new->ext_method, "ext method");

package T;

use Test::More;

use Ruby -eval => <<'EOT';

# exported as "T::TestObject"
class TestObject

	def full_name
		"T::TestObject"
	end

	def iter
		yield "test"
	end
end

EOT

isa_ok(T::TestObject->new, "Ruby::Object");
isa_ok(T::TestObject->new, "T::TestObject");

is(T::TestObject->new->full_name, "T::TestObject");

T::TestObject->new->iter(sub{ is $_[0], "test", "iterator ok" });

END{
	pass "test end";
}