use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

if (! $ENV{RPI_RTC}){
    plan(skip_all => "Skipping: RPI_RTC environment variable not set");
}

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    $o->clock_hours(24);

    $o->year(2018);
    $o->month(5);
    $o->mday(17);
    $o->hour(23);
    $o->min(55);
    $o->sec(01);

    my %dt = $o->dt_hash;

    my @valid = qw(year month day hour minute second);

    for (keys %dt){
        is exists $dt{$_}, 1, "$_ key exists ok";

        if ($_ eq 'year'){
            is $dt{$_}, 2018, "$_ ok";
            next;
        }

        like $dt{$_}, qr/^\d{2}$/, "$_ contains the proper values ok";
    }

    $o->clock_hours(24);
}

done_testing();
