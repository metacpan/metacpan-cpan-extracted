use strict;
use warnings;

use Test::More;
use Test::Exception;
use Oxford::Calendar;

plan tests => 4;

my @date = (25, 3, 2012);
my $testdate = 'Sunday, 11th week, Hilary 2012';
is( Oxford::Calendar::ToOx(@date, { mode => 'nearest' } ), $testdate );
@date = (1, 4, 2012);
$testdate = 'Sunday, -2nd week, Trinity 2012';
is( Oxford::Calendar::ToOx(@date, { mode => 'nearest' } ), $testdate );
@date = (28, 3, 2010);
$testdate = 'Sunday, 11th week, Hilary 2010';
is( Oxford::Calendar::ToOx(@date, { mode => 'nearest' } ), $testdate );
@date = (4, 4, 2010);
isnt( Oxford::Calendar::ToOx(@date, { mode => 'nearest' } ), $testdate );
