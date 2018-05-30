use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use DateTime;
use RPi::RTC::DS3231;

my $rtc = RPi::RTC::DS3231->new;

say $rtc->temp('f');

$rtc->clock_hours(12);
$rtc->year(2000);

my $dt = DateTime->new($rtc->dt_hash);

my %h = $rtc->dt_hash;

print Dumper \%h;
say $dt;

my $datetime = $rtc->date_time;

my @dt;

if (@dt = $datetime =~ /(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/){
    print "$_\n" for @dt ;
}

say $rtc->date_time($datetime);
