#!/usr/bin/perl

use Test::More tests => 12;
use vars qw/$pkg/;

BEGIN { 
	$pkg = 'Sub::Lexical';
	use_ok($pkg);
}

use strict;

# no. 2
ok($pkg->VERSION > 0,	'version number set');

# no. 3
eval {
	my sub foo {
		print "I'm in foo\n";
	}
};
ok(!$@,					'test parse');

# no. 4
eval {
	my $foo;
	{
		my sub foo {
			print "I'm in foo\n";
		}
	}
	ok(!defined $foo,	'lexical scope');
};

# no. 5
{
	my $var;
	eval {
		my sub foo {
			return "a string";
		}
		$var = foo();
	};
	is($var, 'a string',	'correct return');
}

# no. 6,7
{
	my $ref;
	eval {
		my sub foo {
			return "a string";
		}
		$ref = \&foo;
	};
	ok(ref($ref),			'reference test');
	is(ref($ref), 'CODE',	'isa CODE');
}

# no. 8
{
	my $var;
	eval {
		my sub foo {
			return "in foo()";
		}
		$var = foo();
	};
	is($var, 'in foo()',	'no interpolation');
}

# no. 9
{
	my $var;
	eval {
		my sub foo {
			$var = "wentto foo()";
		}
		goto &foo;
	};
	is($var, 'wentto foo()',	'goto went to');
}

# no. 10
{
	local @_ = qw(ichi ni san);
	my $var;
	eval {
		my sub foo {
			return join "#", @_;
		}
		$var = &foo;
	};
	is($var, 'ichi#ni#san',		'@_ passed properly');
}

# no. 11
{
	my $var;
	eval {
		no strict 'subs';
		my sub foo {
			return 'a bareword';
		}
		$var = foo;
	};
	is($var, 'a bareword',		'bareword worked');
}

# no. 12
{
	use warnings;

	my $err;
	local $SIG{__WARN__} = sub { $err = shift };
	eval Sub::Lexical->new()->filter_code(q[
		my $LEXSUB_foo = 'a string';
		my sub foo { return }
	]);
	like($err, qr/"my" variable \$LEXSUB_foo masks earlier declaration/,
								'expected variable collision');
}
