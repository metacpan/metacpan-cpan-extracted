
package Proc::Parallel::RemoteKiller;

use strict;
use warnings;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use Scalar::Util qw(weaken);

my %active;

sub new
{
	my $pkg = shift;
	my $self = bless { hosts => {} }, $pkg;
	$self->{old_sig} = $SIG{INT};
	$SIG{INT} = sub { $self->kill_them_all };
	$active{"$self"} = $self;
	weaken($active{"$self"});
	return $self;
}

sub note
{
	my ($self, $host, $pid) = @_;
	$host = $myfqdn unless defined $host;
	my $precache_answer = $fqdnify{$host};
	$self->{hosts}{$host}{$pid} = 1;
}

sub forget
{
	my ($self, $host, $pid) = @_;
	return unless defined($host) && defined($pid);
	delete $self->{hosts}{$host}{$pid};
	delete $self->{hosts}{$host} unless keys %{$self->{hosts}{$host}};
}

sub forget_all
{
	my ($self) = @_;
	$self->{hosts} = {};
}

sub kill_them_all
{
	my ($self, $do_not_exit) = @_;

	print STDERR "Bailing out!\n" unless $do_not_exit;

	my $x = "set -x\n";
	my $wait = 0;
	my $do = 0;
	for my $host (keys %{$self->{hosts}}) {
		my @pids = keys %{$self->{hosts}{$host}};
		delete $self->{hosts}{$host};
		next unless @pids;
		if ($fqdnify{$host} eq $myfqdn) {
			$x .= "kill @pids\n";
			$do = 1;
		} else {
			$x .= "ssh -o StrictHostKeyChecking=no $host -n kill @pids &\n";
			$wait = 1;
		}
	}
	$x .= "wait\n" if $wait;
	system($x) if $do || $wait; 
	exit(0);
}

sub DESTROY
{
	my ($self) = @_;
	delete $SIG{INT};
	# $self->kill_them_all(1);
	delete $active{"$self"};
}

END {
	for my $rk (values %active) {
		next unless $rk;
		$rk->kill_them_all(1);
	}
}


1;

__END__

=head1 NAME

Proc::Parallel::RemoteKiller - kill off slave processes on control-C

=head1 SYNOPSIS

 use Proc::Parallel::RemoteKiller;

 $remote_killer = Proc::Parallel::RemoteKiller->new;

 $remote_killer->note($host, $pid);

 $remote_killer->forget($host, $pid);

 $remote_killer->kill_them_all();

 $remote_killer->forget_all();

=head1 DESCRIPTION

This module tries to make control-C work when you've got remote slave
processes.  It maintains a list of such processes and catches 
C<$SIG{INT}>.  

You tell it about new processes with C<note>.  You tell it to forget
about processes with C<forget> and C<forget_all>.  You can ask that 
they all be terminated with C<kill_them_all()>.

It uses C<ssh> to get to the remote systems to kill the processes.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

