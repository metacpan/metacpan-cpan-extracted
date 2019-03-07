# PiFlash - flash a Raspberry Pi image to an SD card, with safety checks to avoid erasing wrong device
# This module/script uses sudo to perform root-privileged functions.
# by Ian Kluft
use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl
use PiFlash::State;
use PiFlash::Command;
use PiFlash::Inspector;
use PiFlash::MediaWriter;

package PiFlash;
$PiFlash::VERSION = '0.2.1';
use autodie; # report errors instead of silently continuing ("die" actions are used as exceptions - caught & reported)
use Getopt::Long; # included with perl
use File::Basename; # included with perl
use File::Path qw(make_path); # RPM: perl-File-Path, DEB: included with perl
use Module::Pluggable require => 1; # RPM: perl-Module-Pluggable, DEB: libmodule-pluggable-perl

# ABSTRACT: Raspberry Pi SD-flashing script with safety checks to avoid erasing the wrong device


# return default list of state category names
# this is made available externally so it can be accessed for testing
sub state_categories {
	return (
		"cli_opt",		# options received from command line
		"config",		# configuration settings loaded from YAML $XDG_CONFIG_DIR/piflash
		"hook",			# hook functions: callbacks managed by PiFlash::Hook
		"input",		# input file info from PiFlash::Inspector
		"log",			# log of commands and events
		"output",		# output device info from PiFlash::Inspector
		"plugin",		# plugin modules assigned storage here
		"system",		# system info from PiFlash::Inspector
	);
};

# print program usage message
sub usage
{
	say STDERR "usage: ".basename($0)." [--verbose] [--resize] [--config conf-file] input-file output-device";
	say STDERR "       ".basename($0)." [--verbose] [--config conf-file] --SDsearch";
	say STDERR "       ".basename($0)." --version";
	exit 1;
}

# print numbers with readable suffixes for megabytes, gigabytes, terabytes, etc
# handle more prefixes than currently needed for extra scalability to keep up with Moore's Law for a while
sub num_readable
{
	my $num = shift;
	my @suffixes = qw(bytes KB MB GB TB PB EB ZB);
	my $magnitude = int(log($num)/log(1024));
	if ($magnitude > $#suffixes) {
		$magnitude = $#suffixes;
	}
	my $num_base = $num/(1024**($magnitude));
	return sprintf "%4.2f%s", $num_base, $suffixes[$magnitude];
}

