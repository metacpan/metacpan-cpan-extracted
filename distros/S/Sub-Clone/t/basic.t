#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Util qw(refaddr);

use ok 'Sub::Clone' => ':all';

sub foo { "foo" }

my $bar = "bar";

{
	sub bar { $bar };
}

my $anon = sub { "anon" };

my $blah = "closure";
my $closure = sub { $blah };

ok( !is_cloned(\&foo), "foo is not a cloned sub" );
ok( !is_cloned(\&bar), "bar is a non cloned closure" );
ok( !is_cloned($anon), "non closure anon is not cloned" );

ok( is_cloned($closure), "closure is cloned" );

my $destroyed;
sub Foo::DESTROY { $destroyed++ };

foreach my $sub ( \&foo, \&bar, $anon, $closure ) {
	my $foo = {};
	my $clone = clone_sub($sub);
	ok( is_cloned($clone), "clone is cloned" );
	isnt( refaddr($sub), refaddr($clone), "refaddrs differ" );

	SKIP: {
		skip "no Scalar::Util::weaken" unless defined &Scalar::Util::weaken;
		Scalar::Util::weaken($foo);
		is( $foo, undef, "didn't randomly capture stuff" );
	}

	use Devel::Peek;
	is( $clone->(), $sub->(), "behaves the same" );# || do { Dump($clone); Dump($sub) };

	undef $destroyed;

	bless $clone, "Foo";

	is( ref($sub), "CODE", "orig sub not blessed" );

	my $clone_2 = clone_sub($clone);

	is( ref($clone_2), "Foo", "clone is blessed the same way" );

	undef $clone_2;
	is( $destroyed, 1, "DESTROY called on clone of clone" );

	undef $destroyed;

	my $clone_3 = clone_sub($clone);

	undef $clone;
	#ok( $destroyed, "DESTROY called on clone" ); # passes with XS, but not with pure perl
	undef $clone_3;
	is( $destroyed, 2, "DESTROY called on clone and second clone of clone" );

	my $mortal = clone_if_immortal($sub);
	ok( is_cloned($mortal), "mortal" );

	if ( is_cloned($sub) ) {
		is( refaddr($mortal), refaddr($sub), "orig is already mortal, refaddr is the same" );
	} else {
		isnt( refaddr($mortal), refaddr($sub), "orig is not mortal, refaddrs differ" );
	}
}

{
	my $weak;

	{
		my ( $anon, $clone );

		{
			my $x = "foo";
			if ( defined &Scalar::Util::weaken ) {
				$weak = \$x;
				Scalar::Util::weaken($weak);
			}
			$anon = sub { $x };

			is( $anon->(), "foo", "anon's closed over value" );

			$clone = clone_sub($anon);

			is( $clone->(), "foo", "clone returns the same" );

			$x = "bar";

			is( $anon->(), "bar", "var is captured" );

			is( $clone->(), "bar", "clone in sync" );
		}

		undef $anon;

		is( $clone->(), "bar", "clone refcounts closed var" );

		SKIP: {
			skip "no Scalar::Util::weaken" unless defined &Scalar::Util::weaken;
			is( $$weak, "bar", "weakref is valid" );
		}
	}

	SKIP: {
		skip "no Scalar::Util::weaken" unless defined &Scalar::Util::weaken;
		is( $weak, undef, "weakref went away" );
	}
}

sub mk {
	my $x = shift;
	sub { $x };
}

{
	my $a = mk(3);
	is( $a->(), 3, "closure for left scope" );
	my $clone = clone_sub($a);
	is( $clone->(), 3, "clone works too" );
}
