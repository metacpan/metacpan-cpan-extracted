package Monitoring::Sneck::Checks::time_sync;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::time_sync - checks the local time daemon is synchronised, chrony, ntpd, or timesyncd

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where the tools are. Set by tests. Undef means the first of their PATHS
# that is there.
our $CHRONYC;
our @CHRONYC_PATHS = ( '/usr/bin/chronyc', '/usr/local/bin/chronyc', '/usr/sbin/chronyc' );
our $NTPQ;
our @NTPQ_PATHS = ( '/usr/bin/ntpq', '/usr/sbin/ntpq', '/usr/local/bin/ntpq', '/usr/local/sbin/ntpq' );
our $TIMEDATECTL;
our @TIMEDATECTL_PATHS = ( '/usr/bin/timedatectl', '/bin/timedatectl' );

# Seconds from the NTP epoch, 1900, to the Unix one, 1970.
our $NTP_EPOCH_OFFSET = 2208988800;

=head1 SYNOPSIS

    time_sync|perl:time_sync
    time_sync_tight|perl:time_sync -w 0.01 -c 0.1 --since-warning 7200
    time_sync_ntpd|perl:time_sync -d ntpd

=head1 DESCRIPTION

Asks the local time daemon if it is synchronised, how far off it is,
and when it last updated the clock. Unlike
L<Monitoring::Sneck::Checks::ntp>, which asks a NTP server, this is
about the daemon keeping this host's clock.

- chrony :: Through chronyc -n -c tracking.

- ntpd :: Through ntpq -n -c rv, for the reference ntpd and NTPsec.

- timesyncd :: Through timedatectl show, which only says if the
kernel's clock is synchronised, not the offset.

Without --daemon, the first of chronyc, ntpq, and timedatectl that is
there is used.

- CRITICAL :: Not synchronised. The daemon not answering. The offset or
time since the last update over their critical.

- WARNING :: Synchronised only to the local clock, as with chrony's
local stratum or ntpd's LOCAL(0). The offset or time since the last
update over their warning.

- UNKNOWN :: None of the tools being there.

=head1 OPTIONS

- -d, --daemon :: chrony, ntpd, or timesyncd, instead of looking for
them.

- -w, --warning :: Range for the offset, in seconds, either way.
Default :: 0.1

- -c, --critical :: Range for the offset, in seconds, either way.
Default :: 1

- --since-warning :: Range for the seconds since the last update.

- --since-critical :: Range for the seconds since the last update.

=cut

sub option_spec { return ( 'daemon|d=s', 'warning|w=s', 'critical|c=s', 'since-warning=s', 'since-critical=s' ) }

sub defaults { return { warning => '0.1', critical => '1' } }

