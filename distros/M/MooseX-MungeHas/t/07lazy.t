use Test::More tests => 3;
use strict;
use warnings;

{ package XXX; use Test::Requires "Moo"; }
{ package YYY; use Test::Requires "Moose"; }
{ package ZZZ; use Test::Requires "Mouse"; }

subtest $_, \&test_lazy, $_ for qw/ Moo Moose Mouse /;

sub test_lazy {
	my $framework = shift;
	
	my $class = eval qq!
		package Foo::$framework;
		
		use $framework;
		use MooseX::MungeHas;
		
		has bar => (
			is   => 'ro',
			lazy => sub { 'got it' },
		);
		
		__PACKAGE__;
	!;
	
	ok $class, "class building worked for $class";
	
	is $class->new->bar => 'got it', 'lazy attribute works';
}

