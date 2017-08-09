#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count) = 0;

my(@data) =
(
	{height => ''},				# Pass.
	{height => '1'},			# Fail. No unit.
	{height => '1cm'},			# Pass.
	{height => '1 cm'},			# Pass.
	{height => '1m'},			# Pass.
	{height	=> '40-70.5cm'},	# Pass.
	{height	=> '1.5 -2 m'},		# Pass.
	{height => 'z1'},			# Fail. Not numeric.
);

my($checker);
my($expected);
my($infix);
my($message);
my($params);

for my $i (0 .. $#data)
{
	$checker	= MojoX::Validate::Util -> new;
	$params		= $data[$i];
	$expected	= ( ($i == 1) || ($i == $#data) ) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= "Height '$$params{height}' is ${infix}a valid height";

	ok($checker -> check_dimension($params, 'height', ['cm', 'm']) == $expected, $message); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
