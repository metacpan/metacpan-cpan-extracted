#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ------------------------------------------------

my(@test)	=
(
{
	item		=> 1,
	expected	=> '(?^:(?#Comment))',
	re			=> qr/(?#Comment)/,
},
{
	item		=> 2,
	expected	=> '(?^:(?a))',
	re			=> qr/(?a)/,
},
{
	item		=> 3,
	expected	=> '(?^:(?a-i))',
	re			=> qr/(?a-i)/,
},
{
	item		=> 4,
	expected	=> '(?^:(?^a))',
	re			=> qr/(?^a)/,
},
{
	item		=> 5,
	expected	=> '(?^:(?a:))',
	re			=> qr/(?a:)/,
},
{
	item		=> 6,
	expected	=> '(?^:(?a:b))',
	re			=> qr/(?a:b)/,
},
{
	item		=> 7,
	expected	=> '(?^:[yY][eE][sS])',
	re			=> qr/[yY][eE][sS]/,
},
{
	item		=> 8,
	expected	=> '(?^:(A|B))',
	re			=> qr/(A|B)/,
},
{
	item		=> 9,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	item		=> 10,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript|C++/i,
},
{
	item		=> 11,
	expected	=> '(?^:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	item		=> 12,
	expected	=> '(?^:^)',
	re			=> qr/^/,
},
);

my($parser)		= Regexp::Parsertron -> new;
my($node_uid)	= 5; # Obtained from displaying and inspecting the tree.

my($count);
my($expected);
my($got);
my($message);
my($result);

for my $test (@test)
{
	$count	= $$test{item}; # Used after the loop.
	$result = $parser -> parse(re => $$test{re});

	if ($count == 9)
	{
		$parser -> append(text => '|C++', uid => $node_uid);
	}

	if ($result == 0) # 0 is success.
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$message	= "$$test{item}: re: $$test{re}. got: $got";
		$message	.= ' (After calling append(...) )' if ($$test{item} == 12);

		is_deeply("$got", $expected, $message);
	}
	else
	{
		BAIL_OUT("Case $$test{item} failed to return 0 (== success) from parse()");
	}

	# Reset for next test.

	$parser -> reset;
}

print "# Internal test count: $count\n";

done_testing;
