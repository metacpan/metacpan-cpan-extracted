
package Proc::JobQueue::Move;

# $Id: Move.pm 13853 2009-07-24 00:59:44Z david $

use strict;
use warnings;
require Proc::JobQueue;
require Proc::JobQueue::Job;
our @ISA = qw(Proc::JobQueue::Job);
use Tie::Function::Examples qw(%q_shell);
use Proc::JobQueue qw(my_hostname is_remote_host);

my %destinations;
my $copies_running = 0;

my $debug = $Proc::JobQueue::debug;

sub new
{
	my ($pkg, $opts, $config, $from_file, $to_file, $to_host, $from_host) = @_;
	$pkg->SUPER::new(
		from_host	=> $from_host || my_hostname(),
		config		=> $config,
		opts		=> $opts,
		from		=> $from_file,
		to		=> $to_file,
		to_host		=> $to_host || my_hostname(),
		desc		=> "move to $to_host:$to_file",
		priority	=> 10,
	);
}

sub command
{
	my ($job) = @_;
	if (is_remote_host($job->{to_host})) {
		my $compress = $job->{config}{compress_network_copies} ? "-C" : "";
		return "scp -q -o StrictHostKeyChecking=no -o BatchMode=yes $compress $q_shell{$job->{from}} $q_shell{$job->{to_host}}:$q_shell{$job->{to}} && rm $q_shell{$job->{from}}";
	} else {
		# maybe it's on another filesystem
		return "mv $q_shell{$job->{from}} $q_shell{$job->{to}}";
	}
}

sub runnable
{
	my ($job) = @_;
	return ! $destinations{$job->{to_host}};
}

sub start
{
	my $job = shift;
	$job->SUPER::start(@_);
	$destinations{$job->{to_host}} = 1;
}

sub finished
{
	my $job = shift;
	$destinations{$job->{to_host}} = 0;
	$job->SUPER::finished(@_);
}

sub success
{
	my ($job) = @_;
	unlink($job->{from});
}

1;

__END__

=head1 NAME

 Proc::JobQueue::Move - move files from one place to another

=head1 SYNOPSIS

 use Proc::JobQueue::BackgroundQueue;
 use aliased 'Proc::JobQueue::Command';

 my $queue = new Proc::JobQueue::BackgroundQueue;

 use aliased 'Proc::JobQueue::Move';

 my $job = Move->new($opts, $config, $from_file, $to_file, $to_host, $from_host);

 $queue->add($job);

 $queue->finish;

=head1 DESCRIPTION

This is a subclass of L<Proc::JobQueue::Job>.
In the background, move a file to a new location (possibly on a 
new host).

C<scp> will be used to move files to remote locations.  The trust
relationships must already exist.  Files will be compressed in
transit if C<$config->{compress_network_copies}> is true.

Only one copy job per destination host is allowed to run 
simultaneously.

If the C<$to_host> matches C<Sys::Hostname::hostname> then 
the C<mv> command will be used instead of C<scp> and C<rm>.

=head1 CONSTRUCTION

The C<$opts> parameter is not currently used.   The 
C<$config> parameter must be a hash ref and the following
keys are checked:

=over

=item compress_network_copies

If true, will add C<-C> to the invocation of C<scp>.

=back

The rest of the parameters are self-explanatory.  The C<from_host>
parameter defaults to the local system.  So does the C<to_host> 
parameter.

=head1 ERRATTA 

The argument order for the constructor doesn't make any sense.  Sorry.

Either the from_host or the to_host needs to be the local host.

=head1 SEE ALSO

L<Proc::JobQueue>
L<Proc::JobQueue::Job>
L<Proc::JobQueue::BackgroundQueue>

=head1 LICENSE

Copyright (C) 2007-2008 SearchMe, Inc.   
Copyright (C) 2008-2010 David Sharnoff.
Copyright (C) 2011 Google, Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

