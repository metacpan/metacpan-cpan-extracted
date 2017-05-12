#!/usr/bin/perl

use Test::More tests => 11;
use vars qw/$pkg/;

BEGIN { 
	$pkg = 'Sub::Lexical';
	use_ok($pkg);
}

use strict;

# no. 2
ok($pkg->VERSION > 0,	'version number set');

my $f = $pkg->new();
# no. 3
ok($f,					'constructor ok');

# no. 4,5,6
{
	my $var;
	eval $f->filter_code(q(
		my sub foo {
			 return 'dereffed';
		}
		$var = &{ \&foo }();
	));
	is($var, 'dereffed',		'sub deref');
	
	eval $f->filter_code(q(
		my sub foo {
			 return 'dereffed';
		}
		$var = &{ \\&foo };
	));
	is($var, 'dereffed',		'sub deref no parens');
	
	eval $f->filter_code(q(
		my sub foo {
			 return 'dereffed';
		}
		$var = ${ \\\\&foo }->();
	));
	is($var, 'dereffed',		'sub dedereffed');
}

# no. 7
{
	my $foo = "a string";
	my sub foo {
		print "in foo\n";
	}
	is($foo, "a string",		'var namespace collision');
}

# no. 8,9
{
	my sub foo { return "in dispatch" }
	my sub bar { return "in dispatch" }
	my $dispatch = {
		foo_sub		=> \&foo,
		bar_sub		=> \&bar,
	};

	is($dispatch->{foo_sub}->(), 'in dispatch',		'dispatch test 1');
	my $dispatched = $dispatch->{bar_sub};
	is($dispatched->(),	'in dispatch',				'dispatch test 2');
}

# no. 10
{
	my $cnt = 0;
	my sub foo {
		$cnt++;
		foo() if $cnt != 5;
	}
	foo();
	cmp_ok($cnt, '==', 5,							'recursion test');
}

# no. 11
{
	my $var;
	my sub foo {
		return 'in TOP foo';
	}
	{
		my sub foo {
			return 'in SUB foo';
		}
		$var = foo();
	}
	is($var, 'in SUB foo',							'depth test');
}
