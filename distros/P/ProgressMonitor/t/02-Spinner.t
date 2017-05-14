use strict;
use warnings;

use lib('t');
use _driver;

use ProgressMonitor::Stringify::Fields::Spinner;

runtest(ProgressMonitor::Stringify::Fields::Spinner->new,
		0, 10, [0, 0, 0], 0, ['-', '\\', '|', '/', '-', '\\', '|', '/', '-', '\\', '|', '/', '-']);
