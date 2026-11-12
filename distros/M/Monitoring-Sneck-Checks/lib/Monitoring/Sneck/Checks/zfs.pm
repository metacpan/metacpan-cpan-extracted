package Monitoring::Sneck::Checks::zfs;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::Local qw(timelocal);

=head1 NAME

Monitoring::Sneck::Checks::zfs - checks ZFS pools, health, capacity, scrubs, and device errors

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where zpool is. Set by tests. ZPOOL undef means the first of ZPOOL_PATHS
# that is there.
our $ZPOOL;
our @ZPOOL_PATHS = ( '/sbin/zpool', '/usr/sbin/zpool', '/usr/local/sbin/zpool' );

# Month numbers, as timelocal wants them, by the names zpool status uses.
our %MONTHS = (
	Jan => 0,
	Feb => 1,
	Mar => 2,
	Apr => 3,
	May => 4,
	Jun => 5,
	Jul => 6,
	Aug => 7,
	Sep => 8,
	Oct => 9,
	Nov => 10,
	Dec => 11,
);

# Device states that are fine, AVAIL and INUSE being those of spares.
our %DEVICE_FINE = map { $_ => 1 } ( 'ONLINE', 'AVAIL', 'INUSE' );

=head1 SYNOPSIS

    zfs|perl:zfs
    zfs_tank|perl:zfs -p tank -w 70 -c 85
    zfs_scrubs|perl:zfs --scrub-warning 35 --scrub-critical 60
    zfs_frag|perl:zfs --frag-warning 50

=head1 DESCRIPTION

Checks pools through zpool list and zpool status.

- CRITICAL :: A pool not ONLINE, such as DEGRADED or FAULTED. Data
errors. A pool given with --pool not being there. Capacity,
fragmentation, or scrub age over their critical.

- WARNING :: A resilver running. A device not ONLINE, such as a
FAULTED disk or UNAVAIL spare. A device with read, write, or checksum
errors. Capacity, fragmentation, or scrub age over their warning.

- UNKNOWN :: zpool not being there, or failing.

- OK :: Everything else, including a scrub running and having no
pools.

Scrub age is the days since the last scrub or resilver finished, as
zpool status only says the last. A pool with neither finished, such as
a new one or one whose scrub was canceled, is over any scrub range.

Device error counts stay until zpool clear is run.

A line for each pool follows the status line.

=head1 OPTIONS

- -p, --pool :: A pool to check, instead of all of them. May be given
more than once.

- -w, --warning :: Range for capacity, in percent.
Default :: 80

- -c, --critical :: Range for capacity, in percent.
Default :: 90

- --frag-warning :: Range for fragmentation, in percent.

- --frag-critical :: Range for fragmentation, in percent.

- --scrub-warning :: Range for scrub age, in days.
Default :: 40

- --scrub-critical :: Range for scrub age, in days.

=cut

sub option_spec {
	return (
		'pool|p=s@',       'warning|w=s',     'critical|c=s', 'frag-warning=s',
		'frag-critical=s', 'scrub-warning=s', 'scrub-critical=s',
	);
}

sub defaults { return { warning => '80', critical => '90', 'scrub-warning' => '40' } }

