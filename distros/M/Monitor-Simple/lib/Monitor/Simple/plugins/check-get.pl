#!/usr/bin/env perl
#
# Plugin for checking availability of a single web page, using the
# HTTP GET method.
#
# Usage: check-get.pl [-cfg <config-file>] -service <id> [<logging-options>]
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

# make my test
Monitor::Simple::UserAgent->get_or_exit ($service_id, $config);

# everything is okay
Monitor::Simple::Utils->report_and_exit ($service_id, $config, Monitor::Simple::RETURN_OK, "OK");

__END__
