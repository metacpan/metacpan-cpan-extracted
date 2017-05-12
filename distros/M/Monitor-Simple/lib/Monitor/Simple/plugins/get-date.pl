#!/usr/bin/env perl
#
# Plugin for checking availability and (sometimes) correctness
# of an application (whose name is part of this script's name).
#
# Usage: get-date.pl
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
use constant { MY_ID => 'date' };

# read command-line arguments and configuration
my ($config_file, $service_id) = Monitor::Simple::Utils->parse_plugin_args (MY_ID, @ARGV);
my $config = Monitor::Simple::Config->get_config ($config_file);

# everything is okay
Monitor::Simple::Utils->report_and_exit (MY_ID, $config, Monitor::Simple::RETURN_OK, scalar localtime);

__END__
