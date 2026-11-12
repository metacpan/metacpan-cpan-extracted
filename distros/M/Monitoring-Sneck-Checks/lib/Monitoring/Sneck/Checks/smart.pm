package Monitoring::Sneck::Checks::smart;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::smart - checks disk health through smartctl

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where smartctl is. Set by tests. SMARTCTL undef means the first of
# SMARTCTL_PATHS that is there.
our $SMARTCTL;
our @SMARTCTL_PATHS
	= ( '/usr/sbin/smartctl', '/usr/local/sbin/smartctl', '/usr/bin/smartctl', '/usr/local/bin/smartctl' );

# ATA attributes counted as bad sectors, by ID, to what each is called.
our %ATA_BAD = ( 5 => 'reallocated', 197 => 'pending', 198 => 'uncorrectable' );

# The bits of the NVMe critical warning, what each is called, and 1 if it
# is only a WARNING, as running hot can pass.
our @NVME_WARNINGS = (
	[ 0x01, 'spare below threshold',         0 ],
	[ 0x02, 'over temperature',              1 ],
	[ 0x04, 'reliability degraded',          0 ],
	[ 0x08, 'read only',                     0 ],
	[ 0x10, 'volatile memory backup failed', 0 ],
	[ 0x20, 'persistent memory unreliable',  0 ],
);

=head1 SYNOPSIS

    smart|perl:smart
    smart_no_usb|perl:smart -e '^/dev/sd[f-z]'
    smart_raid|perl:smart -d /dev/bus/0,megaraid,0 -d /dev/bus/0,megaraid,1
    smart_hot|perl:smart --temp-warning 50 --temp-critical 60

=head1 DESCRIPTION

Checks disks through smartctl -j -a -n standby, which needs to be
smartmontools 7.0 or newer for its JSON output. Without --device, the
disks are those smartctl --scan-open finds.

- CRITICAL :: The disk failing its SMART health check. A ATA attribute
failing now. A NVMe critical warning other than temperature. Bad
sectors or media errors over --critical. Wear or temperature over
their critical.

- WARNING :: Bad sectors or media errors over --warning. The last ATA
self test failing. The NVMe temperature warning. Wear or temperature
over their warning.

- UNKNOWN :: smartctl not being there, a disk that can not be opened, or
smartctl not returning JSON.

- OK :: Everything else, including disks in standby, which are left
asleep, disks without SMART, and finding no disks, so the same check
can go everywhere.

Bad sectors and media errors are added up for --warning and
--critical, from...

- ATA :: Reallocated_Sector_Ct (5), Current_Pending_Sector (197), and
Offline_Uncorrectable (198).

- NVMe :: Media errors.

- SCSI :: The grown defect list and uncorrected read, write, and
verify errors.

Wear is the NVMe percentage used, or the SCSI percentage used
endurance indicator. ATA disks have none that is not vendor specific.

A line for each disk follows the status line, with its model, serial,
temperature, wear, and counts.

This needs root, to open the disks.

=head1 OPTIONS

- -d, --device :: A disk to check instead of scanning, such as /dev/sda.
A smartctl device type may follow after a comma, such as
/dev/bus/0,megaraid,0 or /dev/sda,sat. May be given more than once.

- -e, --exclude :: A regex for scanned disks to skip, matched against
the name, such as ^/dev/sdf. May be given more than once.

- -w, --warning :: Range for bad sectors and media errors.
Default :: 0

- -c, --critical :: Range for bad sectors and media errors.

- --wear-warning :: Range for wear, in percent.
Default :: 80

- --wear-critical :: Range for wear, in percent.
Default :: 90

- --temp-warning :: Range for temperature, in Celsius.

- --temp-critical :: Range for temperature, in Celsius.

=cut

sub option_spec {
	return (
		'device|d=s@',    'exclude|e=s@',    'warning|w=s',    'critical|c=s',
		'wear-warning=s', 'wear-critical=s', 'temp-warning=s', 'temp-critical=s',
	);
}

sub defaults { return { warning => '0', 'wear-warning' => '80', 'wear-critical' => '90' } }

