#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Monit::HTTP ':constants', '%MONIT_ACTIONS_REV';

diag('Test the tricky export of constants is working');
is( ACTION_MONITOR, 'monitor', 'ACTION_MONITOR exported correctly' );
is( $MONIT_ACTIONS_REV{'stop'}, 'ACTION_STOP', '%MONIT_ACTIONS_REV exported correctly' );


