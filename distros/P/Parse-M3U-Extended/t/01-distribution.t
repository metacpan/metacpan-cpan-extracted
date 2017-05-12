#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

eval {
	require Test::Distribution
};

if($@) {
	plan skip_all => 'Test::Distribution is not installed';
} else {
	Test::Distribution->import(
		podcoveropts => { trustme => [qw/new/] },
	);
}

