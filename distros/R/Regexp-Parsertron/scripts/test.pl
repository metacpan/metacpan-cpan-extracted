#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

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
	expected	=> '(?^i:Perl|JavaScript)',
	re			=> qr/Perl|JavaScript/i,
},
{
	item		=> 10,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	item		=> 11,
	expected	=> '(?^:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	item		=> 12,
	expected	=> '(?^:a)',
	re			=> qr/a/,
},
{
	item		=> 13,
	expected	=> '(?^i:Perl|JavaScript|(?:Flub|BCPL))',
	re			=> qr/Perl|JavaScript|(?:Flub|BCPL)/i,
},
{
	item		=> 14,
	expected	=> "(?^:(?:(?<n>foo)|(?'n'bar)))",
	re			=> qr/(?:(?<n>foo)|(?'n'bar))/,
},
{
	item		=> 15,
	expected	=> "(?^:(?:(?'n2'foo)|(?<n2>bar)))",
	re			=> qr/(?:(?'n2'foo)|(?<n2>bar))/,
},
{
	item		=> 16,
	expected	=> "(?^:(?:(?'n'foo)|(?'n'bar)))",
	re			=> qr/(?:(?'n'foo)|(?'n'bar))/,
},
{
	item		=> 17,
	expected	=> "(?^:(?:(?'n2'foo)|(?'n2'bar)))",
	re			=> qr/(?:(?'n2'foo)|(?'n2'bar))/,
},
{
	item		=> 18,
	expected	=> '(?^:(?:(?<n2>foo)|(?<n2>bar))\k<n2>)',
	re			=> qr/(?:(?<n2>foo)|(?<n2>bar))\k<n2>/,
},
);

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my(%stats)	= (success => 0, total => 0);
my($count)	= 0;

my($expected);
my($got);
my($result);
my($outcome);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{item} != $limit) );

	$stats{total}++;

	$result		= $parser -> parse(re => $$test{re});
	$outcome	= 1; # Return 1 for fail.

	if ($$test{item} == 10)
	{
		$parser -> append(text => '|C++', uid => 5);
	}

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$outcome	= 0 if ($got eq $expected); # Return 0 for success.

		$stats{success}++ if ($outcome == 0);

		print "Case: $$test{item}. got: $got. expected: $expected. outcome: $outcome (0 is success). \n";
	}
	else
	{
		print "Case $$test{item} failed to return 0 from parse(). \n";
	}

	print '-' x 100, "\n";

	# Reset for next test.

	$parser -> reset;
}

print "Statistics: \n";
print "$_: $stats{$_}. \n" for (sort keys %stats);
