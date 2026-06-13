use warnings;
use strict;

use lib 't/';

use RPiTest;

rpi_multi_check();

system('t/multi/test_full.sh');

