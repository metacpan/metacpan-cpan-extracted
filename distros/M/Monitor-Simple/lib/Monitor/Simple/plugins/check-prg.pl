#!/usr/bin/env perl
#
# Plugin for checking any command-line program by executing it with
# given arguments and reporting warning if there was any STDERR and
# checking STDOUT for expected values (defined in the given, or
# default, configuration file).
#
# Usage: check-prg.pl [-cfg <config-file>] -service <id> [<logging-options>]
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
use Log::Log4perl qw(:easy);

# read command-line arguments and configuration
my ($config_file, $service_id) = Monitor::Simple::Utils->parse_plugin_args ('', @ARGV);
LOGDIE ("Unknown service (missing parameter '-service <id>')\n")
    unless $service_id;
my $config = Monitor::Simple::Config->get_config ($config_file);

# make my tests
Monitor::Simple::Utils->exec_or_exit ($service_id, $config);

# everything is okay
Monitor::Simple::Utils->report_and_exit ($service_id, $config, Monitor::Simple::RETURN_OK, "OK");

__END__
