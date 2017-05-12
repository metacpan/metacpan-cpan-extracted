#!perl

use warnings FATAL => 'all';
use strict;

use Test::More tests => 154;

BEGIN{ use_ok('Ruby', ':DEFAULT') }

use Ruby -function => qw(rb_const Rational Float Integer String lambda(&) rb_c),
	-require => 'rational',
	-class => 'GC', 'String', 'Array',
	-module => 'Kernel',
	-alias => [make => '[]'];

is(rb_const(RUBY_VERSION), $Ruby::Version, 'RUBY_VERSION eq $Ruby::Version');

is_deeply rb_eval("nil"), nil, "rb_eval";

is_deeply rb_eval("true"), true, "rb_eval";

is_deeply rb_eval("false"), false, "rb_eval";

is_deeply rb_eval("nil ? true : false"), false, "rb_eval";

is_deeply rb_eval("if(!nil) then 10 else 11 end"), Integer(10), "rb_eval";

isa_ok(nil, "Ruby::Object");

isa_ok(nil, "Ruby::Object");

can_ok(nil, 'inspect');

ok(nil->respond_to('inspect'), "respond_to");
ok(nil->kind_of('Object'), "kind_of");

is nil->send("inspect"), "nil", "send";
is nil->inspect(), "nil", "NilClass#inspect";

is nil->object_id, nil->send("object_id"), "funcall with string";
is nil->object_id, nil->send( String("object_id")->to_sym ), "funcall with symbol";

nil->class->alias('is_nil', 'nil?');
ok nil->is_nil, "alias";

is sprintf('%s', true), 'true', 'stringify';
is sprintf('%d', Integer(10)), '10', 'numify';

ok true,   "bool test (true)";
ok !nil,   "bool test (nil)";
ok !false, "bool test (false)";
ok !!String('ok'), "bool test (string)";
ok !!String(''),   "bool test (empty string)";

is String('foo'), String('foo'), "str == str";
is String('foo')->clone, String('foo'), "str.clone == str";

is String('str')->stringify, 'str';
is String('1.23')->numify,   1.23;
is String('1000')->numify,   1000;
is String('100000000000000000000000000000000000')->numify, 100000000000000000000000000000000000;
ok String('')->boolify, "string is always true";

is Integer(100)->stringify, '100';
is Integer(100)->numify,     100;
ok Integer(0)->boolify, "integer is always true";

is Float(1.23)->stringify, '1.23';
is Float(1.23)->numify,     1.23;
ok Float(0)->boolify, "float is always true";

is Rational(Integer(1), Integer(2))->numify, 1/2, "rational->numify";
is Rational(Integer(1), Integer(2))->stringify, "1/2", "rational->stringify";

cmp_ok Integer(10), "eq", Integer(10), "Ruby::Integer eq Ruby::Integer";
cmp_ok Integer(10), "eq", 10, "Ruby::Integer eq Perl::Integer";
cmp_ok         10 , "eq", Integer(10), "Perl::Integer eq Ruby::Integer";

cmp_ok Integer(10), "==", Integer(10), "R::I == R::I";
cmp_ok Integer(10), "!=", Integer(11), "R::I != R::I";

cmp_ok Integer(10), "==", 10, "R::I == P::I";
cmp_ok Integer(10), "!=", 11, "R::I == P::I";

cmp_ok 10, "==", Integer(10), "P::I == R::I";
cmp_ok 10, "!=", Integer(11), "P::I == R::I";

cmp_ok Integer(10) <=> Integer(10), "==", 0, "R::I <=> R::I";
cmp_ok Integer(10) <=> Integer( 9),  ">", 0;
cmp_ok Integer(10) <=> Integer(11),  "<", 0;

cmp_ok Integer(10) <=> (10), "==", 0, "R::I <=> P::I";
cmp_ok Integer(10) <=> ( 9), " >", 0;
cmp_ok Integer(10) <=> (11),  "<", 0;

