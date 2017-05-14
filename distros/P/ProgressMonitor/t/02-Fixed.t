use strict;
use warnings;

use lib('t');
use _driver;

use ProgressMonitor::Stringify::Fields::Fixed;

runtest(
		ProgressMonitor::Stringify::Fields::Fixed->new({text => "$$"}),
		0, 0, [0, 0, 0], 0,
		[
		 "$$", "$$", "$$"
		]
	   );
