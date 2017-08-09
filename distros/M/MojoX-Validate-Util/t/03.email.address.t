#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count)	= 0;
my(@data)		=
(
	{email_address => ''},					# Fail required, pass optional.
	{email_address => 'ron@savage.net.au'},	# Pass.
);

my($checker);
my($expected, $error);
my($infix);
my($method, $message);
my($params);
my($suffix);

for my $i (0 .. $#data)
{
	for my $kind (qw/required optional/)
	{
		$checker	= MojoX::Validate::Util -> new;
		$params		= $data[$i];
		$expected	= ($i == 0) ? 0 : 1;
		$infix		= $expected ? '' : 'not ';
		$suffix		= ($kind eq 'required') ? '' : 'n';
		$method		= "check_$kind";
		$message	= "i: $i. kind: $kind. Calling $method(). '$$params{email_address}' is ${infix}a$suffix $kind email address";

		ok($checker -> $method($params, 'email_address') == $expected, $message); $test_count++;

		$error		= $checker -> validation -> error('email_address');
		$error		= defined($error) ? join(', ', @$error) : '';
		$expected	= ( ($i == 0) && ($kind eq 'required') ) ? 'required' : '';

		ok($error eq $expected, "i: $i. kind: $kind. Calling validation's error(). error: $error. expected: $expected"); $test_count++;
	}
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
