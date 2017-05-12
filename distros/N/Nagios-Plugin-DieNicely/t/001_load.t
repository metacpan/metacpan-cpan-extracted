# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use warnings;
use Test::More tests => 1;

BEGIN { use_ok( 'Nagios::Plugin::DieNicely' ); }


