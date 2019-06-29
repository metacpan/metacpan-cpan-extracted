#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::Tools qw(get_event_strength);
plan tests => 7;
my @str = (
	{
		from => 0,
		to   => 300,
	},
	{
		from => 300,
		to   => 600,
	}
);
my @events = (
	{
		type => 'FAC',
		ts   => 0,
	},
	{
		type => 'FAC',
		ts   => 150,
	},
	{
		type => 'FAC',
		ts   => 300,
	},
	{
		type => 'FAC',
		ts   => 600,
	},
	{
		type => 'GOAL',
		ts   => 300,
	},
	{
		type => 'GOAL',
		ts   => 450,
	},
	{
		type => 'GOAL',
		ts   => 700,
	},
);

my @expected = (0,0,1,-1,0,1,-1);
for my $event (@events) {
	my $str = get_event_strength($event, @str);
	my $exp = shift @expected;
	is_deeply($str, $exp == -1 ? undef : $str[$exp], 'expected strength detected');
}