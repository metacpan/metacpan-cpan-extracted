#!perl


use strict;

use warnings FATAL => 'all';

use Test::More tests => 69;

BEGIN{ use_ok('Ruby') }

ok !ref(0), "befor use Ruby -literal";
ok !ref(1);
ok !ref(0x0f);
ok !ref(0.1);
ok !ref("");

use Ruby -all;


isa_ok(0,   'Ruby::Object', 'constant overload: zero');
isa_ok(1,   'Ruby::Object', 'int');
isa_ok(01,  'Ruby::Object', 'oct');
isa_ok(0x1, 'Ruby::Object', 'hex');
isa_ok(0b1, 'Ruby::Object', 'bin');
isa_ok(0.1, 'Ruby::Object', 'float');
isa_ok("1", 'Ruby::Object', 'str');

ok(0->kind_of('Integer'), 'Integer');
ok(1->kind_of('Integer'));

ok(0xff->kind_of('Integer'), 'Binary');
ok(0xFF->kind_of('Integer'));
is(0xff, 0xFF, 'compare integers');
is(0xfe, 0xff - 1);
ok(01->kind_of('Integer'));
ok(0b1->kind_of('Integer'));

is(3, 0x3);
is(3, 003);
is(3, 0b11);

ok(0.0->kind_of('Float'), 'Float');
ok(0.1->kind_of('Float'));
ok(1.0->kind_of('Float'));

ok("foo"->kind_of('String'), 'String');
ok('foo'->kind_of('String'), 'String');

ok(1000_000_000_000_000_000_000_000_000_000_000->kind_of('Integer'));
ok(1000.0->kind_of('Float'));


#ok(0xFFFFFFFFFFFFFFFFFFFFFF->kind_of('Integer'));
#ok(0xFFFFFFFFFFFFFFFFFFFFFF->to_s(16), '0xFFFFFFFFFFFFFFFFFFFFFF');

rb_eval<<'EOS', __PACKAGE__;
	def add(x,y)
		x+y;
	end

EOS


is(add(4, 3), 7);

2->times(sub{ pass "in block" });

is("foo"->upcase, "FOO");

my $foo = "foo";

is($foo + "bar", "foobar");
is($foo, "foo");

ok($foo ==  "foo");
is($foo <=> "foo", 0);

ok(!("1" ==  1),  'R::S("1") == R::I(1)');
ok(  "1" !=  1,   'R::S("1") != R::I(1)');

ok("1" eq  1, 'R::S("1") eq R::I(1) (compare by string)');


cmp_ok(3/2, "eq", 1, "R::I / R::I");
cmp_ok(3.0/2.0, "eq", 1.5, "R::F / R::F");

use Ruby -no_literal;

ok !ref(""), "after no ruby";
ok !ref(1);
ok !ref(01);
ok !ref(0.1);



{
	use Ruby -literal => 'string';

	ok  ref(''), "overload string only";
	ok !ref(01);
	ok !ref(1);
	ok !ref(0.1);
}
{
	use Ruby -literal => 'integer';

	ok !ref(''), "overload integer only";
	ok  ref(01);
	ok  ref(1);
	ok !ref(0.1);
}
{
	use Ruby -literal => 'float';

	ok !ref(''), "overload float only";
	ok !ref(01);
	ok !ref(1);
	ok  ref(0.1);
}
{
	use Ruby -literal => 'numeric';

	ok !ref(''), "overload all numerics";
	ok  ref(01);
	ok  ref(1);
	ok  ref(0.1);
}
ok !eval "use Ruby -literal => 'foo'; 1", "unexpected literal type";


sub foo{
	use Ruby -literal;
	"foo";
}

is foo(), "foo";

my $s = foo();
$s += "bar";

is $s, "foobar";
is foo(), "foo";

END{ pass "test end"; }