cmp_ok 10 <=> Integer(10), "==", 0, "P::I <=> R::I";
cmp_ok 10 <=> Integer( 9), " >", 0;
cmp_ok 10 <=> Integer(11),  "<", 0;

ok((Integer(10)+Integer(10))->kind_of('Integer'), "R::I + R::I => R::I");
ok((Integer(10)+10)         ->kind_of('Integer'), "R::I + P::I => R::I");
ok((Integer(10)+ 0.5)       ->kind_of('Float'),   "R::I + P::F => R::F");
ok((Integer(10)+'10')       ->kind_of('Numeric'), "R::I + P::IS => R::Numeric");
ok((Integer(10)+'0.5')      ->kind_of('Numeric'), "R::I + P::FS => R::Numeric");

is Integer(10) + Integer(2), 12, "R::I + R::I";
is Integer(10) + 2         , 12, "R::I + P::I";

is Integer(10) - Integer(2),  8, "R::I - R::I";
is Integer(10) - 2         ,  8, "R::I - P::I";

is Integer(10) * Integer(2), 20, "R::I * R::I";
is Integer(10) * 2         , 20, "R::I * P::I";

is Integer(10) / Integer(2),  5, "R::I / R::I";
is Integer(10) / 2         ,  5, "R::I / P::I";

is Integer(10) % Integer(4),  2, "R::I % R::I";
is Integer(10) % 4         ,  2, "R::I % P::I";

is Integer(10) ** Integer(2), 100, "R::I ** R::I";
is Integer(10) ** 2         , 100, "R::I ** P::I";

is Integer(010) | Integer(002), 012, "R::I | R::I";
is Integer(010) | 002,          012, "R::I | P::I";

is Integer(070) & Integer(011), 010, "R::I & R::I";
is Integer(070) & 011,          010, "R::I & P::I";

is Integer(070) ^ Integer(071), 001, "R::I ^ R::I";
is Integer(070) ^ 071,          001, "R::I ^ P::I";

is -Integer(10), Integer(-10), "-R::I";
is  Integer(077) & ~Integer(01),  Integer(076),  "~R::I";

isa_ok abs(Float(-10)), "Ruby::Object";
is     abs(Float(-10)), Float(10),   "abs() is overloaded";

isa_ok int(Float(1.5)), "Ruby::Object", "int()";
is     int(Float(1.5)), Integer(1),   "int() is overloaded";

isa_ok sqrt(Float(100)), "Ruby::Object", "sqrt()";
is     sqrt(Float(100)), Float(10), "sqrt() is overloaded";

isa_ok sin(Float(100)), "Ruby::Object", "sin()";
isa_ok cos(Float(100)), "Ruby::Object", "cos()";
isa_ok exp(Float(100)), "Ruby::Object", "exp()";
isa_ok log(Float(100)), "Ruby::Object", "log()";
isa_ok atan2(Float(1), Float(1)), "Ruby::Object", "atan2(R::F, R::F)";
isa_ok atan2(Float(1), 1.0), "Ruby::Object", "atan2(R::F, P::F)";
isa_ok atan2(1.0, Float(1)), "Ruby::Object", "atan2(P::F, R::F)";

my $i = Integer(10);

$i += Integer(1);

is $i, 11, "R::I += R::I";
isa_ok $i, "Ruby::Object";

$i += 1;

is $i, 12, "R::I += P::I";
isa_ok $i, "Ruby::Object";

$i++;

is $i, 13, "R::I++";
isa_ok $i, "Ruby::Object";


ok !eval{ 10 + Integer(10) }, "Don't P::I + R::I";

is Integer(100)->inspect, 100, "inspect Integer";

my $plus_one = lambda{ $_[0] + 1 };

ok($plus_one->respond_to('call'), 'make lambda');

is $plus_one->call(Integer(10)), 11, "lambda->call";
is $plus_one->call(Integer(10)), 11, " ... retry";

is $plus_one->(Integer(11)), 12, "lambda as code";
is $plus_one->(Integer(11)), 12, " ... retry";

