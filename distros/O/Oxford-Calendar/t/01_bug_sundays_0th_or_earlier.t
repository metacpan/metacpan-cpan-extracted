use strict;
use warnings;

use Test::More;
use Test::Exception;
use Oxford::Calendar;

plan tests => 1;

my @date = (18, 4, 2010);
my $testdate = 'Sunday, 0th week, Trinity 2010';
is( Oxford::Calendar::ToOx(@date, { mode => 'nearest' } ), $testdate );

