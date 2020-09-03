#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count)	= 0;
my(@data)		=
(					# Calls check_key_exists().
	{},				# Fail. Tests 1 .. 6.
	{x => undef},	# Fail.
	{x => ''},		# Pass.
	{x => '0'},		# Pass.
	{x => 0},		# Pass.
	{x => 'a'},		# Pass.
);

my($checker);
my($expected);
my($infix);
my($message);
my($params);
my($result);

for my $i (0 .. $#data)
{
	$checker	= MojoX::Validate::Util -> new;
	$params		= $data[$i];
	$expected	= ($i == 0) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= (defined($$params{x}) ? "'$$params{x}'" : 'undef') . " does ${infix}satisfy a key exists check";
	$result		= $checker -> check_key_exists($params, 'x') ? 1 : 0;

	ok($result == $expected, $message); $test_count++;
}

@data =
(								# Calls check_equal_to().
	{x => '',	y => 'x'},		# Fail. Value can't be empty. Tests 7 .. 10.
	{x => 'x',	y => 'x'},		# Pass.
	{x => 'pw',	y => 'wp'},		# Fail.
	{x => 99,	y => 99},		# Pass.
);

for my $i (0 .. $#data)
{
	$checker	= MojoX::Validate::Util -> new;
	$params		= $data[$i];
	$expected	= ( ($i == 0) || ($i == 2) ) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= (defined($$params{x}) ? "'$$params{x}'" : 'undef') . " does ${infix}satisfy an equal_to check";
	$result		= $checker -> check_equal_to($params, 'x', 'y') ? 1 : 0;

	ok($result == $expected, $message); $test_count++;
}

@data =
(					# Calls check_required().
	{},				# Fail. Tests 11 .. 16.
	{x => undef},	# Fail.
	{x => ''},		# Pass.
	{x => '0'},		# Pass.
	{x => 0},		# Pass.
	{x => 'x'},		# Pass.
);

for my $i (0 .. $#data)
{
	$checker	= MojoX::Validate::Util -> new;
	$params		= $data[$i];
	$expected	= ($i <= 1) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= (defined($$params{x}) ? "'$$params{x}'" : 'undef') . " is ${infix}a required parameter";
	$result		= $checker -> check_required($params, 'x') ? 1 : 0;

	ok($result == $expected, $message); $test_count++;
}

@data =
(											# Calls check_url().
	{homepage => 'localhost'},				# Fail. Tests 17 .. 20.
	{homepage => 'savage.net.au'},			# Pass.
	{homepage => 'http://savage.net.au'},	# Pass.
	{homepage => 'https://savage.net.au'},	# Pass.
);

for my $i (0 .. $#data)
{
	$checker	= MojoX::Validate::Util -> new;
	$params		= $data[$i];
	$expected	= ($i == 0) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= (defined($$params{homepage}) ? "'$$params{homepage}'" : 'undef') . " is ${infix}a required parameter";
	$result		= $checker -> check_url($params, 'homepage') ? 1 : 0;

	ok($result == $expected, $message); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
