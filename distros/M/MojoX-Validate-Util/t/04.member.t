#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count)	= 0;
my(@data)		=
(
	{love_popup_ads => 'No'},	# Pass.
	{love_popup_ads => 'Nyet'},	# Fail
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
	$expected	= ($i == 0) ? 1 : 0;
	$infix		= $expected ? '' : 'not ';
	$message	= (defined($$params{love_popup_ads}) ? "'$$params{love_popup_ads}'" : 'undef') . " does ${infix}satisfy a membership check";
	$result		= $checker -> check_member($params, 'love_popup_ads', ['Yes', 'No']) ? 1 : 0;

	ok($result == $expected, $message); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