# initialize enabled plugins
sub init_plugins
{
	# get list of available plugin modules
	my $plugin_data = PiFlash::State::plugin();

	# get list of enabled plugins from command line and config file
	my %enabled;
	if (PiFlash::State::has_cli_opt("plugin")) {
		foreach my $plugin ( split(/[^\w:]+/, PiFlash::State::cli_opt("plugin") // "")) {
			next if $plugin eq "";
			$plugin =~ s/^.*:://;
			$enabled{$plugin} = 1;
		}
	}
	if (PiFlash::State::has_config("plugin")) {
		foreach my $plugin ( split(/[^\w:]+/, PiFlash::State::config("plugin") // "")) {
			next if $plugin eq "";
			$plugin =~ s/^.*:://;
			$enabled{$plugin} = 1;
		}
	}

	# for each enabled plugin, allocate state storage, load its config (if any) and run its init method
	my @plugins_available = PiFlash->plugins();
	foreach my $plugin (@plugins_available) {
		$plugin =~ /^PiFlash::Plugin::([A-Z]\w+)$/ or next;
		my $modname = $1;
		if (exists $enabled{$modname} and $plugin->can("init")) {
			if (exists $plugin_data->{$modname}) {
				next; # skip if its storage area exists
			}
			my @data;
			if (exists $plugin_data->{docs}{$modname}) {
				push @data, $plugin_data->{docs}{$modname};
			}
			$plugin_data->{$modname} = {};
			$plugin->init($plugin_data->{$modname}, @data);
		}
	}
}

# piflash script main routine to be called from exception-handling wrapper
sub piflash
{
	# initialize program state storage
	PiFlash::State->init(state_categories());

	# collect and validate command-line arguments
	do { GetOptions (PiFlash::State::cli_opt(), "verbose", "sdsearch", "version", "resize", "config:s", "plugin:s"); };
	if ($@) {
		# in case of failure, add state info if verbose mode is set
		PiFlash::State->error($@);
	}

	# if --version option was selected, print the version number and exit
	if (PiFlash::State::has_cli_opt("version")) {
		say $PiFlash::VERSION;
		return;
	}

	# read configuration
	my $config_file;
	if (PiFlash::State::has_cli_opt("config")) {
		$config_file = PiFlash::State::cli_opt("config");
	} else {
		my $config_dir = $ENV{XDG_CONFIG_DIR} // ($ENV{HOME}."/.local");
		make_path($config_dir);
		$config_file = $config_dir."/piflash";
	}
	if ( -f $config_file ) {
		PiFlash::State::read_config($config_file);
	}

	# print usage info if there aren't sufficient parameters to do anything
	my $param_ok = 0;
	if (PiFlash::State::has_cli_opt("sdsearch")) {
		$param_ok = 1;
	}
	if ($#ARGV == 1 and -f $ARGV[0] and -b $ARGV[1]) {
		$param_ok = 1;
	}
	# TODO insert subcommand processing here
	if (!$param_ok) {
		usage();
	}

	# initialize enabled plugins
	# this has to be done after command line and configuration processing so we know what the user has enabled
	# since PiFlash runs root code, plugins are disabled by default
	init_plugins();

	# collect system info: kernel specs and locations of needed programs
	PiFlash::Inspector::collect_system_info();

	# if --SDsearch option was selected, search for SD cards and exit
	if (PiFlash::State::has_cli_opt("sdsearch")) {
		# SDsearch mode: print list of SD card devices and exit
		PiFlash::Inspector::sd_search();
		return;
	}

	# call hook for after reading command-line options
	PiFlash::Hook::cli_options();

	# set input and output paths
	PiFlash::State::input("path", $ARGV[0]);
	PiFlash::State::output("path", $ARGV[1]);
	say "requested to flash ".PiFlash::State::input("path")." to ".PiFlash::State::output("path");
	say "output device ".PiFlash::State::output("path")." will be erased";

	# check the input file
	PiFlash::Inspector::collect_file_info();
	
	# check the output device
	PiFlash::Inspector::collect_device_info();

	# check input file and output device sizes
	if (PiFlash::State::input("size") > PiFlash::State::output("size")) {
		PiFlash::State->error("output device not large enough for this image - currently have: "
			.num_readable(PiFlash::State::output("size")).", minimum size: "
			.num_readable(PiFlash::State::input("size")));
	}
	# check if SD card is recommended 8GB - check for 6GB since it isn't a hard limit
	if (PiFlash::State::has_input("NOOBS") and PiFlash::State::output("size") < 6*1024*1024*1024) {
		PiFlash::State->error("NOOBS images want 8GB SD card - currently have: "
			.num_readable(PiFlash::State::output("size")));
	}

	# test access to root privilege
	# sudo should be configured to not prompt for a password again on this session for some minutes
	say "verify sudo access";
	do { PiFlash::Command::cmd("sudo test", PiFlash::Command::prog("sudo"), PiFlash::Command::prog("true")); };
	if ($@) {
		# in case of failure, report that root privilege is required
		PiFlash::State->error("root privileges required to run this script");
	}

	# flash the device
	PiFlash::MediaWriter::flash_device();
}

# run main routine and catch exceptions
sub main
{
	local $@; # avoid interference from anything that modifies global $@
	do { piflash(); };

	# catch any exceptions thrown in main routine
	if (my $exception = $@) {
		if (ref $exception) {
			# exception is an object - try common output functions in case they include more details
			# these are not generated by this program - but if another module surprises us, try to handle it gracefully
			if ($exception->can('as_string')) {
				# typical of Exception::Class derivative classes
				PiFlash::State->error("[".(ref $exception)."]: ".$exception->as_string());
			}
			if ($exception->can('to_string')) {
				# typical of Exception::Base derivative classes
				PiFlash::State->error("[".(ref $exception)."]: ".$exception->to_string());
			}
			# if exception object was not handled, fall through and print whatever it says as if it's a string
		}

		# print exception as a plain string
		# don't run this through PiFlash::State->error() because it probably already came from there
		say STDERR "$0 failed: $@";
		return 1;
	} else {
		if (PiFlash::State::verbose()) {
			say "Program state dump...\n".PiFlash::State::odump($PiFlash::State::state,0);
		}
	}

	# return success
	return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash - Raspberry Pi SD-flashing script with safety checks to avoid erasing the wrong device

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

 exit PiFlash::main;

=head1 DESCRIPTION

This is the top-level command-line processing level of the L<piflash> script to flash an SD card for a Raspberry Pi
single-board computer. The main function serves as an exception catching wrapper which calls the piflash function
to process the command line.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Command>, L<PiFlash::Inspector>, L<PiFlash::MediaWriter>, L<PiFlash::State>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2019 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
