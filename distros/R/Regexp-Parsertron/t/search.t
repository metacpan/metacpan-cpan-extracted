#!/usr/bin/env perl

use strict;
use warnings;

use Regexp::Parsertron;

# Warning: Can't use Test2 or Test::Stream because of the '#' in the regexps.

use Test::More;

# ---------------------

my($re)		= qr/(?:(?<n2>Perl5)|(?<n2>Perl6))\k<n2>/;
my($parser)	= Regexp::Parsertron -> new(re => $re);

# Return 0 for success and 1 for failure.

my($result)			= $parser -> parse(re => $re); # 0 is success.
my($target)			= 'Perl';
my($found_regexp_1)	= $parser -> search($target);
my($found_regexp_2)	= $parser -> search(qr/$target/);
my($found_string)	= $parser -> find($target);
my($count)			= 0;

ok($#$found_regexp_1 == 1, "Calling search('$target'). Found the expected number of nodes"); $count++;
ok($#$found_regexp_2 == 1, "Calling search(qr/$target/). Found the expected number of nodes"); $count++;
ok($#$found_string == 1, "Calling find('$target'). Found the expected number of nodes"); $count++;

print "# Internal test count: $count\n";

done_testing();

