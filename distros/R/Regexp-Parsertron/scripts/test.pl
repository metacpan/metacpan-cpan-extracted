#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

# ------------------------------------------------

my(@test)	=
(
{
	count		=> 1,
	expected	=> '(?^:(?#Comment))',
	re			=> qr/(?#Comment)/,
},
{
	count		=> 2,
	expected	=> '(?^:(?))',
	re			=> qr/(?)/,
},
{
	count		=> 3,
	expected	=> '(?^:(?a))',
	re			=> qr/(?a)/,
},
{
	count		=> 4,
	expected	=> '(?^:(?a-i))',
	re			=> qr/(?a-i)/,
},
{
	count		=> 5,
	expected	=> '(?^:(?^a))',
	re			=> qr/(?^a)/,
},
{
	count		=> 6,
	expected	=> '(?^:(?a:))',
	re			=> qr/(?a:)/,
},
{
	count		=> 7,
	expected	=> '(?^:(?a:b))',
	re			=> qr/(?a:b)/,
},
{
	count		=> 8,
	expected	=> '(?^:(?:))',
	re			=> qr/(?:)/,
},
{
	count		=> 9,
	expected	=> '(?^:[yY][eE][sS])',
	re			=> qr/[yY][eE][sS]/,
},
{
	count		=> 10,
	expected	=> '(?^:(A|B))',
	re			=> qr/(A|B)/,
},
{
	count		=> 11,
	expected	=> '(?^i:Perl|JavaScript)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 12,
	expected	=> '(?^i:Perl|JavaScript|C++)',
	re			=> qr/Perl|JavaScript/i,
},
{
	count		=> 13,
	expected	=> '(?^:/ab+bc/)',
	re			=> '/ab+bc/',
},
{
	count		=> 14,
	expected	=> '(?^:a)',
	re			=> qr/a/,
},
{
	count		=> 15,
	expected	=> '(?^:(?:(?<n>foo)|(?<n>bar))\k<n>)',
	re			=> qr/(?:(?<n>foo)|(?<n>bar))\k<n>/,
},
);

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my(%stats)	= (success => 0, total => 0);

my($expected);
my($got);
my($result);
my($success);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{count} != $limit) );

	$stats{total}++;

	$result		= $parser -> parse(re => $$test{re});
	$success	= 1;

	if ($$test{count} == 12)
	{
		$parser -> append(text => '|C++', uid => 6);
	}

	if ($result == 0)
	{
		$got		= $parser -> as_string;
		$expected	= $$test{expected};
		$success	= 0 if ($got eq $expected);

		$stats{success}++ if ($success == 0);

		say "$$test{count}: got: $got. expected: $expected. outcome: $success (0 is success). ";
	}
	else
	{
		say "Test $$test{count} failed to return 0 from parse(). ";
	}

	say '-' x 50;

	# Reset for next test.

	$parser -> reset;
}

print "Statistics: ";
print "$_: $stats{$_}. " for (sort keys %stats);
say '';
