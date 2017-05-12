package PDTest;
use 5.0.12;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');

use Panda::Time qw/
    tzset tzget tzname tzdir gmtime localtime timegm timegmn timelocal timelocaln systimelocal
    available_zones use_embed_zones use_system_zones
/;

use Panda::Date qw/now date rdate rdate_const idate today today_epoch :const/;

use_embed_zones();
tzset('Europe/Moscow');

sub import {
    my $stash = \%{PDTest::};
    my $caller = caller();
    *{"${caller}::$_"} = *{"PDTest::$_"} for keys %$stash;
}

1;
