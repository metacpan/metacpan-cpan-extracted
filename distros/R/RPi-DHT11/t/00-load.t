use strict;
use warnings;

use Test::More;

BEGIN { use_ok('RPi::DHT11') };

my $mod = 'RPi::DHT11';

can_ok $mod, 'temp';
can_ok $mod, 'humidity';
can_ok $mod, 'cleanup';

done_testing();
