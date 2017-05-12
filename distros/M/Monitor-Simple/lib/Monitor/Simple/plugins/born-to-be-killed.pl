#!/usr/bin/env perl
#
# Plugin for checking availability... well, whatever - because it does
# notjing except to kill itself.
#
# Usage: born-to-be-killed.pl
#
# The return code and STDOUT are compatible with the Nagios plugins
# (see: http://nagios.sourceforge.net/docs/3_0/quickstart.html)
#
# September 2011
# Author: Martin Senger <martin.senger@gmail.com>
#-----------------------------------------------------------------

use warnings;
use strict;

use Monitor::Simple;

kill 9 => $$;

__END__
