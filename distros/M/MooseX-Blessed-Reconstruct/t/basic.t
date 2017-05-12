#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Scalar::Util qw(refaddr);

use ok 'MooseX::Blessed::Reconstruct';

{
	# convince Perl these classes are loaded
	{ package Some::Foo; sub foo {}; package Some::Bar; sub bar {} }

	my $v = MooseX::Blessed::Reconstruct->new;

	isa_ok( $v, "MooseX::Blessed::Reconstruct" );

	my $obj = bless({
		oh => "hai",
		bar => bless({
			name => "Hello",
		}, "Some::Bar"),
	}, "Some::Foo");

	$obj->{bar2} = $obj->{bar};

	my $fixed = $v->visit($obj);

	isa_ok( $fixed, "Some::Foo" );
	isa_ok( $fixed->{bar}, "Some::Bar" );
	isa_ok( $fixed->{bar2}, "Some::Bar" );
	is( refaddr($fixed->{bar}), refaddr($fixed->{bar2}), "refaddr for shared ref" );
	is( $fixed->{oh}, "hai", "simple value" );
}

{
	{
		package A::Nonmoose::Class; # not to be confused with an anonymous class!

		sub new { bless $_[1], $_[0] }

		sub name { $_[0]{name} }

		package A::Moose::Class;
		use Moose;

		has string => ( is => 'ro', isa => 'Str', required => 1 );
		has _      => ( is => 'ro', isa => 'Str', required => 1, init_arg => 'foo' );
		has ignore => ( is => 'ro', isa => 'Str', default => 'ok', init_arg => undef );
		has other  => ( is => 'ro', isa => 'A::Nonmoose::Class' );
		has moose  => ( is => 'ro', isa => 'Str', default => 'hi' );
		has extra  => ( is => 'rw' );

		sub BUILD { shift->extra("yatta") }
	}

	my $obj = bless( {
		string => 'test',
		foo    => 'bar',
		other  => bless({ name => "Yuval"}, "A::Nonmoose::Class"),
	}, 'A::Moose::Class');

	isnt $obj->{moose}, 'hi', 'default not yet created';
	isnt $obj->{extra}, 'extra', 'BUILD not called';

	my $fixed = MooseX::Blessed::Reconstruct->new->visit($obj);

	isnt( refaddr($fixed), refaddr($obj), "new object" );

	isa_ok $fixed, 'A::Moose::Class';
	isa_ok $fixed->other, 'A::Nonmoose::Class';

	is $fixed->string, 'test', 'simple data';
	is $fixed->other->name, 'Yuval', 'nested object data';
	is $fixed->_, 'bar', 'init_arg value works';
	is $fixed->moose, 'hi', '"default" worked';
	is $fixed->ignore, 'ok', 'no init-arg';
	is $fixed->extra, 'yatta', 'BUILD called';

	isnt $obj->{moose}, 'hi', 'proto was not destroyed';
	isnt $obj->{extra}, 'extra', 'proto was not destroyed';
}
