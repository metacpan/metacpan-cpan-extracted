#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

use Try::Tiny;

# ------------------------------------------------

my(@test)	=
(
{
	item		=> 1,
	expected	=> '(?^:)',
	re			=> qr//,
},
{
	item		=> 2,
	expected	=> '(?^:^)',
	re			=> qr/^/,
},
{
	item		=> 3,
	expected	=> '(?^:(?:))',
	re			=> qr/(?:)/,
},
);

my($limit)	= shift || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 0);
my(%stats)	= (success => 0, total => 0);
my($count)	= 0;

my($expected);
my($got);
my($outcome);
my($result);

for my $test (@test)
{
	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($limit > 0) && ($$test{item} != $limit) );

	$stats{total}++;

	try
	{
		$result		= $parser -> parse(re => $$test{re});
		$outcome	= 1; # Return 1 for fail.

		if ($result == 0)
		{
			$got		= $parser -> as_string;
			$expected	= $$test{expected};
			$outcome	= 0 if ($got eq $expected); # Return 0 for success.

			$stats{success}++ if ($outcome == 0);

			#print "Case: $$test{item}. got: $got. expected: $expected. outcome: $outcome (0 is success). \n";
		}
		else
		{
			#print "Case $$test{item} failed to return 0 from parse(). \n";
		}
	}
	catch
	{
		#print map{"# $_\n"} split(/\n/, $_);

		ok(1 == 1, "As expected, unable to parse qr/$$test{re}/"); $count++;
	};

	# Reset for next test.

	$parser -> reset;
}

#print "Statistics: \n";
#print "$_: $stats{$_}. \n" for (sort keys %stats);

print "# Internal test count: $count\n";

done_testing();
