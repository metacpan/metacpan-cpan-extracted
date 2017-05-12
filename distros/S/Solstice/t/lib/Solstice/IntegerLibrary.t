#!/usr/local/bin/perl

use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => undef;

use Test::More;
#use Test::More qw(no_plan);

use Solstice::IntegerLibrary qw(inttobytes inttotime inttoword inttoroman inttolatin);

use constant SUCCESS       => 1;
use constant FAIL          => 0;

use constant TEST_COUNT     => 68;    # How many tests will be run in this script?


plan(tests => TEST_COUNT);


### Add your own test blocks here

my $test_val;  # test value for comparisons   

####################################################
# inttobytes ($int, $compact)

# int < 0
is(inttobytes("-1"), "1 bytes", "inttobytes: negative number");

# int < 1000
is(inttobytes("1"), "1 bytes", "inttobytes: bytes lower bound");
is(inttobytes("999"), "999 bytes", "inttobytes: bytes upper bound");

# 999 < int < 1,000,000
is(inttobytes("1000"), "1.0 Kbytes", "inttobytes:  kbytes lower bound");
is(inttobytes("999999"), "1000.0 Kbytes", "inttobytes:  kbytes upper bound");

# 999,999 < int < 1,000,000,000
is(inttobytes("1000000"), "1.00 Mbytes", "inttobytes:  Mbytes lower bound");
is(inttobytes("999999999"), "1000.00 Mbytes", "inttobytes:  Mbytes upper bound");

# 999,999,999 > int < 1,000,000,000,000
is(inttobytes("1000000000"), "1.00 Gbytes", "inttobytes:  Gbytes lower bound");
is(inttobytes("999999999999"), "1000.00 Gbytes", "inttobytes:  Gbytes upper bound");

is(inttobytes("1000000000000"), "1.00 Tbytes", "inttobytes:  Tbytes lower bound");
is(inttobytes("999999999999999"), "1000.00 Tbytes", "inttobytes:  Tbytes upper bound");

# int > 1,000,000,000,000,000
is(inttobytes(100_000_000_000_000_000_000), "100000000.00 Tbytes", "int > 1000 Tbytes");

#testing compact
is(inttobytes("500", TRUE), "500 B", "inttobytes: bytes compact");
is(inttobytes("500000", TRUE), "500.0 KB", "inttobytes: Kbytes compact");
is(inttobytes("5000000", TRUE), "5.00 MB", "inttobytes:  Mbytes compact");
is(inttobytes("5000000000", TRUE), "5.00 GB", "inttobytes:  Gbytes compact");

################################################################################
# inttotime($int, $compact)


# fractional seconds
is(inttotime(.9, TRUE), '00:00:00', "inttotime: decimal input") || diag("Unexpected handling of fractional seconds (should drop fractions)");
is(inttotime(2.9, TRUE), '00:00:02', "inttotime: decimal input") || diag("Unexpected handling of fractional seconds (should drop fractions)");

# negative seconds
is(inttotime(-234,TRUE), '00:03:54', "inttotime: negative input") || diag("reported incorrect interval for negative time");

is(inttotime(45), "45 sec", "intotime: seconds");
is(inttotime(6 * 60), "6 min", "intotime: minutes");
is(inttotime(6 * 3600), "6 hr", "intotime: hours");
is(inttotime(6 * 3600 + 6 * 60 + 45), "6 hr 6 min 45 sec", "inttotime: seconds, minutes, and hours");

# compact
is(inttotime(6 * 3600 + 6 * 60 + 45, TRUE), "06:06:45", "inttotime: compact seconds, minutes, and hours");





###################################################################################
# inttoword($int)

# outside bounds
is(inttoword(-1), -1, "inttoword: negative value") || diag("Altered a number that should not be translated");
is(inttoword(0), 0, "inttoword: zero value") || diag("Altered a number that should not be translated");
is(inttoword(10), 10, "inttoword: > 9") || diag("Altered a number that should not be translated");

# at bounds
is(inttoword(1), "one", "inttoword: lower bound");
is(inttoword(9), "nine", "inttoword: upper bound");


###################################################################################
# inttoroman($int, $upper)
# Returns $int transformed into a roman numeral string; $int
# must be a non-zero integer between -4000 and 4000.
# $upper specifies upper-case

# outside bounds
is(inttoroman(-4001), undef, "inttoroman: outside lower bound") || diag("Returned a value for out-of-bounds input");
is(inttoroman(4001), undef, "inttoroman: outside higher bound") || diag("Returned a value for out-of-bounds input");

is(inttoroman(1), "i", "inttoroman: lower one");
is(inttoroman(1, TRUE), "I", "inttoroman: upper one");

is(inttoroman(2), "ii", "inttoroman: lower two");
is(inttoroman(2, TRUE), "II", "inttoroman: upper two");

is(inttoroman(3), "iii", "inttoroman: lower three");
is(inttoroman(3, TRUE), "III", "inttoroman: upper three");

is(inttoroman(4), "iv", "inttoroman: lower four");
is(inttoroman(4, TRUE), "IV", "inttoroman: upper four");

is(inttoroman(5), "v", "inttoroman: lower five");
is(inttoroman(5, TRUE), "V", "inttoroman: upper five");

is(inttoroman(7), "vii", "inttoroman: lower seven");
is(inttoroman(7, TRUE), "VII", "inttoroman: upper seven");

is(inttoroman(9), "ix", "inttoroman: lower nine");
is(inttoroman(9, TRUE), "IX", "inttoroman: upper nine");

is(inttoroman(10), "x", "inttoroman: lower ten");
is(inttoroman(10, TRUE), "X", "inttoroman: upper ten");

is(inttoroman(14), "xiv", "inttoroman: lower fourteen");
is(inttoroman(14, TRUE), "XIV", "inttoroman: upper fourteen");

is(inttoroman(40), "xl", "inttoroman: lower fourty");
is(inttoroman(40, TRUE), "XL", "inttoroman: upper fourty");

is(inttoroman(50), "l", "inttoroman: lower fifty");
is(inttoroman(50, TRUE), "L", "inttoroman: upper fifty");


is(inttoroman(90), "xc", "inttoroman: lower ninety");
is(inttoroman(90, TRUE), "XC", "inttoroman: upper ninety");


is(inttoroman(100), "c", "inttoroman: lower one hundred");
is(inttoroman(100, TRUE), "C", "inttoroman: upper one hundred");

is(inttoroman(500), "d", "inttoroman: lower five hundred");
is(inttoroman(500, TRUE), "D", "inttoroman: upper five hundred");

is(inttoroman(1000), "m", "inttoroman: lower thousand");
is(inttoroman(1000, TRUE), "M", "inttoroman: upper thousand");

is(inttoroman(3999), "mmmcmxcix", "inttoroman: lower 3999");
is(inttoroman(3999, TRUE), "MMMCMXCIX", "inttoroman: upper 3999");


############################################################################
# inttolatin($int, $upper)
# Returns $int transformed into a latin alphabet string,
# where $int is a non-zero integer. $upper specifies upper-case.

is(inttolatin(1), "a", "inttolatin: lower single char bound");
is(inttolatin(26), "z", "inttolatin: upper single char bound");
is(inttolatin(27), "aa", "inttolatin: upper single char bound + 1");
is(inttolatin(30), "ad", "inttolatin: upper single char bound");
is(inttolatin(53), "ba", "inttolatin: 2 * upper single char bound + 1");








exit 0;


=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
