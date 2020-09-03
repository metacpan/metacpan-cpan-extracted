#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count) = 0;

my(@data) =
(
	{height => ''},				# 0: Pass.
	{height => '1cm'},			# 1: Pass.
	{height => '1 cm'},			# 2: Pass.
	{height => '1m'},			# 3: Pass.
	{height	=> '40-70.5cm'},	# 4: Pass.
	{height	=> '1.5 -2 m'},		# 5: Pass.
	{height => '1'},			# 6: Fail. No unit.
	{height => 'z1'},			# 7: Fail. Not numeric.
	{height => '1,2m'},			# 8: Fail.
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
	$expected	= ($i <= 5) ? 1 : 0;		# 0 => Fail; 1 => Pass.
	$infix		= $expected ? '' : 'not ';	# 'not ' => Fail; '' => Pass.
	$message	= "Height '$$params{height}' is ${infix}a valid height";

	ok($checker -> check_dimension($params, 'height', ['cm', 'm']) == $expected, $message); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
