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

    for (1..31){
        is $o->mday($_), $_, "setting mday to $_ ok";
    }
}

{   # out of bounds/illegal chars

    my $o = $mod->new;

    for (qw(0 32)){
        is eval { $o->mday($_); 1; }, undef, "setting dom to '$_' fails ok";
    }
}
done_testing();