sub ranges {
	return ( 'warning', 'critical', 'frag-warning', 'frag-critical', 'scrub-warning', 'scrub-critical' );
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $zpool = $ZPOOL // ( grep { -x $_ } @ZPOOL_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'zpool is not there' )     if !defined($zpool);
	return $self->finish( $self->UNKNOWN, $zpool . ' is not there' ) if !-x $zpool;

	# so numbers and dates come out the same everywhere
	local $ENV{LC_ALL} = 'C';

	my ( $list_exit, $list ) = $self->run_command( $zpool, 'list', '-Hp', '-o', 'name,health,capacity,fragmentation' );
	return $self->finish( $self->UNKNOWN, 'zpool list exited ' . $list_exit . ', ' . ( $list =~ s/\s+\z//r ) )
		if $list_exit;
	my %pools;
	foreach my $line ( split( /\n/, $list ) ) {
		my ( $name, $health, $capacity, $fragmentation ) = split( /\t/, $line );
		next if !defined($fragmentation);
		$pools{$name}
			= { health => $health, capacity => $capacity =~ s/%\z//r, fragmentation => $fragmentation =~ s/%\z//r };
	}

	my @names = @{ $self->opt('pool') // [] };
	@names = sort( keys(%pools) ) if !defined( $names[0] );
	return $self->finish( $self->OK, 'no pools' ) if !defined( $names[0] );

	my ( $status_exit, $status ) = $self->run_command( $zpool, 'status', '-p' );
	return $self->finish( $self->UNKNOWN, 'zpool status exited ' . $status_exit . ', ' . ( $status =~ s/\s+\z//r ) )
		if $status_exit;
	my $statuses = _parse_status($status);

	my @codes;
	my @parts;
	my @details;
	my $ok_count = 0;
	foreach my $name (@names) {
		if ( !defined( $pools{$name} ) ) {
			push( @codes, $self->CRITICAL );
			push( @parts, $name . ' is not there' );
			next;
		}
		my ( $code, $says, $detail ) = $self->pool_status( $name, $pools{$name}, $statuses->{$name} );
		push( @codes,   $code );
		push( @details, $detail );
		defined($says) ? push( @parts, $says ) : $ok_count++;
	} ## end foreach my $name (@names)
	if ($ok_count) {
		my $noun = defined( $parts[0] ) ? 'other' : 'pool';
		$noun = $noun . 's' if $ok_count > 1;
		push( @parts, $ok_count . ' ' . $noun . ' ok' );
	}

	# pools are split by ; as what is said about each has commas
	return $self->finish( $self->worst(@codes), join( '; ', @parts ), @details );
} ## end sub check

=head2 pool_status

Works out how a pool is.

- name :: The pool's name.

- listed :: Hash ref from zpool list, of health, capacity, and
fragmentation, which is - if the pool has none.

- status :: Hash ref of what zpool status said about it, as from
_parse_status, or undef if it said nothing.

Returns the code, what to say about the pool in the status line, undef
if it is fine, and the line about it for after the status line.

    my ( $code, $says, $detail )
        = $check->pool_status( 'tank', { health => 'ONLINE', capacity => 85, fragmentation => 10 }, $status );
    # ( 1, 'tank 85% full', 'tank ONLINE, 85% full, 10% fragmented, scrubbed 3 days ago' )

=cut

sub pool_status {
	my ( $self, $name, $listed, $status ) = @_;

	my @codes = ( $self->OK );
	my @problems;
	my @detail = ( $name . ' ' . $listed->{health}, $listed->{capacity} . '% full' );

	if ( $listed->{health} ne 'ONLINE' ) {
		push( @codes,    $self->CRITICAL );
		push( @problems, $listed->{health} );
	}

	my $capacity_code = $self->threshold_status( $listed->{capacity}, $self->opt('warning'), $self->opt('critical') );
	push( @codes,    $capacity_code );
	push( @problems, $listed->{capacity} . '% full' ) if $capacity_code != $self->OK;
	$self->perfdata(
		label    => $name . '_capacity',
		value    => $listed->{capacity},
		uom      => '%',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
		max      => 100,
	);

	if ( $listed->{fragmentation} =~ /\A[0-9]+\z/ ) {
		my $fragmentation = $listed->{fragmentation};
		my $fragmentation_code
			= $self->threshold_status( $fragmentation, $self->opt('frag-warning'), $self->opt('frag-critical') );
		push( @codes,    $fragmentation_code );
		push( @problems, $fragmentation . '% fragmented' ) if $fragmentation_code != $self->OK;
		push( @detail,   $fragmentation . '% fragmented' );
		$self->perfdata(
			label    => $name . '_fragmentation',
			value    => $fragmentation,
			uom      => '%',
			warning  => $self->opt('frag-warning'),
			critical => $self->opt('frag-critical'),
			min      => 0,
			max      => 100,
		);
	} ## end if ( $listed->{fragmentation} =~ /\A[0-9]+\z/)

	if ( !defined($status) ) {
		push( @codes,    $self->UNKNOWN );
		push( @problems, 'not in zpool status' );
		return ( $self->worst(@codes), $name . ' ' . join( ', ', @problems ), join( ', ', @detail ) );
	}

	my $scan = $status->{scan};
	if ( defined( $scan->{running} ) ) {
		my $running = ( $scan->{running} eq 'scrub' ? 'scrubbing ' : 'resilvering ' ) . $scan->{done} . '%';
		push( @detail, $running );
		if ( $scan->{running} eq 'resilver' ) {
			push( @codes,    $self->WARNING );
			push( @problems, $running );
		}
	} else {
		# a pool never scrubbed is as old as can be
		my $age = defined( $scan->{finished} ) ? ( time - $scan->{finished} ) / 86400 : 9**9**9;
		my $says
			= defined( $scan->{finished} )
			? $scan->{verb} . ' ' . int($age) . ' days ago'
			: 'no finished scrub';
		my $scan_code = $self->threshold_status( $age, $self->opt('scrub-warning'), $self->opt('scrub-critical') );
		push( @codes,    $scan_code );
		push( @problems, $says ) if $scan_code != $self->OK;
		push( @detail,   $says );
		if ( defined( $scan->{finished} ) ) {
			$self->perfdata(
				label    => $name . '_scrub_age',
				value    => sprintf( '%.2f', $age ),
				warning  => $self->opt('scrub-warning'),
				critical => $self->opt('scrub-critical'),
				min      => 0,
			);
		}
	} ## end else [ if ( defined( $scan->{running} ) ) ]

	foreach my $device ( @{ $status->{devices} } ) {
		# a group such as raidz1-0 or spare-1 is only DEGRADED for what is under it, which is said itself
		my $bad_state = !$DEVICE_FINE{ $device->{state} }
			&& !( $device->{state} eq 'DEGRADED' && $device->{name} =~ /-[0-9]+\z/ );
		my @errors = map { $device->{$_} . ' ' . $_ } grep { $device->{$_} ne '0' } ( 'read', 'write', 'checksum' );
		next if !$bad_state && !defined( $errors[0] );

		my $says = $device->{name};
		$says = $says . ' ' . $device->{state}                       if $bad_state;
		$says = $says . ' with ' . join( ', ', @errors ) . ' errors' if defined( $errors[0] );
		push( @codes,    $self->WARNING );
		push( @problems, $says );
	} ## end foreach my $device ( @{ $status->{devices} } )

	if ( defined( $status->{data_errors} ) && $status->{data_errors} !~ /\ANo known data errors/ ) {
		push( @codes, $self->CRITICAL );
		push( @problems,
			$status->{data_errors} =~ /\A([0-9]+) data errors/ ? $1 . ' data errors' : $status->{data_errors} );
	}

	return (
		$self->worst(@codes),
		defined( $problems[0] ) ? $name . ' ' . join( ', ', @problems ) : undef,
		join( ', ', @detail )
	);
} ## end sub pool_status

# Parses the output of zpool status -p, for every pool.
#
# Args...
#
#     - output :: What zpool status -p printed.
#
# Returns a hash ref of pool names to hash refs of...
#
#     - state :: The pool's state, such as ONLINE.
#     - scan :: Hash ref of running, scrub or resilver if one is running, and done, the
#       percent done, or of finished, the epoch the last finished, and verb, scrubbed or
#       resilvered. Empty if none has finished and none is running.
#     - devices :: Array ref of hash refs of name, state, read, write, and checksum, the
#       error counts, for every vdev and device but the pool itself, spares and logs included.
#       Counts a line does not have, as for spares, are 0.
#     - data_errors :: What the errors line says, such as 'No known data errors'.
#
# Example...
#
#     my $statuses = _parse_status($output);
#     # $statuses->{tank}{scan} is { finished => 1793583466, verb => 'scrubbed' }
#     # $statuses->{tank}{devices}[0] is { name => 'raidz1-0', state => 'ONLINE', read => 0, ... }
sub _parse_status {
	my ($output) = @_;

	my %pools;
	my $name;
	my $section = '';
	foreach my $line ( split( /\n/, $output ) ) {
		if ( $line =~ /\A\s*pool: (\S+)/ ) {
			$name         = $1;
			$pools{$name} = { scan => {}, scan_text => '', devices => [] };
			$section      = '';
			next;
		}
		next if !defined($name);

		# device names can have colons in them, such as pci-0000:00:1f.2-ata-1, so only errors ends the config
		if ( $section eq 'config' ) {
			if ( $line =~ /\Aerrors:\s*(.*?)\s*\z/ ) {
				$pools{$name}{data_errors} = $1;
				$section = '';
				next;
			}
			# the NAME header and section names such as logs or spares have no state
			my ( $device, $state, @counts ) = split( ' ', $line );
			next if !defined($state) || $device eq $name || ( $device eq 'NAME' && $state eq 'STATE' );
			@counts = map { defined($_) && /\A[0-9]/ ? $_ : 0 } @counts[ 0 .. 2 ];
			push(
				@{ $pools{$name}{devices} },
				{
					name     => $device,
					state    => $state,
					read     => $counts[0],
					write    => $counts[1],
					checksum => $counts[2]
				}
			);
		} elsif ( $line =~ /\A\s*([a-z_]+):\s*(.*?)\s*\z/ ) {
			$section                 = $1;
			$pools{$name}{state}     = $2 if $section eq 'state';
			$pools{$name}{scan_text} = $2 if $section eq 'scan';
		} elsif ( $section eq 'scan' ) {
			$pools{$name}{scan_text} = $pools{$name}{scan_text} . ' ' . ( $line =~ s/\A\s+|\s+\z//gr );
		}
	} ## end foreach my $line ( split( /\n/, $output ) )

	foreach my $pool ( values(%pools) ) {
		my $text = delete( $pool->{scan_text} );
		my ($running) = $text =~ /\A(scrub|resilver) in progress/;
		if ( defined($running) ) {
			$pool->{scan} = { running => $running, done => ( $text =~ /([0-9.]+)% done/ )[0] // '?' };
			next;
		}
		my $verb;
		$verb = 'scrubbed'   if $text =~ /\Ascrub repaired/;
		$verb = 'resilvered' if $text =~ /\Aresilvered/;
		next if !defined($verb);
		# the end is a date as ctime prints it, such as "on Sun Nov  1 01:47:46 2026"
		my ( $month, $day, $hour, $minute, $second, $year )
			= $text =~ /\bon \w{3} (\w{3})\s+([0-9]+) ([0-9]+):([0-9]+):([0-9]+) ([0-9]{4})\z/;
		next if !defined($year) || !defined( $MONTHS{$month} );
		$pool->{scan}
			= { verb => $verb, finished => timelocal( $second, $minute, $hour, $day, $MONTHS{$month}, $year ) };
	} ## end foreach my $pool ( values(%pools) )

	return \%pools;
} ## end sub _parse_status

1;
