#!/usr/bin/env perl
#
# Testing plugin. It exits with the exit code given in ARGV[0] with
# the message given in ARGV[1].
#
# Usage: copy-message.pl <exit-code> <message>
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
#use Log::Log4perl qw(:easy);
use constant { MY_ID => 'copy-message' };

Monitor::Simple::Utils->report_and_exit (MY_ID, undef, $ARGV[0], $ARGV[1]);

__END__
