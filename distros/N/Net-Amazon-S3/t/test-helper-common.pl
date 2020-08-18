
use strict;
use warnings;
use utf8;

use Test::Deep      qw[ !cmp_deeply ];
use Test::More      import => [qw[ !ok !is !is_deeply ]];
use Test::Warnings  qw[ :no_end_test had_no_warnings ];

sub ok {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	Test::More::ok $params{got}, $title;
}

sub it {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	Test::Deep::cmp_deeply $params{got}, $params{expect}, $title;
}

sub is {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	Test::More::is $params{got}, $params{expect}, $title;
}

1;
