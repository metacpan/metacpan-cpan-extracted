#!perl

use warnings FATAL => 'all';
use strict;

use Test::More tests => 36;

BEGIN{
	require_ok('Ruby');
}
cmp_ok($Ruby::Version, 'ge', '1.8.0', 'version check');

Ruby->import('rb_eval');

ok not defined(&nil);
ok defined(&rb_eval), "core function ('-function' is default)";

Ruby->import('Integer');

ok not defined(&nil);
ok defined(&Integer), "ruby function ('-function' is default)";

Ruby->import(':DEFAULT');

ok defined(&nil);
ok defined(&true);
ok defined(&false);

ok defined(&rb_require), "import :DEFAULT";

Ruby->import(-function => 'String');

ok defined(&String), "-function => 'String'";

ok not Object->isa('Ruby::Object');

Ruby->import(-class => 'Object');

ok Object->isa('Ruby::Object'), "-class => 'Object'";

ok !eval{ Ruby->import(-class => 'Not_a_class'); 1 }, "-class => 'Not_a_class'";

ok not Kernel->isa('Ruby::Object');

Ruby->import(-module => 'Kernel');

ok Kernel->isa('Ruby::Object'), "-module => 'Kernel'";

Ruby->import(-require => 'rbconfig');
Ruby->import(-module  => 'Config');

ok(Config->isa('Ruby::Object'), "-require => 'rbconfig'");


Ruby->import(-module => ['Config' => 'RubyConfig']);

ok(RubyConfig->isa('Ruby::Object'), "-module => [ruby => perl]");

Ruby->import(-function => [qw(Integer Int)]);

is(Int(10.5), 10, "-function => [ruby => perl]");

Ruby->import(-function => 'lambda(&)');

ok defined(&lambda);
is prototype(\&lambda), '&', 'import with prototype';

Ruby->import(-function => [lambda => 'lmd(&)']);

ok defined(&lmd),         "import r() as p()";
is prototype(\&lmd), '&', "with prototype";

Ruby->import(['lambda(&)' => 'lm']);

is prototype(\&lm), '&', "with prototype (2)";

Ruby->import(["binding"]);

ok defined(&binding);

ok !eval{ Ruby->import(-function => ['lambda($)' => 'lambda(&)']); 1 }, 'prototype mismatch';
ok !eval{ Ruby->import(-function => 'nil()'); 1 }, "doesn't set prototype to core function";


ok not defined(&T::nil);

Ruby->import([nil => 'T::nil']);

ok defined(&T::nil), 'export to another package';


ok !eval{ Ruby->import(-foo); 1}, "undefined import command";

ok(Ruby->import(-variable => '$stdout'), "import global variable");
ok(Ruby->import(-variable => ['$stdin', '$rubyin']), "import \$r as \$p");


ok !eval{ Ruby->import(-base); 1}, "too few arguments";
ok !eval{ Ruby->import(-base => qw(a b)); 1}, "too many arguments";
ok !eval{ Ruby->import(-all  => qw(foo)); 1}, "too many arguments";

END{
	pass "test end";
}