sub ranges { return ( 'warning', 'critical', 'since-warning', 'since-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ('--daemon must be chrony, ntpd, or timesyncd')
		if defined( $options->{daemon} ) && $options->{daemon} !~ /\A(?:chrony|ntpd|timesyncd)\z/;

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	# set one at a time, as in a list a slice of nothing found would be nothing, shifting what follows
	my %tools;
	$tools{chrony}    = $CHRONYC     // ( grep { -x $_ } @CHRONYC_PATHS )[0];
	$tools{ntpd}      = $NTPQ        // ( grep { -x $_ } @NTPQ_PATHS )[0];
	$tools{timesyncd} = $TIMEDATECTL // ( grep { -x $_ } @TIMEDATECTL_PATHS )[0];
	my $daemon = $self->opt('daemon') // ( grep { defined( $tools{$_} ) } ( 'chrony', 'ntpd', 'timesyncd' ) )[0];
	return $self->finish( $self->UNKNOWN, 'none of chronyc, ntpq, or timedatectl found' ) if !defined($daemon);
	my $tool = $tools{$daemon};
	return $self->finish( $self->UNKNOWN, 'no tool for ' . $daemon . ' found' ) if !defined($tool) || !-x $tool;

	my $state
		= $daemon eq 'chrony' ? $self->chrony_state($tool)
		: $daemon eq 'ntpd'   ? $self->ntpd_state($tool)
		:                       $self->timesyncd_state($tool);
	return $self->finish( $self->CRITICAL, $daemon . ' is not answering, ' . $state->{says} )
		if !$state->{answering};

	if ( !$state->{synced} ) {
		my $message = $daemon . ' not synchronised';
		$message = $message . ', NTP is off' if $state->{ntp_off};
		return $self->finish( $self->CRITICAL, $message );
	}

	my @codes = ( $self->OK );
	my @parts;
	if ( $state->{local} ) {
		push( @codes, $self->WARNING );
		push( @parts, $daemon . ' synchronised to the local clock' );
	} else {
		push( @parts,
			$daemon . ' synchronised' . ( defined( $state->{reference} ) ? ' to ' . $state->{reference} : '' ) );
	}
	push( @parts, 'stratum ' . $state->{stratum} ) if defined( $state->{stratum} );

	if ( defined( $state->{offset} ) ) {
		my $offset = abs( $state->{offset} );
		push( @codes, $self->threshold_status( $offset, $self->opt('warning'), $self->opt('critical') ) );
		push( @parts, 'offset ' . sprintf( '%.6f', $state->{offset} ) . ' seconds' );
		$self->perfdata(
			label    => 'offset',
			value    => sprintf( '%.6f', $offset ),
			uom      => 's',
			warning  => $self->opt('warning'),
			critical => $self->opt('critical'),
			min      => 0,
		);
	} ## end if ( defined( $state->{offset} ) )

	if ( defined( $state->{updated} ) ) {
		my $since = time - int( $state->{updated} );
		$since = 0 if $since < 0;
		push( @codes, $self->threshold_status( $since, $self->opt('since-warning'), $self->opt('since-critical') ) );
		push( @parts, 'updated ' . $since . ' seconds ago' );
		$self->perfdata(
			label    => 'since_update',
			value    => $since,
			uom      => 's',
			warning  => $self->opt('since-warning'),
			critical => $self->opt('since-critical'),
			min      => 0,
		);
	} ## end if ( defined( $state->{updated} ) )

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 chrony_state

Asks chrony through chronyc -n -c tracking.

- chronyc :: The path to chronyc.

Returns a hash ref of answering, 1 or 0, and if not, says, what went
wrong, else synced, 1 or 0, local, 1 if synchronised to the local
clock, reference, the server's address, stratum, offset, in seconds,
and updated, the epoch of the last update, or undef.

    my $state = $check->chrony_state('/usr/bin/chronyc');
    # { answering => 1, synced => 1, local => 0, reference => '192.0.2.123', stratum => 2,
    #   offset => -0.000156213, updated => 1794200902.841540871 }

=cut

sub chrony_state {
	my ( $self, $chronyc ) = @_;

	my ( $exit, $output ) = $self->run_command( $chronyc, '-n', '-c', 'tracking' );
	my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // 'saying nothing';
	# reference ID, address, stratum, reference time, system offset, ..., leap status
	my @fields = split( /,/, $first );
	return { answering => 0, says => $first } if $exit || @fields < 14 || $fields[2] !~ /\A[0-9]+\z/;

	return {
		answering => 1,
		synced    => ( $fields[13] ne 'Not synchronised' && $fields[2] < 16 ) ? 1          : 0,
		local     => uc( $fields[0] ) eq '7F7F0101'                           ? 1          : 0,
		reference => $fields[1] ne ''                                         ? $fields[1] : undef,
		stratum   => $fields[2],
		offset    => $fields[4],
		updated   => $fields[3] > 0 ? $fields[3] : undef,
	};
} ## end sub chrony_state

=head2 ntpd_state

Asks ntpd through ntpq -n -c rv. Returns the same as L</chrony_state>,
the offset turned from milliseconds to seconds.

- ntpq :: The path to ntpq.

    my $state = $check->ntpd_state('/usr/bin/ntpq');

=cut

sub ntpd_state {
	my ( $self, $ntpq ) = @_;

	my ( $exit, $output ) = $self->run_command( $ntpq, '-n', '-c', 'rv' );
	my ($leap)    = $output =~ /\bleap=([0-9]+)/;
	my ($stratum) = $output =~ /\bstratum=([0-9]+)/;
	if ( $exit || !defined($leap) || !defined($stratum) ) {
		return { answering => 0, says => ( grep { /\S/ } split( /\n/, $output ) )[0] // 'saying nothing' };
	}
	my ($offset)  = $output =~ /\boffset=([-+]?[0-9.]+)/;
	my ($refid)   = $output =~ /\brefid=([^,\s]+)/;
	my ($reftime) = $output =~ /\breftime=([0-9a-f]+)\./;

	return {
		answering => 1,
		synced    => ( $leap ne '11'   && $stratum < 16 )                           ? 1 : 0,
		local     => ( defined($refid) && $refid =~ /\A(?:LOCAL\(|127\.127\.1\.)/ ) ? 1 : 0,
		reference => $refid,
		stratum   => $stratum,
		offset    => defined($offset)                       ? $offset / 1000                    : undef,
		updated   => ( defined($reftime) && hex($reftime) ) ? hex($reftime) - $NTP_EPOCH_OFFSET : undef,
	};
} ## end sub ntpd_state

=head2 timesyncd_state

Asks systemd through timedatectl show. Returns the same as
L</chrony_state>, but with only answering, says, and synced, plus
ntp_off, 1 if NTP is turned off.

- timedatectl :: The path to timedatectl.

    my $state = $check->timesyncd_state('/usr/bin/timedatectl');
    # { answering => 1, synced => 1, ntp_off => 0 }

=cut

sub timesyncd_state {
	my ( $self, $timedatectl ) = @_;

	my ( $exit, $output ) = $self->run_command( $timedatectl, 'show' );
	my %show;
	foreach my $line ( split( /\n/, $output ) ) {
		$show{$1} = $2 if $line =~ /\A([^=]+)=(.*)\z/;
	}
	if ( $exit || !defined( $show{NTPSynchronized} ) ) {
		return { answering => 0, says => ( grep { /\S/ } split( /\n/, $output ) )[0] // 'saying nothing' };
	}

	return {
		answering => 1,
		synced    => $show{NTPSynchronized} eq 'yes' ? 1 : 0,
		ntp_off   => ( $show{NTP} // '' ) eq 'no'    ? 1 : 0,
	};
} ## end sub timesyncd_state

1;
