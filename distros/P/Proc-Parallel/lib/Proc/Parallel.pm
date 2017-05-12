
package Proc::Parallel;

use strict;
use warnings;
use IO::Event::Callback;
use IO::Event;
use POSIX ":sys_wait_h";
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(start_command finish_commands);
our $VERSION = 0.601;

my %running;

sub start_command
{
	my ($command, $input_callback, $eof_callback) = @_;

	my $fh;
	my $pid;
	if (ref($command)) {
		$pid = open $fh, "-|", @$command
			or die "open @$command|: $!";
	} else {
		$pid = open $fh, "-|", $command
			or die "open $command|: $!";
	}

	$running{$pid} = $command;
	IO::Event::Callback->new($fh,
		input	=> $input_callback,
		eof	=> sub {
			my ($handler, $ioe, $input_buffer_reference) = @_;
			$eof_callback->($handler, undef, $input_buffer_reference)
				if $eof_callback;
			delete $running{$pid};
			$ioe->close();
			waitpid($pid, WNOHANG);
			IO::Event::unloop_all() unless keys %running;
		},
	);
}

sub finish_commands
{
	IO::Event::loop();
}

1;

__END__

=head1 NAME

 Proc::Parallel - run multiple commands and process their output in parallel

=head1 SYNOPSIS

 use Proc::Parallel;

 startcommand($command, $per_line_callback, $at_eof_callback);

 finish_commands();

=head1 DESCRIPTION

This module is a wrapper around an asynchronous IO library.
It provides an easy interface for starting
a bunch of commands and processing each line of output from
those commands.

It uses L<IO::Event::Callback>.

When the last of the commands finish, C<Event::unloop_all()> is called
so this module is not safe to use with other L<Event>-based code.

The commands are started as you call C<startcommand()>, but no output
will be processed unless you call C<IO::Event::loop()> or let 
C<finish_commands()> call it for you.  The call to C<finish_commands()>
or C<IO::Event::loop()> returns when all the commands have completed.
Additional commands may be started after calling C<finish_commands()>.

In addition to the command to run, the C<startcommand()> function takes
two L<IO::Event>-style callbacks: one that's called for each line of
output and one that's called when at end-of-file.

=head1 EXAMPLE

 startcommand($command, sub { 
	my ($handler, $ioe, $input_buffer_reference) = @_;
	while (<$ioe>) {
		# do suff for each line
	}
 });

 finish_commands();

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

