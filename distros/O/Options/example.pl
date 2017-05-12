#!/usr/bin/env perl

use strict;
use warnings;

use Options;

# Define the options supported
my $options = new Options(params => [
						['port', 'p', undef, 'The port to connect to.'],
						['host', 'h', 'localhost', 'The host to connect to.']
						],
						flags =>  [
						['quit', 'q', 'Quit after connecting.'],
						['help', 'h', 'Display this usage guide.'],
						]);

# Parse the default option source (@ARGV)
my %results = $options->get_options();

# Provide usage
if($options->get_result('help')){
	$options->print_usage();
	exit(1);
}

# It is also acceptable to access the results hash directly,
# but the following method is generally a better approach.
# See Options.pm POD docs for more info.
my $host = $options->get_result('host');
my $port = $options->get_result('port');

my $stay_connected = !$options->get_result('quit');

my $command = "ssh $host:$port";
if($stay_connected){
	$command .= ' -N';
}

print "Result command: $command\n\n";

