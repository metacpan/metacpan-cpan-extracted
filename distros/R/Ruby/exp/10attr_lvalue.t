#!perl

use warnings;
use strict;
use Test::More tests => 12;

BEGIN{ use_ok('Ruby') }

use Ruby -class => 'GC', -eval => <<'EOT';

class MyObject

	def initialize()
		@foo = 1;
	end

	def foo()
		@foo
	end

	def foo=(arg)
		@foo = arg
	end

	def bar()
		true;
	end

end

EOT

my $o = MyObject->new;

is($o->foo, 1, "read");

$o->foo = 0xFF;

is($o->foo, 0xFF, "write");

$o->foo = 'foo';

is($o->foo, "foo");

$o->foo = 1;

$o->foo++;

is($o->foo, 2, "incr");

$o->foo *= 2;

is($o->foo, 4, "mul with assig");

for(1 .. 100){
	GC->start;
	$o->foo++;
}

is($o->foo, 104, "incr with GC->start");

$o->foo = true;

is_deeply($o->foo, true, "store Ruby object");

is($o->bar, true);
eval{
	$o->bar = false;
};
ok $rb_errinfo->kind_of('NoMethodError'), '$obj->unwritable = $value; -> raise NoMethodError';

is($o->bar, true);

pass "test end";

