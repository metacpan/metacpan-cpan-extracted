# PiFlash::Command - run commands including fork paramaters and piping input & output
# by Ian Kluft
use strict;
use warnings;

use strict;
use warnings;
use v5.18.0; # require 2014 or newer version of Perl
use PiFlash::State;

package PiFlash::Command;
$PiFlash::Command::VERSION = '0.0.6';
use autodie;
use POSIX; # included with perl
use IO::Handle; # rpm: "dnf install perl-IO", deb: included with perl
use IO::Poll qw(POLLIN POLLHUP); # same as IO::Handle
use Carp qw(carp croak);

# ABSTRACT: process/command running utilities for piflash



# fork wrapper function
# borrowed from Aaron Crane's YAPC::EU 2009 presentation slides online
sub fork_child
{
    my ($child_process_code) = @_;

	# fork and catch errors
    my $pid = fork;
	if (!defined $pid) {
		PiFlash::State->error("Failed to fork: $!\n");
	}

	# if in parent process, return child pid
	if ($pid != 0) {
		return $pid;
	}

    # if in child process, run requested code
    my $result = $child_process_code->();

	# if we got here, child code returned - so exit to end the subprocess
    exit $result;
}

# command logging function
sub cmd_log
{
	# record all command return codes, stdout & stderr in a new top-level store in State
	# it's overhead but useful for problem-reporting, troubleshooting, debugging and testing
	if (PiFlash::State::verbose()) {
		my $log = PiFlash::State::log();
		if (!exists $log->{cmd}) {
			$log->{cmd} = [];
		}
		push @{$log->{cmd}}, { @_ };
	}
}

# fork/exec wrapper to run child processes and collect output/error results
# used as lower level call by cmd() and cmd2str()
# adds more capability than qx()/backtick/system - wrapper lets us send input & capture output/error data
## no critic (RequireArgUnpacking)
sub fork_exec
{
	# input for child process may be provided as reference to array - use it and remove it from parameters
	my @input;
	if ( ref $_[0] eq "ARRAY" ) {
		my $input_ref = shift;
		@input = @$input_ref;
	}
	if (PiFlash::State::verbose()) {
		say STDERR "fork_exec running: ".join(" ", @_);
	}
	my $cmdname = shift;
	my @args = @_;

	# open pipes for child process stdin, stdout, stderr
	my ($child_in_reader, $child_in_writer, $child_out_reader, $child_out_writer,
		$child_err_reader, $child_err_writer);
	pipe $child_in_reader, $child_in_writer
		or PiFlash::State->error("fork_exec($cmdname): failed to open child process input pipe: $!");
	pipe $child_out_reader, $child_out_writer
		or PiFlash::State->error("fork_exec($cmdname): failed to open child process output pipe: $!");
	pipe $child_err_reader, $child_err_writer
		or PiFlash::State->error("fork_exec($cmdname): failed to open child process error pipe: $!");

	# fork the child process
	my $pid = fork_child(sub {
		# in child process

		# close our copy of parent's end of pipes to avoid deadlock - it must now be only one with them open
		close $child_in_writer
			or croak "fork_exec($cmdname): child failed to close parent process input writer pipe: $!";
		close $child_out_reader
			or croak "fork_exec($cmdname): child failed to close parent process output reader pipe: $!";
		close $child_err_reader
			or croak "fork_exec($cmdname): child failed to close parent process error reader pipe: $!";

		# dup file descriptors into child's standard in=0/out=1/err=2 positions
		POSIX::dup2(fileno $child_in_reader, 0)
			or croak "fork_exec($cmdname): child failed to reopen stdin from pipe: $!\n";
		POSIX::dup2(fileno $child_out_writer, 1)
			or croak "fork_exec($cmdname): child failed to reopen stdout to pipe: $!\n";
		POSIX::dup2(fileno $child_err_writer, 2)
			or croak "fork_exec($cmdname): child failed to reopen stderr to pipe: $!\n";

		# close the file descriptors that were just consumed by dup2
		close $child_in_reader
			or croak "fork_exec($cmdname): child failed to close child process input reader pipe: $!";
		close $child_out_writer
			or croak "fork_exec($cmdname): child failed to close child process output writer pipe: $!";
		close $child_err_writer
			or croak "fork_exec($cmdname): child failed to close child process error writer pipe: $!";

		# execute the command
		exec @args
			or croak "fork_exec($cmdname): failed to execute command - returned $?";
	});

	# in parent process

	# close our copy of child's end of pipes to avoid deadlock - it must now be only one with them open
	close $child_in_reader
		or PiFlash::State->error("fork_exec($cmdname): parent failed to close child process input reader pipe: $!");
	close $child_out_writer
		or PiFlash::State->error("fork_exec($cmdname): parent failed to close child process output writer pipe: $!");
	close $child_err_writer
		or PiFlash::State->error("fork_exec($cmdname): parent failed to close child process error writer pipe: $!");

	# write to child's input if any content was provided
	if (@input) {
		# blocks until input is accepted - this interface reqiuires child commands using input take it before output
		# because parent process is not multithreaded
		if (! print $child_in_writer join("\n", @input)."\n") {
			PiFlash::State->error("fork_exec($cmdname): failed to write child process input: $!");
		}
	}
	close $child_in_writer;

	# use IO::Poll to collect child output and error separately
	my @fd = ($child_out_reader, $child_err_reader); # file descriptors for out(0) and err(1)
	my @text = (undef, undef); # received text for out(0) and err(1)
	my @done = (0, 0); # done flags for out(0) and err(1)
	my $poll = IO::Poll->new();
	$poll->mask($fd[0] => POLLIN);
	$poll->mask($fd[1] => POLLIN);
	while (not $done[0] or not $done[1]) {
		# wait for input
		if ($poll->poll() == -1) {
			PiFlash::State->error("fork_exec($cmdname): poll failed: $!");
		}
		for (my $i=0; $i<=1; $i++) {
			if (!$done[$i]) {
				my $events = $poll->events($fd[$i]);
				if ($events && (POLLIN || POLLHUP)) {
					# read all available input for input or hangup events
					# we do this for hangup because Linux kernel doesn't report input when a hangup occurs
					my $buffer;
					while (read($fd[$i], $buffer, 1024) != 0) {
						if (!defined $text[$i]) {
							$text[$i] = "";
						}
						$text[$i] .= $buffer;
					}
					if ($events && (POLLHUP)) {
						# hangup event means this fd (out=0, err=1) was closed by the child
						$done[$i] = 1;
						$poll->remove($fd[$i]);
						close $fd[$i];
					}
				}
			}
		}
	}

	# reap the child process status
	waitpid( $pid, 0 );

	# record all command return codes, stdout & stderr in a new top-level store in State
	# it's overhead but useful for problem-reporting, troubleshooting, debugging and testing
	cmd_log (
		cmdname => $cmdname,
		cmdline => [@args],
		returncode => $? >> 8,
		(($? & 127) ? (signal => sprintf "signal %d%s", ($? & 127), (($? & 128) ? " with coredump" : "")) : ()),
		out => $text[0],
		err => $text[1]
	);

	# catch errors
	if ($? == -1) {
		PiFlash::State->error("failed to execute $cmdname command: $!");
	} elsif ($? & 127) {
		PiFlash::State->error(sprintf "%s command died with signal %d, %s coredump",
			$cmdname, ($? & 127),  ($? & 128) ? 'with' : 'without');
	} elsif ($? != 0) {
		PiFlash::State->error(sprintf "%s command exited with value %d", $cmdname, $? >> 8);
	}

	# return output/error
	return @text;
}
## use critic

