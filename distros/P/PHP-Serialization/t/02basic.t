#!/usr/bin/perl

use Test::More tests => 1;

use PHP::Serialization qw(unserialize serialize);
my $data = {
	this_is_a_test => 1.23,
	second_test => [1,2,3],
	third_test => -2,
};
my $encoded = serialize($data);
is_deeply($data, unserialize($encoded));
