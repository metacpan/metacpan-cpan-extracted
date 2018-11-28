#!/usr/bin/env perl
#
# See https://www.nntp.perl.org/group/perl.perl5.porters/2018/07/msg251490.html.

use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my($parser)	= Regexp::Parsertron -> new;
my(@test)	=
(
{
	item		=> 1,
	expected	=> '(?^:(?!(a)b)..)',
	re			=> qr/(?!(a)b)../,
},
{
	item		=> 2,
	expected	=> '(?^:(?!(a)b|ac)..)',
	re			=> qr/(?!(a)b|ac)../,
},
{
	item		=> 3,
	expected	=> '(?^:(?!ac|(a)b)..)',
	re			=> qr/(?!ac|(a)b)../,
},
);

my($expected);
my($got);
my($message);
my($result);

for my $test (@test)
{
	$result = $parser -> parse(re => $$test{re}, verbose => 0);

	if (! defined $result)
	{
		print "Parse is ambiguous. \n";
	}
	elsif ($result == 0) # 0 is success.
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$message	= "$$test{item}: re: $$test{re}. got: $got";
		$message	.= ' (After calling append(...) )' if ($$test{item} == 12);

		print "got: $got. expected: $expected. message: $message. \n";
	}
	else
	{
		print "Case $$test{item} failed to return 0 (== success) from parse(). \n";
	}

	# Reset for next test.

	$parser -> reset;
}
