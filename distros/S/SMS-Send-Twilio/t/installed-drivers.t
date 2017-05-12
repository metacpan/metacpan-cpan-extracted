use strict;
use warnings;

use Test::More;
use SMS::Send;

my @drivers = SMS::Send->installed_drivers;

ok ( scalar (@drivers) >= 1, 'Found at least 1 driver' );
ok ( scalar (grep { $_ eq 'Twilio' } @drivers ) == 1, 'Found "Twilio" driver' );

done_testing;
