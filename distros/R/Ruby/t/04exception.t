#!perl

use warnings;
use strict;

use Test::More tests => 25;

BEGIN{ use_ok('Ruby'); }

use Ruby ':DEFAULT', qw(raise String rb_c lambda(&) catch throw),
	-class => qw(Kernel);

eval{
	rb_c(Object)->numify;
};
ok( $rb_errinfo->kind_of('TypeError'), "bad numify" );

eval{
	rb_c(Object)->respond_to('');
};
ok( $rb_errinfo->kind_of('ArgumentError'), "Empty symbol");

eval{
	raise(String 'TEST');
};

ok( $rb_errinfo->kind_of('RuntimeError'), "raise");
ok(!$rb_errinfo->kind_of('SyntaxError'),  "... isn't Syntax Error");


like($@, qr/TEST/, '$@');
like($rb_errinfo, qr/TEST/, "$rb_errinfo");

eval{
	rb_eval 'nil.call_undefined_method';
};

ok($rb_errinfo->kind_of('NameError'), "rb_eval");


eval{
	nil->call_undefined_method();
};

ok($rb_errinfo->kind_of('NameError'), "method call");


eval{ lambda { raise(String 'TEST') }->call; };

ok($rb_errinfo->kind_of('RuntimeError'), "raise in block sub");

eval{ lambda { die 'TEST' }->call };

ok($rb_errinfo->kind_of('Perl::Error'), "die in block sub");

eval{ lambda { undefined_function() }->call };

ok($rb_errinfo->kind_of('Perl::Error'), "error in block sub");


eval{
	rb_eval(q{ Perl['&Carp::croak'].call('TEST')});
};

ok($rb_errinfo->kind_of('Perl::Error'), "die in rb_eval in sub");

eval{
	Kernel->open();
};

ok($rb_errinfo->kind_of('ArgumentError'), "wrong number of arguments");

eval{
	my $s = String('foo');
	$s->freeze;
	$s->concat('bar');
};

ok($rb_errinfo->kind_of('TypeError'), "can't modify frozen string");

eval{
	my $s = rubyify('foo');
	$s->concat('bar');
};
ok($rb_errinfo->kind_of('TypeError'), "Modification of read-only value attempt");

eval{
	rb_eval('return');
};
ok($rb_errinfo->kind_of('LocalJumpError'), "unexpected return");

eval{
	rb_eval('redo');
};
ok($rb_errinfo->kind_of('LocalJumpError'), "unexpected redo");

eval{
	rb_eval('break');
};
ok($rb_errinfo->kind_of('LocalJumpError'), "unexpected break");

eval{
	catch 'foo', sub{
		throw 'foo';
	};
};
ok($rb_errinfo->kind_of('LocalJumpError'), "catch/throw");


eval{
	Kernel->exit();
};


ok($rb_errinfo->kind_of('SystemExit'), "system exit");

eval{
	rb_eval('1 1 1');
};

ok($rb_errinfo->kind_of('SyntaxError'), "syntax error");

eval{
	rb_eval('$SAFE=1;$SAFE=0');
};


ok($rb_errinfo->kind_of('SecurityError'), 'insecure operation');

eval{
	$rb_errinfo = "foo";
};

ok($rb_errinfo->kind_of('TypeError'), "assigment non-exeption into \$!");


END{
	pass "test end";
}
