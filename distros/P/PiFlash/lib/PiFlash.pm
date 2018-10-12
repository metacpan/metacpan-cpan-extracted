# PiFlash - flash a Raspberry Pi image to an SD card, with safety checks to avoid erasing wrong device
# This module/script uses sudo to perform root-privileged functions.
# by Ian Kluft
use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl
use PiFlash::State;
use PiFlash::Command;
use PiFlash::Inspector;
use Carp;
use POSIX; # included with perl
use File::Basename; # included with perl
use File::LibMagic; # rpm: "dnf install perl-File-LibMagic", deb: "apt-get install libfile-libmagic-perl"

package PiFlash;
$PiFlash::VERSION = '0.0.3';
use autodie; # report errors instead of silently continuing ("die" actions are used as exceptions - caught & reported)
use Getopt::Long; # included with perl

# ABSTRACT: command-line processing for piflash script to flash SD card for Raspberry Pi


# print program usage message
sub usage
{
	say STDERR "usage: ".PiFlash::Inspector::base($0)." [--verbose] input-file output-device";
	say STDERR "       ".PiFlash::Inspector::base($0)." [--verbose] --SDsearch";
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

# generate random hex digits
sub random_hex
{
	my $length = shift;
	my $hex = "";
	while ($length > 0) {
		my $chunk = ($length > 4) ? 4 : $length;
		$length -= $chunk;
		$hex .= sprintf "%0*x", $chunk, int(rand(16**$chunk));
	}
	return $hex;
}

# generate a random UUID
# 128 bits/32 hexadecimal digits, used to set a probably-unique UUID on an ext2/3/4 filesystem we created
sub random_uuid
{
	my $uuid;

	# start with our own contrived prefix for our UUIDs
	$uuid .= "314decaf-"; # "314" first digits of pi (as in RasPi), and "decaf" among few words from hex digits

	# next 4 digits are from lower 4 hex digits of current time (rolls over every 18 days)
	$uuid .= sprintf "%04x-", (time & 0xffff);

	# next 4 digits are the UUID format version (4 for random) and 3 random hex digits
	$uuid .= "4".random_hex(3)."-";

	# next 4 digits are a UUID variant digit and 3 random hex digits
	$uuid .= (sprintf "%x", 8+int(rand(4))).random_hex(3)."-";
	
	# conclude with 8 random hex digits
	$uuid .= random_hex(12);

	return $uuid;
}

# generate a random label string
# 11 characters, used to set a probably-unique label on a VFAT/ExFAT filesystem we created
sub random_label
{
	my $label = "RPI";
	for (my $i=0; $i<8; $i++) {
		my $num = int(rand(36));
		if ($num <= 9) {
			$label .= chr(ord('0')+$num);
		} else {
			$label .= chr(ord('A')+$num-10);
		}
	}
	return $label;
}

# flash the output device from the input file
sub flash_device
{
	# flash the device
	if (PiFlash::State::has_input("imgfile")) {
		# if we know an embedded image file name, use it in the start message
		say "flashing ".PiFlash::State::input("path")." / ".PiFlash::State::input("imgfile")." -> "
			.PiFlash::State::output("path");
	} else {
		# print a start message with source and destination
		say "flashing ".PiFlash::State::input("path")." -> ".PiFlash::State::output("path");
	}
	say "wait for it to finish - this takes a while, progress not always indicated";
	if (PiFlash::State::input("type") eq "img") {
		PiFlash::Command::cmd("dd flash", PiFlash::Command::prog("sudo")." ".PiFlash::Command::prog("dd")
			." bs=4M if=\"".PiFlash::State::input("path")."\" of=\""
			.PiFlash::State::output("path")."\" status=progress" );
	} elsif (PiFlash::State::input("type") eq "zip") {
		if (PiFlash::State::has_input("NOOBS")) {
			# format SD and copy NOOBS archive to it
			my $label = random_label();
			PiFlash::State::output("label", $label);
			my $fstype = PiFlash::State::system("primary_fs");
			if ($fstype ne "vfat") {
				PiFlash::State->error("NOOBS requires VFAT filesystem, not in this kernel - need to load a module?");
			}
			say "formatting $fstype filesystem for Raspberry Pi NOOBS system...";
			PiFlash::Command::cmd("write partition table", PiFlash::Command::prog("echo"), "type=c", "|",
				PiFlash::Command::prog("sudo"), PiFlash::Command::prog("sfdisk"), PiFlash::State::output("path"));
			my @partitions = grep {/part\s*$/} PiFlash::Command::cmd2str("lsblk - find partitions",
				PiFlash::Command::prog("lsblk"), "--list", PiFlash::State::output("path"));
			$partitions[0] =~ /^([^\s]+)\s/;
			my $partition = "/dev/".$1;
			PiFlash::Command::cmd("format sd card", PiFlash::Command::prog("sudo"),
				PiFlash::Command::prog("mkfs.$fstype"), "-n", $label, $partition);
			my $mntdir = PiFlash::State::system("media_dir")."/piflash/sdcard";
			PiFlash::Command::cmd("reread partition table", PiFlash::Command::prog("sudo"),
				PiFlash::Command::prog("blockdev"), "--rereadpt", PiFlash::State::output("path"));
			PiFlash::Command::cmd("create mount point", PiFlash::Command::prog("sudo"),
				PiFlash::Command::prog("mkdir"), "-p", $mntdir );
			PiFlash::Command::cmd("mount SD card", PiFlash::Command::prog("sudo"), PiFlash::Command::prog("mount"),
				"-t", $fstype, "LABEL=$label", $mntdir);
			PiFlash::Command::cmd("unzip NOOBS contents", PiFlash::Command::prog("sudo"),
				PiFlash::Command::prog("unzip"), "-d", $mntdir, PiFlash::State::input("path"));
			PiFlash::Command::cmd("unmount SD card", PiFlash::Command::prog("sudo"), PiFlash::Command::prog("umount"),
				$mntdir);
		} else {
			# flash zip archive to SD
			PiFlash::Command::cmd("unzip/dd flash", PiFlash::Command::prog("unzip")." -p \""
				.PiFlash::State::input("path")."\" \"".PiFlash::State::input("imgfile")."\" | "
				.PiFlash::Command::prog("sudo")." ".PiFlash::Command::prog("dd")." bs=4M of=\""
				.PiFlash::State::output("path")."\" status=progress");
		}
	} elsif (PiFlash::State::input("type") eq "gz") {
		# flash gzip-compressed image file to SD
		PiFlash::Command::cmd("gunzip/dd flash", PiFlash::Command::prog("gunzip")." --stdout \""
			.PiFlash::State::input("path")."\" | ".PiFlash::Command::prog("sudo")." ".PiFlash::Command::prog("dd")
			." bs=4M of=\"".PiFlash::State::output("path")."\" status=progress");
	} elsif (PiFlash::State::input("type") eq "xz") {
		# flash xz-compressed image file to SD
		PiFlash::Command::cmd("xz/dd flash", PiFlash::Command::prog("xz")." --decompress --stdout \""
			.PiFlash::State::input("path")."\" | ".PiFlash::Command::prog("sudo")." ".PiFlash::Command::prog("dd")
			." bs=4M of=\"".PiFlash::State::output("path")."\" status=progress");
	}
	say "wait for it to finish - synchronizing buffers";
	PiFlash::Command::cmd("sync", PiFlash::Command::prog("sync"));
	say "done - it is safe to remove the SD card";
}

# piflash script main routine to be called from exception-handling wrapper
sub piflash
{
	# initialize program state storage
	PiFlash::State->init("system", "input", "output", "option", "log");

	# collect and validate command-line arguments
	do { GetOptions (PiFlash::State::option(), "verbose", "sdsearch"); };
	if ($@) {
		# in case of failure, add state info if verbose mode is set
		PiFlash::State->error($@);
	}
	if (($#ARGV != 1) and (!PiFlash::State::has_option("sdsearch"))) {
		usage();
	}
	# collect system info: kernel specs and locations of needed programs
	PiFlash::Inspector::collect_system_info();

	# if --SDsearch option was selected, search for SD cards and exit
	if (PiFlash::State::has_option("sdsearch")) {
		# SDsearch mode: print list of SD card devices and exit
		PiFlash::Inspector::sd_search();
		return;
	}

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
	flash_device();
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

PiFlash - command-line processing for piflash script to flash SD card for Raspberry Pi

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

 exit PiFlash::main;

=head1 DESCRIPTION

This is the top-level command-line processing level of the L<piflash> script to flash an SD card for a Raspberry Pi
single-board computer. The main function serves as an exception catching wrapper which calls the piflash function
to process the command line.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Command>, L<PiFlash::Inspector>, L<PiFlash::State>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
