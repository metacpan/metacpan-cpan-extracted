package Monitoring::Sneck::Checks::cciss;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::cciss - checks HP Smart Array controllers, through cciss_vol_status

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests. CCISS_VOL_STATUS undef means the first of
# CCISS_VOL_STATUS_PATHS that is there.
our $CCISS_VOL_STATUS;
our @CCISS_VOL_STATUS_PATHS = (
	'/usr/bin/cciss_vol_status',       '/usr/sbin/cciss_vol_status',
	'/usr/local/bin/cciss_vol_status', '/usr/local/sbin/cciss_vol_status',
);
our $SYS_VENDOR   = '/sys/devices/virtual/dmi/id/sys_vendor';
our $SCSI_GENERIC = '/sys/class/scsi_generic';
our $DEV          = '/dev';

# Volume states, from cciss_vol_status's decode_status, that are passing
# rather than broken. Its "expannding" is as it spells it.
our $PASSING = _any(
	'Ready for recovery operation',
	'Currently recovering',
	'Currently expanding',
	'Currently expannding',
	'Not yet available',
	'Queued for expansion',
	'Hardware was overheated',
);

# The cache states cciss_vol_status counts as trouble, some ending in a :.
our $CACHE_TROUBLE = _any(
	'Write cache temporarily disabled',
	'Write Cache permanently disabled',
	'Possible data loss on last reset',
	'Cache contains unflushed data',
	'Cache dirty limit reached',
	'Excessive ECC errors detected',
	'Non power related data loss',
	'HW problem with battery enable',
	'CPLD battery backed write cache incompatibility',
	'Permanent disable condition detected',
);

# A regex matching any of the strings, whole, with a : after allowed.
sub _any {
	my $any = join( '|', map { quotemeta($_) } @_ );
	return qr/\A(?:$any):?\z/;
}

=head1 SYNOPSIS

    cciss|perl:cciss
    cciss_sg0|perl:cciss -d /dev/sg0
    cciss_bsd|perl:cciss -d /dev/ciss0

=head1 DESCRIPTION

Checks the logical volumes, physical drives, enclosures, and cache of
HP Smart Array controllers, through cciss_vol_status -u -s -V.

- CRITICAL :: A volume FAILED, using interim recovery mode (degraded),
with the wrong drive replaced, with a drive not properly connected,
overheating, or in a state it does not know. A failed drive, even when
a spare has taken over and the volume is OK. A failed spare. A
enclosure with a fan, power supply, temperature, or door alert.

- WARNING :: A volume ready for recovery, recovering, expanding, queued
for expansion, not yet available, or that was overheated in the past.
A spare rebuilding. A drive in S.M.A.R.T. predictive failure. Cache
trouble, such as the write cache disabled or a battery problem.

- UNKNOWN :: cciss_vol_status not being there, or saying nothing about
a controller.

- OK :: Everything else, including not being a HP, having no
controllers, and a controller with no logical drives, such as one used
only as a HBA, so the same check can go everywhere.

Without --device, the controllers are found...

- Linux :: If /sys/devices/virtual/dmi/id/sys_vendor says it is a HP,
the sg devices of SCSI type 12, RAID controllers, under
/sys/class/scsi_generic, for the hpsa driver, and /dev/cciss/c*d0 for
the old cciss driver.

- FreeBSD :: /dev/ciss*, as only Smart Arrays have those.

This needs root, to open the devices.

=head1 OPTIONS

- -d, --device :: A controller to check, such as /dev/sg0,
/dev/cciss/c0d0, or /dev/ciss0, instead of finding them, and without
looking at the vendor. May be given more than once.

=cut