sub ranges { return ( 'warning', 'critical', 'wear-warning', 'wear-critical', 'temp-warning', 'temp-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $regex ( @{ $options->{exclude} // [] } ) {
		push( @problems, '--exclude "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/; 1 };
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $smartctl = $SMARTCTL // ( grep { -x $_ } @SMARTCTL_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'smartctl is not there' )     if !defined($smartctl);
	return $self->finish( $self->UNKNOWN, $smartctl . ' is not there' ) if !-x $smartctl;
	require JSON;

	my @devices;
	foreach my $given ( @{ $self->opt('device') // [] } ) {
		my ( $name, $type ) = split( /,/, $given, 2 );
		push( @devices, { name => $name, type => $type } );
	}
	if ( !defined( $devices[0] ) ) {
		my ( $exit, $output ) = $self->run_command( $smartctl, '--scan-open', '-j' );
		my $scan = eval { JSON->new->decode($output) };
		return $self->finish( $self->UNKNOWN, 'smartctl --scan-open exited ' . $exit . ', without JSON' )
			if ref($scan) ne 'HASH';
		my @excludes = map { qr/$_/ } @{ $self->opt('exclude') // [] };
		foreach my $found ( @{ $scan->{devices} // [] } ) {
			next if grep { $found->{name} =~ $_ } @excludes;
			push( @devices, { name => $found->{name}, type => $found->{type}, open_error => $found->{open_error} } );
		}
		return $self->finish( $self->OK, 'no disks found' ) if !defined( $devices[0] );
	} ## end if ( !defined( $devices[0] ) )

	my @codes;
	my @parts;
	my @details;
	my $ok_count = 0;
	foreach my $device (@devices) {
		my ( $code, $says, $detail ) = $self->device_status( $smartctl, $device );
		push( @codes, $code );
		defined($says) ? push( @parts, $says ) : $ok_count++;
		push( @details, $detail ) if defined($detail);
	}
	if ($ok_count) {
		my $noun = defined( $parts[0] ) ? 'other' : 'disk';
		$noun = $noun . 's' if $ok_count > 1;
		push( @parts, $ok_count . ' ' . $noun . ' ok' );
	}

	return $self->finish( $self->worst(@codes), join( ', ', @parts ), @details );
} ## end sub check

=head2 device_status

Runs smartctl -j -a -n standby on a disk and works out how it is.

- smartctl :: The path to smartctl.

- device :: Hash ref of name, such as /dev/sda, type, a smartctl device
type or undef, and open_error, what smartctl --scan-open said when it
could not open it, if it could not.

Returns the code, what to say about the disk in the status line, undef
if it is fine, and the line about it for after the status line, undef
if smartctl said nothing useful.

    my ( $code, $says, $detail ) = $check->device_status( '/usr/sbin/smartctl', { name => '/dev/sdb' } );
    # ( 1, 'sdb 8 pending, 2 reallocated', 'sdb WDC WD40EFRX-68N32N0, S/N WD-WCC7K0000001, 36 C, ...' )

=cut

sub device_status {
	my ( $self, $smartctl, $device ) = @_;

	# what it is called in the output, the type after when it says which disk behind a controller
	my $short = $device->{name} =~ s{\A/dev/}{}r;
	$short = $short . ':' . $device->{type} if defined( $device->{type} ) && $device->{type} =~ /,/;
	return ( $self->UNKNOWN, $short . ' can not be opened, ' . $device->{open_error}, undef )
		if defined( $device->{open_error} );

	my @command = ( $smartctl, '-j', '-a', '-n', 'standby' );
	push( @command, '-d', $device->{type} ) if defined( $device->{type} );
	my ( $exit, $output ) = $self->run_command( @command, $device->{name} );
	my $info = eval { JSON->new->decode($output) };
	return ( $self->UNKNOWN, $short . ' smartctl exited ' . $exit . ', without JSON', undef ) if ref($info) ne 'HASH';

	# bit 0 is a bad command line and bit 1 the disk not opening, or being asleep with -n standby
	my @messages = map { $_->{string} // '' } @{ $info->{smartctl}{messages} // [] };
	if ( $exit & 3 ) {
		return ( $self->OK, $short . ' in standby', undef )
			if grep { /\bin (?:STANDBY|SLEEP|IDLE\S*) mode\b/i } @messages;
		return ( $self->UNKNOWN, $short . ' smartctl exited ' . $exit . ', ' . ( $messages[0] // 'saying nothing' ),
			undef );
	}
	if ( defined( $info->{smart_support} ) && !$info->{smart_support}{available} ) {
		return ( $self->OK, $short . ' has no SMART', undef );
	}

	my @codes = ( $self->OK );
	my @problems;
	if ( defined( $info->{smart_status} ) && !$info->{smart_status}{passed} ) {
		push( @codes,    $self->CRITICAL );
		push( @problems, 'failing SMART health check' );
	}

	# bad sectors and media errors, by what they are called
	my %bad;
	foreach my $attribute ( @{ $info->{ata_smart_attributes}{table} // [] } ) {
		if ( ( $attribute->{when_failed} // '' ) eq 'now' ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, $attribute->{name} . ' failing' );
		}
		$bad{ $ATA_BAD{ $attribute->{id} } } = $attribute->{raw}{value} // 0 if exists( $ATA_BAD{ $attribute->{id} } );
	}
	my $nvme = $info->{nvme_smart_health_information_log};
	if ( defined($nvme) ) {
		$bad{'media errors'} = $nvme->{media_errors} // 0;
		foreach my $warning (@NVME_WARNINGS) {
			my ( $bit, $name, $warning_only ) = @{$warning};
			next if !( ( $nvme->{critical_warning} // 0 ) & $bit );
			push( @codes,    $warning_only ? $self->WARNING : $self->CRITICAL );
			push( @problems, $name );
		}
	}
	$bad{'grown defects'} = $info->{scsi_grown_defect_list} if defined( $info->{scsi_grown_defect_list} );
	if ( defined( $info->{scsi_error_counter_log} ) ) {
		my $uncorrected = 0;
		foreach my $direction ( 'read', 'write', 'verify' ) {
			$uncorrected
				= $uncorrected + ( $info->{scsi_error_counter_log}{$direction}{total_uncorrected_errors} // 0 );
		}
		$bad{'uncorrected errors'} = $uncorrected;
	}
	my @bad_names = sort( keys(%bad) );
	if ( defined( $bad_names[0] ) ) {
		my $bad_total = 0;
		$bad_total = $bad_total + $_ foreach values(%bad);
		my $bad_code = $self->threshold_status( $bad_total, $self->opt('warning'), $self->opt('critical') );
		push( @codes,    $bad_code );
		push( @problems, map { $bad{$_} . ' ' . $_ } grep { $bad{$_} } @bad_names ) if $bad_code != $self->OK;
		$self->perfdata(
			label    => $short . '_bad',
			value    => $bad_total,
			warning  => $self->opt('warning'),
			critical => $self->opt('critical'),
			min      => 0,
		);
	} ## end if ( defined( $bad_names[0] ) )

	my $wear = defined($nvme) ? $nvme->{percentage_used} : $info->{scsi_percentage_used_endurance_indicator};
	if ( defined($wear) ) {
		my $wear_code = $self->threshold_status( $wear, $self->opt('wear-warning'), $self->opt('wear-critical') );
		push( @codes,    $wear_code );
		push( @problems, $wear . '% worn' ) if $wear_code != $self->OK;
		$self->perfdata(
			label    => $short . '_wear',
			value    => $wear,
			uom      => '%',
			warning  => $self->opt('wear-warning'),
			critical => $self->opt('wear-critical'),
			min      => 0,
		);
	} ## end if ( defined($wear) )

	my $temperature = $info->{temperature}{current};
	if ( defined($temperature) ) {
		my $temperature_code
			= $self->threshold_status( $temperature, $self->opt('temp-warning'), $self->opt('temp-critical') );
		push( @codes,    $temperature_code );
		push( @problems, $temperature . ' C' ) if $temperature_code != $self->OK;
		$self->perfdata(
			label    => $short . '_temp',
			value    => $temperature,
			warning  => $self->opt('temp-warning'),
			critical => $self->opt('temp-critical'),
		);
	} ## end if ( defined($temperature) )

	# only the newest, as a old failure stays in the log after the disk has passed since
	my $last_test = $info->{ata_smart_self_test_log}{standard}{table}[0];
	if ( defined($last_test) && defined( $last_test->{status}{passed} ) && !$last_test->{status}{passed} ) {
		push( @codes,    $self->WARNING );
		push( @problems, 'last self test failed' );
	}

	my @detail = ( $short . ' ' . ( $info->{model_name} // 'unknown model' ) );
	push( @detail, 'S/N ' . $info->{serial_number} ) if defined( $info->{serial_number} );
	push( @detail, $temperature . ' C' )             if defined($temperature);
	push( @detail, $wear . '% worn' )                if defined($wear);
	push( @detail, map { $bad{$_} . ' ' . $_ } @bad_names );

	return (
		$self->worst(@codes),
		defined( $problems[0] ) ? $short . ' ' . join( ', ', @problems ) : undef,
		join( ', ', @detail )
	);
} ## end sub device_status

1;
