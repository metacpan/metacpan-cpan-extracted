#
# Signal handlers for the test suite.
#
# This module provides a global handler for SIGHUP and SIGUSR1 that simply
# increments a counter.  The counter variables are exported as $USR1 and $HUP
# to the caller.  Initial counter values are 0.
package My::Test::SignalHandlers;

use strict;
use warnings;

my $USR1 = 0;
my $HUP  = 0;

$SIG{USR1} = sub { $USR1++ };
$SIG{HUP}  = sub { $HUP++ };

# Exporter.pm exports a COPY of the scalars.  We need to make sure both scalars
# point to the same variable.  So we export by hand.
sub import {
    my $class = shift;

    my $caller = caller();

    no strict 'refs';
    *{"${caller}::USR1"} = \$USR1;
    *{"${caller}::HUP"}  = \$HUP;
}

1;