sub option_spec { return ('device|d=s@') }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux' && $self->os ne 'freebsd';

	my @devices = @{ $self->opt('device') // [] };
	if ( !defined( $devices[0] ) ) {
		if ( $self->os eq 'linux' ) {
			my $vendor = read_file( $SYS_VENDOR, err_mode => 'quiet' ) // '';
			return $self->finish( $self->OK, 'not a HP' ) if $vendor !~ /\bHPE?\b|Hewlett/i;
		}
		@devices = $self->controllers;
		return $self->finish( $self->OK, 'no Smart Array controllers' ) if !defined( $devices[0] );
	}
	my $command = $CCISS_VOL_STATUS // ( grep { -x $_ } @CCISS_VOL_STATUS_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'cciss_vol_status is not there' ) if !defined($command);
	return $self->finish( $self->UNKNOWN, $command . ' is not there' )      if !-x $command;

	my @codes;
	my @parts;
	foreach my $device (@devices) {
		my ( $code, $says ) = $self->controller_status( $command, $device );
		push( @codes, $code );
		push( @parts, $says );
	}

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 controllers

Returns the controllers found, as in the description, such as /dev/sg0
or /dev/ciss0.

=cut

sub controllers {
	my ($self) = @_;

	my $number = sub { ( $_[0] =~ /([0-9]+)\z/ )[0] // 0 };
	my @controllers;
	if ( $self->os eq 'freebsd' ) {
		opendir( my $dh, $DEV ) or return ();
		@controllers = map { $DEV . '/' . $_ }
			sort { $number->($a) <=> $number->($b) } grep { /\Aciss[0-9]+\z/ } readdir($dh);
		return @controllers;
	}

	if ( opendir( my $dh, $SCSI_GENERIC ) ) {
		foreach my $sg ( sort { $number->($a) <=> $number->($b) } grep { /\Asg[0-9]+\z/ } readdir($dh) ) {
			my $type = read_file( $SCSI_GENERIC . '/' . $sg . '/device/type', err_mode => 'quiet' ) // next;
			push( @controllers, $DEV . '/' . $sg ) if $type =~ /\A\s*12\s*\z/;
		}
	}
	if ( opendir( my $dh, $DEV . '/cciss' ) ) {
		push( @controllers,
			map { $DEV . '/cciss/' . $_ } sort { $number->( $a =~ s/d0\z//r ) <=> $number->( $b =~ s/d0\z//r ) }
			grep { /\Ac[0-9]+d0\z/ } readdir($dh) );
	}

	return @controllers;
} ## end sub controllers

=head2 controller_status

Runs cciss_vol_status -u -s -V on a controller and returns the code
and what to say about it.

    my ( $code, $says ) = $check->controller_status( '/usr/bin/cciss_vol_status', '/dev/sg0' );

=cut

sub controller_status {
	my ( $self, $command, $device ) = @_;

	# it exits 1 when anything is not OK, which the output says more about
	my ( $exit, $output ) = $self->run_command( $command, '-u', '-s', '-V', $device );
	my $found = _parse($output);
	if ( !defined( $found->{controller} ) && !defined( $found->{volumes}[0] ) ) {
		my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // '';
		$first =~ s/\A\s+|\s+\z//g;
		return ( $self->UNKNOWN, $device . ' said nothing, exited ' . $exit . ', "' . $first . '"' );
	}

	my @codes = ( $self->OK );
	my @parts;
	foreach my $volume ( @{ $found->{volumes} } ) {
		my $status = $volume->{status};
		push(
			@codes,
			$status eq 'OK'       ? $self->OK
			: $status =~ $PASSING ? $self->WARNING
			:                       $self->CRITICAL
		);
		my $says = $volume->{device} . ' ' . $volume->{level} . ' ' . lc($status);
		if ( defined( $volume->{failed}[0] ) ) {
			push( @codes, $self->CRITICAL );
			$says = $says . ', failed ' . join( ', ', @{ $volume->{failed} } );
		} elsif ( $volume->{failed_count} ) {
			push( @codes, $self->CRITICAL );
			$says = $says . ', ' . $volume->{failed_count} . ' failed drives';
		}
		$says = $says . ', replacing ' . join( ', ', @{ $volume->{replacement} } )
			if defined( $volume->{replacement}[0] );
		foreach my $spare ( @{ $volume->{spares} } ) {
			if ( $spare =~ /has failed/ ) {
				push( @codes, $self->CRITICAL );
				$says = $says . ', a spare failed';
			} elsif ( $spare =~ /currently rebuilding/ ) {
				push( @codes, $self->WARNING );
				$says = $says . ', a spare rebuilding';
			}
		}
		push( @parts, $says );
	} ## end foreach my $volume ( @{ $found->{volumes} } )
	push( @parts, $device . ' no logical drives' ) if !defined( $found->{volumes}[0] );

	my @drives = @{ $found->{drives} };
	my @bad    = grep { $_->{status} ne 'OK' } @drives;
	foreach my $drive (@bad) {
		push( @codes, $self->WARNING );
		push( @parts, $drive->{location} . ' ' . $drive->{status} );
	}
	# a count of drives ok next to failed ones would only confuse, as only S.M.A.R.T. goes in their status
	my $any_failed = grep { defined( $_->{failed}[0] ) || $_->{failed_count} } @{ $found->{volumes} };
	push( @parts, scalar(@drives) . ' drives ok' ) if defined( $drives[0] ) && !defined( $bad[0] ) && !$any_failed;

	foreach my $enclosure ( @{ $found->{enclosures} } ) {
		next if $enclosure->{status} eq 'OK';
		push( @codes, $self->CRITICAL );
		push( @parts, 'enclosure ' . $enclosure->{name} . ' ' . lc( $enclosure->{status} ) );
	}
	foreach my $problem ( @{ $found->{problems} } ) {
		push( @codes, $self->WARNING );
		push( @parts, $device . ' ' . lc($problem) );
	}

	return ( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub controller_status

# Parses the output of cciss_vol_status -u -s -V for one controller.
#
# Args...
#
#     - output :: What cciss_vol_status printed.
#
# Returns a hash ref of...
#
#     - controller :: Its name, if -V printed it.
#     - volumes :: Array ref of hash refs of device, level, status, spares, a array ref of
#       spare messages, failed and replacement, array refs of drive locations, and failed_count.
#     - drives :: Array ref of hash refs of location and status, OK or predictive failure.
#     - enclosures :: Array ref of hash refs of name and status.
#     - problems :: Array ref of cache trouble and drives that could not be read.
#
# Example...
#
#     my $found = _parse($output);
#     # $found->{volumes}[0] is { device => '/dev/sda', level => 'RAID 5', status => 'OK', ... }
#     # $found->{drives}[0] is { location => 'connector 1I box 1 bay 1', status => 'OK' }
sub _parse {
	my ($output) = @_;

	my %found   = ( volumes => [], drives => [], enclosures => [], problems => [] );
	my $section = '';
	foreach my $line ( split( /\n/, $output ) ) {
		if ( $line =~ /\AController: (.*?)\s*\z/ ) {
			$found{controller} = $1;
		} elsif ( $line =~ /\A(\S+): \(.*?\) (.+?) Volume \S+ status: (Unknown status [0-9]+|[^.]*)\.(.*)/ ) {
			my ( $device, $level, $status, $rest ) = ( $1, $2, $3, $4 );
			push(
				@{ $found{volumes} },
				{
					device      => $device,
					level       => $level,
					status      => $status,
					spares      => [ $rest =~ /(At least one [^.]+)/g ],
					failed      => [],
					replacement => [],
				}
			);
			$section = '';
		} elsif ( $line
			=~ /\A\S+: \(.*?\) Enclosure (.*?) \(S\/N: .*\) on Bus [0-9]+, Physical Port (\S+) status: (.*?)\.\s*\z/
			)
		{
			push( @{ $found{enclosures} }, { name => $1 . ' port ' . $2, status => $3 } );
		} elsif (
			$line =~ /\A\s*(Failed drives|'Replacement' drives|Drives currently substituted for by spares):\s*\z/ )
		{
			$section
				= $1 eq 'Failed drives'                              ? 'failed'
				: $1 eq 'Drives currently substituted for by spares' ? 'failed'
				:                                                      'replacement';
		} elsif ( $line =~ /\A\s*Physical drives: [0-9]+/ ) {
			$section = 'drives';
		} elsif ( $line =~ /\A\s*Total of ([0-9]+) failed physical drives/ ) {
			$found{volumes}[-1]{failed_count} = $1 if defined( $found{volumes}[0] );
		} elsif ( $line =~ /\A\s+(?:b[0-9]+t[0-9]+\s+)?(connector \S+ box \S+ bay \S+)\s/ ) {
			my $location = $1;
			if ( $section eq 'drives' ) {
				my $status
					= $line =~ /\sOK\s*\z/                          ? 'OK'
					: $line =~ /S\.M\.A\.R\.T\. predictive failure/ ? 'predictive failure'
					:                                                 'not OK';
				push( @{ $found{drives} }, { location => $location, status => $status } );
			} elsif ( ( $section eq 'failed' || $section eq 'replacement' ) && defined( $found{volumes}[0] ) ) {
				my $list = $found{volumes}[-1]{$section};
				push( @{$list}, $location ) if !grep { $_ eq $location } @{$list};
			}
		} elsif ( ( my $trimmed = $line =~ s/\A\s+|\s+\z//gr ) =~ $CACHE_TROUBLE ) {
			push( @{ $found{problems} }, $trimmed =~ s/:\z//r );
		} elsif ( $line =~ /\ACannot get device information for/ ) {
			push( @{ $found{problems} }, 'could not read a drive' );
		} elsif ( $line =~ /\A\S/ ) {
			$section = '';
		}
	} ## end foreach my $line ( split( /\n/, $output ) )

	return \%found;
} ## end sub _parse

1;
