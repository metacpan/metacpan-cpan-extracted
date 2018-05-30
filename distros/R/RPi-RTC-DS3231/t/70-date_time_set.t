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

    is
        eval { $o->date_time($o->date_time); 1; },
        1,
        "using properly formatted date ok";

    is
        eval { $o->date_time("blah"); 1; },
        undef,
        "croak ok if datetime format invalid";

    like $@, qr/parameter must be in the format/, "...and error is sane";
}

done_testing();
