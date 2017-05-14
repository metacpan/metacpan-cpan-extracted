use strict;
use warnings;

use lib('t');
use _driver;

use ProgressMonitor::Stringify::Fields::ETA;

runtest(
		ProgressMonitor::Stringify::Fields::ETA->new,
		0, 0, [0, 0, 0], 0,
		[
		 '--:--:--', '--:--:--',  '00:00:00'
		]
	   );
