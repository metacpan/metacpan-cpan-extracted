#!/usr/bin/env perl
#
# This is a copy of t/01.range.t, without the Test::More parts.

use strict;
use warnings;

use MojoX::Validate::Util;

# ------------------------------------------------

my(%count)		= (fail => 0, pass => 0, total => 0);
my($checker)	= MojoX::Validate::Util -> new;

$checker -> add_dimension_check;

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

my($expected);
my($params);

for my $i (0 .. $#data)
{
	$count{total}++;

	$params		= $data[$i];
	$expected	= ( ($i == 1) || ($i == $#data) ) ? 0 : 1;

	$count{fail}++ if ($expected == 0);

	$count{pass}++ if ($checker -> check_dimension($params, 'height', ['cm', 'm']) == 1);
}

print "Test counts: \n", join("\n", map{"$_: $count{$_}"} sort keys %count), "\n";
