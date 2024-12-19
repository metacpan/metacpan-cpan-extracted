#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper::Config qw(read_config);

plan tests => 1;

my $TEST_FILE = 't/data/test.conf';

my $config = read_config($TEST_FILE, {
	LowerCase       => sub { lc shift },
	ExtraEquals     => sub { shift =~ s/=//gr },
	ExtraWhitespace => sub { shift =~ s/\s+//gr },
});

is_deeply(
	$config,
	{
		LowerCase       => 'value',
		ExtraEquals     => ' None  Of  These',
		ExtraWhitespace => 'Weirdwhitespace'
	},
	'read_config() read file correctly'
);
