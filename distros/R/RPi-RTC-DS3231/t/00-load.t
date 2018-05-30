use strict;
use warnings;
use Test::More;


if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

use_ok( 'RPi::RTC::DS3231' ) || print "Bail out!\n";

diag( "Testing RPi::RTC::DS3231 $RPi::RTC::DS3231::VERSION, Perl $], $^X" );

done_testing();