my $count = 0;
Integer(3)->times(sub{
	my($i) = @_;

	is $count, $i, "do block with param";

	$count++;
});


$count = 0;
rb_eval('[1, 2, 3, 4, 5]')->each(sub{
	is($_[0], ++$count, 'ary.each');
});
rb_eval('{:foo => :bar}')->each(sub{
	is $_[0], 'foo', 'hash.each';
	is $_[1], 'bar', 'hash.each';
});


rb_eval(<<'.', __PACKAGE__);

	def add(x, y)
		x.to_f + y.to_f
	end

	def pkg()
		__PACKAGE__
	end

	def call_functions()
		f('f()');
		g('g()');
		h('h()');
	end

.

cmp_ok add(1, 2), '==', 3, 'eval & import';

is pkg(), 'main', '__PACKAGE__ in ruby';

sub f{
	is $_[0], 'f()',  "call f() in ruby";
}
sub g{
	is $_[0], 'g()', "call g() in ruby";
}
sub h{
	is $_[0], 'h()', "call h() in ruby";
}

call_functions();


is(rb_c(Kernel), "Kernel", "rb_c");
is(Kernel::->class, rb_c(Module), "import module");
is(String::->class, rb_c(Class),  "import class");
is(String::->new('')->class, rb_c(String), "new");

is_deeply( Array->make(1 .. 1000)->to_perl, [1 .. 1000], 'call with many arguments');

# rubyify / to_perl

ok rubyify('')   ->kind_of('Perl::Scalar'), "rubyify str";
ok rubyify( 0)   ->kind_of('Perl::Scalar'),  "rubyify num";
ok rubyify(undef)->kind_of('Perl::Scalar'), "rubyify undef";

ok rubyify([]) ->kind_of('Perl::Array'),  "rubyify array";
ok rubyify({}) ->kind_of('Perl::Hash'),   "rubyify hash";
ok rubyify(\&f)->kind_of('Perl::Code'),   "rubyify code";
ok rubyify(*f) ->kind_of('Perl::Glob'),   "rubyify glob";

ok rubyify(*STDIN)    ->kind_of('Perl::Glob'), "rubyfiy *STDIN  -> Perl::Glob";
ok rubyify(\*STDIN)   ->kind_of('Perl::IO'),   "rubyify \*STDIN -> Perl::IO";
ok rubyify(*STDIN{IO})->kind_of('Perl::IO'),   "rubyify *STDIN{IO} -> Perl::IO";


ok rubyify(Integer(1))->kind_of('Integer'), "rubyify rubyint";

is_deeply rubyify([1, 2, 3])->to_perl, [1, 2, 3], "to_perl perlarray";
is_deeply rubyify({foo => 'bar'})->to_perl, {foo => 'bar'}, "to_perl perlhash";

is_deeply rb_eval('[1, 2, 3]')->to_perl, [1, 2, 3], "to_perl rubyarray";
is_deeply rb_eval('{1 => 2, "foo" => "bar"}')->to_perl, {1 => 2, "foo" => "bar"}, "to_perl rubyhash";

# global variable

our $stdin;
Ruby->import(-variable => '$stdin');
ok $stdin, "import global variable";
ok $stdin->kind_of('IO');

our $rubyout;
Ruby->import(-variable => [qw($stdout $rubyout)]);

ok $rubyout;
ok $rubyout->kind_of('IO');

{package T; our $stderr;}
Ruby->import(-variable => [qw($stderr $T::stderr)]);
ok $T::stderr->kind_of('IO'),'export $gvar to T::';

rb_eval('$gvar = 10');

Ruby->import(-variable => '$gvar');
our $gvar;

is $gvar, 10, "get gvar";
$gvar = 20;
is $gvar, 20, "set gvar";

is rb_eval('$gvar'), 20, "get in ruby";
rb_eval('$gvar = $gvar.to_i * 2');

is $gvar, 40, "set in ruby";


for(1 .. 10){
	$gvar++; GC->start;
}

is $gvar, 50, "set/get \$gvar";

END{
	pass "test end";
}

