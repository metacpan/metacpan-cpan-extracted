
package Proc::JobQueue::Command;

# $Id: Command.pm 13848 2009-07-23 21:34:00Z david $

use strict;
use warnings;
require Proc::JobQueue::Job;
our @ISA = qw(Proc::JobQueue::Job);

sub new
{
	my ($pkg, $cmdStr, %params) = @_;

	return $pkg->SUPER::new(
		command	=> $cmdStr,
		desc	=> "run $cmdStr",
		%params,
	);
}

sub success
{
	my ($job) = @_;
	print "# Job terminated correctly $job->{command}\n";
}

sub failed
{
	my ($job) = @_;
	print "#ERROR: Job terminated incorrectly $job->{command}\n";
}

1;

__END__

=head1 NAME

 Proc::JobQueue::Command - run shell commands in the background

=head1 SYNOPSIS

 use Proc::JobQueue::BackgroundQueue;
 use aliased 'Proc::JobQueue::Command';

 my $queue = new Proc::JobQueue::BackgroundQueue;

 my $job = Command->new($shell_command_string);

 $queue->add($job);

 $queue->finish;

=head1 DESCRIPTION

This is a subclass of L<Proc::JobQueue::Job>.
In the background, run a command-line command.

=head1 SEE ALSO

L<Proc::JobQueue>
L<Proc::JobQueue::Job>
L<Proc::JobQueue::BackgroundQueue>
L<Proc::JobQueue::Move>
L<Proc::JobQueue::Sort>
L<Proc::JobQueue::Sequence>

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

