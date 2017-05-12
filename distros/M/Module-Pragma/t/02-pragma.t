#!perl

use strict;
use warnings;

use Test::More tests => 26;


BEGIN{ require_ok('Module::Pragma') };
BEGIN{
	package test2;
	$INC{'test2.pm'} = __FILE__;

	use base qw(Module::Pragma);

	__PACKAGE__->register_tags( 'A', 'B', 'C' );

	__PACKAGE__->register_exclusive('A', 'B');

	sub default_import { 'A' }
}


ok(!eval{ test2->import('A', 'B'); 1 }, 'exclusive tags');
like $@, qr/exclusive/, 'ex exception';

#########################################################
sub t0{
	is_deeply([test2->enabled()], [], "nothing is enabled");
}
sub t1{
	ok( test2->enabled('A'), "'A' is only enabled");
	ok(!test2->enabled('B'), "'B' is not enabled");
	ok(!test2->enabled('C'), "'C' is not enabled");
}
sub t2{
	ok(!test2->enabled('A'), "Now, 'A' is not enabled");
	ok( test2->enabled('B'), "And  'B' is enabled");
	ok(!test2->enabled('C'), "Of couse, 'C' is not enabled");
}
sub t3{
	ok(!test2->enabled('A'), "'A' is not enabled");
	ok( test2->enabled('B'), "'B' is enabled");
	ok( test2->enabled('C'), "Now, 'C' is enabled");
}
sub t4{
	is_deeply [test2->enabled], [], '"no" removes the effect';
}

sub t5{

	ok( test2->enabled('A') );
}

t0();
{
	use test2;
	t1();

	use test2 'B';
	t2();

	use test2 'C';
	t3();

	no test2;
	t4();

	use test2 'A';
	t5();
}
t0();

sub t6{
	ok(!test2->enabled('A'), 'in no PRAGMA "A"');
	ok( test2->enabled('B'), '== use PRAGMA "B"');
}
sub t7{
	is_deeply([test2->enabled()], [], 'no PRAGMA; only');
}
sub t8{
	is_deeply([test2->enabled()], [], 'no PRAGMA "C"; is empty');
	ok(defined(test2->enabled()), '... but defined');
}

{
	no test2 'A';
	t6();

	no test2;
	t7();

	no test2 'C';
	t8();
}

t0();


BEGIN{
	package test3;
	$INC{'test3.pm'} = __FILE__;

	use base qw(Module::Pragma);

	sub unknown_tag{
		my($class, $tag) = @_;

		my $bit =  $class->register_tags($tag);
		$class->register_exclusive($class->tags);

		return $bit;
	}
}
#########################################################

sub t9{
	is_deeply( [test3->enabled()], ['B'], 'auto-setted');
}
sub t10{
	is_deeply( [test3->enabled()], ['C'], 'everything is exclusive');
}
sub t11{
	is_deeply( [test3->enabled()], ['A'], 'local scoped');
}

use test3 'A';
{
	use test3 'B';
	t9();

	use test3 'C';
	t10();

}
t11();

sub f{
	g();
}
sub g{
	h();
}
sub h{
	is_deeply( [test3->enabled()], ['A'], "deep subcall");
}

{
	use test3 'A';
	f();
}

#EOF
