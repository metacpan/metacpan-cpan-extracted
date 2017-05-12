use strict;
use warnings;

use Test::More 'no_plan';
use Test::NoWarnings;

use lib 't';
use Code::Perl::Test::Expr;


use Code::Perl::Expr qw( :easy );
use Petal::CodePerl::Expr qw( :easy );

our $env;

my @tests = (
	['any unstrict method hash', {testsub => 10}, dereft(scal("main::env"), "testsub", 0), 10, undef],
	['pathexists yes', 10, pathexists(calls("main::empty")), 1, 'do{eval {main::empty()}; ! $@}'],
	['alternates 1', undef, alternate(number(1)), 1, '1'],
	[
		'alternates 3 ok',
		undef,
		alternate(string("eeny"), string("meeny"), string("miney")),
		"eeny",
		q{do{my $v;for (1){eval{$v = "eeny"}; last unless $@;eval{$v = "meeny"}; last unless $@;$v = "miney"} $v}}
	],
	[
		'alternates 2 fail',
		undef,
		alternate(perl("die"), string("eeny")),
		"eeny",
		q{do{my $v;for (1){eval{$v = die}; last unless $@;$v = "eeny"} $v}}
	],
	[
		'perlsprintf',
		["string1", "string2"],
		perlsprintf('%s->[%s].%s->[%s]."%%"', scal("main::env"), number(0), scal("main::env"), number(1)),
		"string1string2%",
		q{($main::env)->[(0)].($main::env)->[(1)]."%"},
	]
);

Code::Perl::Test::Expr::test_exprs(@tests);

sub empty
{
	return 0;
}

sub testsub
{
	my $hash = shift;
	my $key = shift;
	return $hash->{$key};
}

sub testmethod
{
	my $pkg = shift;
	my $hash = shift;
	my $key = shift;
	return "$pkg, $hash->{$key}";
}

