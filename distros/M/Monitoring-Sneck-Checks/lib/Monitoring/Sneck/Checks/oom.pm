package Monitoring::Sneck::Checks::oom;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::oom - checks for processes killed for running out of memory

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    oom|perl:oom
    oom_held|perl:oom -H 3600 -c 5

=head1 DESCRIPTION

Counts the processes the Linux OOM killer killed since the last run,
from oom_kill in /proc/vmstat, which kernels from 4.13 have. By
default any is WARNING.

The count is kept in a state file, see
L<Monitoring::Sneck::Checks::base/read_state>, so the first run, and
the first after a reboot, have nothing to compare to and are OK.

A kill is only seen by the run after it, so the next run is OK again,
which a poll can easily miss. --hold keeps reporting it for that many
seconds after.

Only Linux has this. Other OSes are UNKNOWN, as is a kernel without
oom_kill.

=head1 OPTIONS

- -w, --warning :: Range for the kills since the last run.
Default :: 0

- -c, --critical :: Range for the kills since the last run.

- -H, --hold :: Seconds to keep reporting kills for.
Default :: 0

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s', 'hold|H=i' ) }

sub defaults { return { warning => '0', hold => 0 } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';
	my ($count) = $self->proc_file('vmstat') =~ /^oom_kill ([0-9]+)$/m;
	die("this kernel does not count OOM kills\n") if !defined($count);

	my $file  = $Monitoring::Sneck::Checks::base::STATE_DIR . '/oom.json';
	my $state = $self->read_state($file);
	return $self->finish( $self->UNKNOWN, 'can not read the state in ' . $file ) if !defined($state);

	# a lower count than last time is a reboot, so starts over
	my $now   = time;
	my $first = !defined( $state->{count} ) || $count < $state->{count};
	my $kills = $first ? 0 : $count - $state->{count};
	my %new   = ( count => $count );
	if ($kills) {
		%new = ( %new, killed_at => $now, killed => $kills );
	} elsif ( !$first && defined( $state->{killed_at} ) && $now - $state->{killed_at} < $self->opt('hold') ) {
		%new = ( %new, killed_at => $state->{killed_at}, killed => $state->{killed} );
	}
	my $problem = $self->write_state( $file, \%new );
	return $self->finish( $self->UNKNOWN, $problem ) if defined($problem);

	my $reported = $kills;
	my $held     = '';
	if ( !$kills && defined( $new{killed_at} ) ) {
		$reported = $new{killed};
		$held     = ', held from ' . ( $now - $new{killed_at} ) . ' seconds ago';
	}
	$self->perfdata(
		label    => 'kills',
		value    => $kills,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my $message
		= $reported
		. ' OOM kill'
		. ( $reported == 1 ? '' : 's' )
		. ' since the last check'
		. $held . ', '
		. $count
		. ' since boot';
	$message = 'first check, ' . $count . ' OOM kills since boot' if $first;

	return $self->finish( $self->threshold_status( $reported, $self->opt('warning'), $self->opt('critical') ),
		$message );
} ## end sub check

1;
