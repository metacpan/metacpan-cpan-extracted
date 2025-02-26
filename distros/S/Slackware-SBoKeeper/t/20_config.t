#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use Slackware::SBoKeeper::Config qw(read_config);

plan tests => 1;

my $TEST_FILE = 't/data/test.conf';

my $config = read_config($TEST_FILE, {
	LowerCase       => sub { lc shift },
	ExtraEquals     => sub { shift =~ s/=//gr },
	ExtraWhitespace => sub { shift =~ s/\s+//gr },
	Zero            => sub { shift },
	TestFile        => sub { $_[1]->{File} },
});

is_deeply(
	$config,
	{
		LowerCase       => 'value',
		ExtraEquals     => ' None  Of  These',
		ExtraWhitespace => 'Weirdwhitespace',
		Zero            => '0',
		TestFile        => File::Spec->rel2abs($TEST_FILE),
	},
	'read_config() read file correctly'
);
