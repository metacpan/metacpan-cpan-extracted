package Monitoring::Sneck::Checks::uptime;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::uptime - checks how long the host has been up

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    rebooted|perl:uptime
    rebooted_or_stale|perl:uptime -w 900:7776000

=head1 DESCRIPTION

Checks the seconds the host has been up against the ranges, so by
default being up under 15 minutes, as after a reboot no one planned,
is WARNING. A upper end, such as 7776000 for 90 days, catches hosts
that have gone too long without one.

On Linux it is read from /proc/uptime, and on FreeBSD from kern.boottime
through L<BSD::Sysctl>. Other OSes are UNKNOWN.

=head1 OPTIONS

- -w, --warning :: Range of seconds up.
Default :: 900:

- -c, --critical :: Range of seconds up.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { warning => '900:' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $seconds = int( $self->seconds_up );
	$self->perfdata(
		label    => 'uptime',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);

	return $self->finish( $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') ),
		'up ' . _human($seconds) );
} ## end sub check

=head2 seconds_up

Returns the seconds the host has been up. Dies if it can not be found.

=cut

sub seconds_up {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my ($seconds) = $self->proc_file('uptime') =~ /\A([0-9.]+)/;
		die("can not make sense of /proc/uptime\n") if !defined($seconds);
		return $seconds;
	}
	if ( $self->os eq 'freebsd' ) {

		# a timeval, which may come as a hash or array ref, or as text such as "{ sec = 1700000000, usec = 0 } ..."
		my $boot = $self->sysctl('kern.boottime');
		my $sec
			= ref($boot) eq 'HASH'          ? $boot->{sec} // $boot->{tv_sec}
			: ref($boot) eq 'ARRAY'         ? $boot->[0]
			: $boot =~ /sec\s*=\s*([0-9]+)/ ? $1
			:                                 $boot;
		die("can not make sense of kern.boottime\n") if !defined($sec) || $sec !~ /\A[0-9]+\z/;
		return time - $sec;
	} ## end if ( $self->os eq 'freebsd' )

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub seconds_up

# Turns seconds into days, hours, and minutes for people.
#
# Args...
#
#     - seconds :: The seconds.
#
# Returns the text, such as '12 days, 3:04'.
#
# Example...
#
#     _human(1049040);    # '12 days, 3:24'
sub _human {
	my ($seconds) = @_;

	my $days    = int( $seconds / 86400 );
	my $hours   = int( ( $seconds % 86400 ) / 3600 );
	my $minutes = int( ( $seconds % 3600 ) / 60 );

	return ( $days ? $days . ' day' . ( $days == 1 ? '' : 's' ) . ', ' : '' ) . sprintf( '%d:%02d', $hours, $minutes );
}

1;
