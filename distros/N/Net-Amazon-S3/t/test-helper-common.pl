
use strict;
use warnings;
use utf8;

use Test::Deep      v0.111 qw[ !cmp_deeply !bool ];
use Test::More      import => [qw[ !ok !is !is_deeply ]];
use Test::Warnings  qw[ :no_end_test had_no_warnings ];

use Safe::Isa qw[];
use Ref::Util qw[];

sub __expand_lazy_param {
	my ($param) = @_;

	return $param->()
		if Ref::Util::is_plain_coderef ($param);

	return $param;
}

sub ok {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	return if exists $params{if} && ! __expand_lazy_param ($params{if});

	Test::More::ok
		__expand_lazy_param ($params{got}),
		__expand_lazy_param ($title),
		;
}

sub it {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	return if exists $params{if} && ! __expand_lazy_param ($params{if});

	Test::Deep::cmp_deeply
		__expand_lazy_param ($params{got}),
		__expand_lazy_param ($params{expect}),
		__expand_lazy_param ($title),
		;
}

sub is {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	return if exists $params{if} && ! __expand_lazy_param ($params{if});

	Test::More::is
		__expand_lazy_param ($params{got}),
		__expand_lazy_param ($params{expect}),
		__expand_lazy_param ($title),
		;
}

sub cmp_deeply {
	goto \&it;
}

sub bool {
	my ($param) = @_;

	return $param if $param->$Safe::Isa::_isa ('Test::Deep::Cmp');

	return Test::Deep::bool ($param);
}

1;
