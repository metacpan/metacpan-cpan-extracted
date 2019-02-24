#!/usr/bin/perl
# $Id: functions.t,v 1.1 2019/02/23 02:55:55 cmanley Exp $
use strict;
use Test::More;
use lib qw(../lib);
use MySQL::Compress qw(
	mysql_compress
	mysql_uncompress
	mysql_uncompressed_length
);

my @tests = (
	{
		'compressed'	=> pack('H*', '0C000000789CF348CDC9C95728CF2FCA495104001D09045E'),
		'expect'		=> 'Hello world!',
	},
	{
		'compressed'	=> pack('H*', '0C000000789CF348CDC9C96728CF2FCA495104001C29043E'),
		'expect'		=> "Hello\x00world!",
	},
	{
		'compressed'	=> '',
		'expect'		=> '',
	},
	{
		'compressed'	=> undef,
		'expect'		=> undef,
	},
	{
		'compressed'	=> pack('H*', '01000000789C33000000310031'),
		'expect'		=> '0',
	},
	{
		'compressed'	=> pack('H*', '01000000789C53000000210021'),
		'expect'		=> ' ',
	},
	{
		'compressed'	=> pack('H*', '03000000789C4B4A8E0200024901202E'),	# ends with space then dot
		'expect'		=> 'bcZ',
	},
);


if (1) {
	plan tests => scalar(@tests) * 4 + 2;

	foreach my $test (@tests) {
		my $compressed = $test->{'compressed'};
		my $expect = $test->{'expect'};
		require bytes;
		$expect = defined($expect) ? bytes::length($expect) : undef;
		my $result = mysql_uncompressed_length($compressed);
		is($result, $expect, 'mysql_uncompressed_length() returns ' . (defined($expect) ? $expect : 'undef'));
	}

	foreach my $test (@tests) {
		my $compressed = $test->{'compressed'};
		my $expect = $test->{'expect'};
		my $result = mysql_uncompress($compressed);
		is($result, $expect, 'mysql_uncompress() returns ' . (defined($expect) ? "\"$expect\"" : 'undef'));
	}

	foreach my $test (@tests) {
		my $expect = $test->{'expect'};
		my $result = mysql_uncompress(mysql_compress($test->{'expect'}));
		is($result, $expect, 'mysql_uncompress(mysql_compress(' . (defined($expect) ? "\"$expect\"" : 'undef') . ') returns original value');
	}

	foreach my $test (@tests) {
		my $expect = $test->{'expect'};
		my $result = mysql_uncompress(mysql_compress($test->{'expect'}, 9));
		is($result, $expect, 'mysql_uncompress(mysql_compress(' . (defined($expect) ? "\"$expect\"" : 'undef') . ', 9) returns original value');
	}

	# Test compression levels
	if (1) {
		my $h;
		open($h, __FILE__) || die('Failed to open ' . __FILE__ . ": $!");
		my $data = join('', <$h>);
		close($h);
		$data .= "$data$data$data$data";
		require bytes;
		my $len_low     = bytes::length(mysql_compress($data, 1));
		my $len_default = bytes::length(mysql_compress($data));
		my $len_max     = bytes::length(mysql_compress($data, 9));
		cmp_ok($len_low, '>', $len_default, "result of low compression level ($len_low) is larger than result of default compression level ($len_default)");
		cmp_ok($len_max, '<', $len_default, "result of max compression level ($len_max) is smaller than result of default compression level ($len_default)");
	}
}

#done_testing();


unless($ENV{'HARNESS_ACTIVE'}) {
	require Data::Dumper; Data::Dumper->import('Dumper'); local $Data::Dumper::Terse = 1;
	if (0) {
		foreach my $test (@tests) {
			my $compressed = $test->{'compressed'};
			my $expect = $test->{'expect'};
			#my $result = mysql_uncompress($compressed);
			my $result = mysql_uncompressed_length($compressed);
			print Dumper($result);
		}
	}
	if (0) {
		my $h;
		open($h, __FILE__) || die('Failed to open ' . __FILE__ . ": $!");
		my $data = join('', <$h>);
		close($h);
		require bytes;
		print "default: " . bytes::length(mysql_compress($data)) . "\n";
		for my $level (1..9, undef) {
			print "$level: " . bytes::length(mysql_compress($data, $level)) . "\n";
		}
	}
}