# run a command
# usage: cmd( label, command_line)
#   label: a descriptive name of the action this is performing
#   command_line: shell command line (pipes and other shell metacharacters allowed)
# note: if there are no shell special characters then all command-line parameters need to be passed separately.
# If there are shell special characters then it will be given to the shell for parsing.
## no critic (RequireArgUnpacking)
sub cmd
{
	my $cmdname = shift;
	if (PiFlash::State::verbose()) {
		say STDERR "cmd running: ".join(" ", @_);
	}
	my @args = @_;
	system (@args);
	cmd_log (
		cmdname => $cmdname,
		cmdline => [@args],
		returncode => $? >> 8,
		(($? & 127) ? (signal => sprintf "signal %d%s", ($? & 127), (($? & 128) ? " with coredump" : "")) : ()),
	);
	if ($? == -1) {
		PiFlash::State->error("failed to execute $cmdname command: $!");
	} elsif ($? & 127) {
		PiFlash::State->error(sprintf "%s command died with signal %d, %s coredump",
			$cmdname, ($? & 127),  ($? & 128) ? 'with' : 'without');
	} elsif ($? != 0) {
		PiFlash::State->error(sprintf "%s command exited with value %d", $cmdname, $? >> 8);
	}
	return 1;
}
## use critic

# run a command and return the output as a string
# This originally used qx() to fork child process and obtain output.  But Perl::Critic discourages use of qx/backtick.
# And it would be useful to provide input to child process, rather than using a wasteful echo-to-pipe shell command.
# So the fork_exec_wrapper() was added as a lower-level base for cmd() and cmd2str().
## no critic (RequireArgUnpacking)
sub cmd2str
{
	my $cmdname = shift;
	my ($out, $err) = fork_exec($cmdname, @_);
	if (defined $err) {
		carp("$cmdname had error output:\n".$err);
	}
	if (wantarray) {
		return split /\n/, $out;
	}
	return $out;
}
## use critic

# look up secure program path
## no critic (RequireFinalReturn)
sub prog
{
	my $progname = shift;

	if (!PiFlash::State::has_system("prog")) {
		PiFlash::State::system("prog", {});
	}
	my $prog = PiFlash::State::system("prog");

	# call with undef to initialize cache (mainly needed for testing because normal use will auto-create it)
	if (!defined $progname) {
		return;
	}

	# return value from cache if found
	if (exists $prog->{$progname}) {
		return $prog->{$progname};
	}

	# if we didn't have the location of the program, look for it and cache the result
	my $envprog = (uc $progname)."_PROG";
	$envprog =~ s/\W+/_/g; # collapse any sequences of non-alphanumeric/non-underscore to a single underscore
	if (exists $ENV{$envprog} and -x $ENV{$envprog}) {
		$prog->{$progname} = $ENV{$envprog};
		return $prog->{$progname};
	}

	# search paths in order emphasizing recent Linux Filesystem that prefers /usr/bin, then Unix PATH order
	for my $path ("/usr/bin", "/sbin", "/usr/sbin", "/bin") {
		if (-x "$path/$progname") {
			$prog->{$progname} = "$path/$progname";
			return $prog->{$progname};
		}
	}

	# if we get here, we didn't find a known secure location for the program
	PiFlash::State->error("unknown secure location for $progname - install it or set "
			.(uc $progname."_PROG")." to point to it");
}
## use critic

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PiFlash::Command - process/command running utilities for piflash

=head1 VERSION

version 0.0.6

=head1 SYNOPSIS

 PiFlash::Command::cmd( label, command_line)
 PiFlash::Command::cmd2str( label, comannd_line)
 PiFlash::Command::prog( "program-name" )

=head1 DESCRIPTION

This class contains internal functions used by L<PiFlash> to run programs and return their status, as well as piping
their input and output.

=head1 SEE ALSO

L<piflash>, L<PiFlash::Inspector>, L<PiFlash::State>

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
