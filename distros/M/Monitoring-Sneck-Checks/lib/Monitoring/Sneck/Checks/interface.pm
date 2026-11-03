package Monitoring::Sneck::Checks::interface;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::interface - checks network interfaces are up, at speed, and not erroring

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $NET      = '/sys/class/net';
our $IFCONFIG = '/sbin/ifconfig';
our $NETSTAT  = '/usr/bin/netstat';

=head1 SYNOPSIS

    uplink|perl:interface -i em0 -s 1000 -F -m 9000
    nics|perl:interface -a -e 0 -E 10
    bond|perl:interface -i bond0 -i eth0 -i eth1 -s 10000 -r 1 -R 100

=head1 DESCRIPTION

Checks each interface is up, which is CRITICAL if not, and optionally
that it is at a speed, at full duplex, and has a MTU, each WARNING if
not, as a link that came up at 100 Mb/s or half duplex works, just
badly.

Errors and drops are checked as a rate, per second, since the last
run, with the counters kept in a state file, see
L<Monitoring::Sneck::Checks::base/read_state>. So the first run, or
one after the counters reset, has no rate and is not checked for them.
They are only kept and checked if one of --errors-warning,
--errors-critical, --drops-warning, or --drops-critical is given, so
nothing else needs the state file.

On Linux, everything is read from /sys/class/net, and --all is every
interface backed by a device, so not lo, bridges, VLANs, and the like.
On FreeBSD it comes from ifconfig and netstat -I, and --all is
ifconfig -l ether. Other OSes are UNKNOWN.

=head1 OPTIONS

- -i, --interface :: A interface. May be given more than once.

- -a, --all :: Every interface backed by a device on Linux, or every
Ethernet one, as listed by ifconfig -l ether, on FreeBSD.

- -x, --ignore :: A interface for --all to leave out, such as a unused
port. May be given more than once.

- -s, --speed :: The Mb/s it must be at least.

- -F, --full-duplex :: It must be at full duplex.

- -m, --mtu :: The MTU it must have.

- -e, --errors-warning :: Range of errors per second.

- -E, --errors-critical :: Range of errors per second.

- -r, --drops-warning :: Range of drops per second.

- -R, --drops-critical :: Range of drops per second.

One of --interface or --all must be given.

=cut

sub option_spec {
	return (
		'interface|i=s@',    'all|a',   'ignore|x=s@',        'speed|s=i',
		'full-duplex|F',     'mtu|m=i', 'errors-warning|e=s', 'errors-critical|E=s',
		'drops-warning|r=s', 'drops-critical|R=s',
	);
}

sub ranges { return ( 'errors-warning', 'errors-critical', 'drops-warning', 'drops-critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $interface ( @{ $options->{interface} // [] } ) {
		push( @problems, '--interface "' . $interface . '" is not a interface name' )
			if $interface !~ /\A[A-Za-z0-9_.:-]+\z/;
	}
	push( @problems, 'nothing to check, give --interface or --all' )
		if !defined( $options->{interface} ) && !$options->{all};

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux' && $self->os ne 'freebsd';
	my %names = map { $_ => 1 } @{ $self->opt('interface') // [] }, ( $self->opt('all') ? $self->all : () );
	delete( @names{ @{ $self->opt('ignore') // [] } } );
	my @names = sort( keys(%names) );
	return $self->finish( $self->UNKNOWN, 'no interfaces found' ) if !defined( $names[0] );

	my @codes;
	my @parts;
	foreach my $name (@names) {
		my $info = $self->os eq 'linux' ? $self->linux_info($name) : $self->freebsd_info($name);
		if ( !defined($info) ) {
			push( @codes, $self->CRITICAL );
			push( @parts, $name . ' is not there' );
			next;
		}
		my ( $code, $part ) = $self->interface_status( $name, $info );
		push( @codes, $code );
		push( @parts, $part );
	} ## end foreach my $name (@names)

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 interface_status

Works out the status of a interface, as said under L</DESCRIPTION>,
adding its perfdata.

- name :: The interface.

- info :: Hash ref of up, 1 or 0, speed, in Mb/s, duplex, full or half,
mtu, errors, and drops, the counters, any undef if not known.

Returns the code and what to say about it.

=cut

sub interface_status {
	my ( $self, $name, $info ) = @_;

	if ( !$info->{up} ) {
		return ( $self->CRITICAL, $name . ' is down' );
	}

	my @codes = ( $self->OK );
	my @problems;
	my @is = ('up');
	push( @is, $info->{speed} . ' Mb/s' ) if defined( $info->{speed} );
	push( @is, $info->{duplex} )          if defined( $info->{duplex} );
	if ( defined( $self->opt('speed') ) && ( $info->{speed} // 0 ) < $self->opt('speed') ) {
		push( @codes,    $self->WARNING );
		push( @problems, 'under ' . $self->opt('speed') . ' Mb/s' );
	}
	if ( $self->opt('full-duplex') && ( $info->{duplex} // '' ) ne 'full' ) {
		push( @codes,    $self->WARNING );
		push( @problems, 'not full duplex' );
	}
	if ( defined( $self->opt('mtu') ) && ( $info->{mtu} // 0 ) != $self->opt('mtu') ) {
		push( @codes,    $self->WARNING );
		push( @problems, 'MTU ' . ( $info->{mtu} // 'unknown' ) . ', not ' . $self->opt('mtu') );
	}

	# the rates, and the state they need, only when a range for them was given
	my $rates = $self->rates_wanted ? $self->rates( $name, $info ) : {};
	foreach my $kind ( 'errors', 'drops' ) {
		next if !defined( $rates->{$kind} );
		my $warning  = $self->opt( $kind . '-warning' );
		my $critical = $self->opt( $kind . '-critical' );
		$self->perfdata(
			label    => $name . ' ' . $kind,
			value    => $rates->{$kind},
			warning  => $warning,
			critical => $critical,
			min      => 0
		);
		my $code = $self->threshold_status( $rates->{$kind}, $warning, $critical );
		next if $code == $self->OK;
		push( @codes,    $code );
		push( @problems, $rates->{$kind} . ' ' . $kind . '/s' );
	} ## end foreach my $kind ( 'errors', 'drops' )

	my $part = $name . ' ' . join( ' ', @is );
	$part = $part . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return ( $self->worst(@codes), $part );
} ## end sub interface_status

=head2 rates_wanted

Returns 1 if any of --errors-warning, --errors-critical,
--drops-warning, or --drops-critical was given, so the rates are to
be kept and checked, else 0.

=cut

sub rates_wanted {
	my ($self) = @_;

	return ( grep { defined( $self->opt($_) ) }
			( 'errors-warning', 'errors-critical', 'drops-warning', 'drops-critical' ) )
		? 1
		: 0;
}

=head2 rates

Works out the errors and drops per second since the last run, and
saves the counters for the next.

- name :: The interface.

- info :: As for L</interface_status>.

Returns a hash ref of errors and drops, each undef if there is no rate
yet. Dies if the state can not be kept.

=cut

sub rates {
	my ( $self, $name, $info ) = @_;

	my $file
		= $Monitoring::Sneck::Checks::base::STATE_DIR . '/interface-' . ( $name =~ s/[^A-Za-z0-9_.-]/_/gr ) . '.json';
	my $old = $self->read_state($file) // {};
	my $now = Time::HiRes::time;
	my %rates;
	foreach my $kind ( 'errors', 'drops' ) {
		my ( $was, $is ) = ( $old->{$kind}, $info->{$kind} );
		next if !defined($was) || !defined($is) || $is < $was || !defined( $old->{time} ) || $now <= $old->{time};
		$rates{$kind} = sprintf( '%.2f', ( $is - $was ) / ( $now - $old->{time} ) );
	}
	my $problem = $self->write_state( $file, { time => $now, errors => $info->{errors}, drops => $info->{drops} } );
	die( $problem . "\n" ) if defined($problem);

	return \%rates;
} ## end sub rates

=head2 all

Returns the interfaces --all covers, see DESCRIPTION.

=cut

sub all {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		opendir( my $net, $NET ) or return ();
		return grep { !/\A\./ && -e $NET . '/' . $_ . '/device' } readdir($net);
	}
	my ( $exit, $output ) = $self->run_command( $IFCONFIG, '-l', 'ether' );
	die( 'ifconfig -l ether exited ' . $exit . "\n" ) if $exit;

	return split( /\s+/, $output =~ s/\A\s+|\s+\z//gr );
} ## end sub all

=head2 linux_info

Returns what is known about a interface from /sys/class/net, as taken
by L</interface_status>, or undef if it is not there.

=cut

sub linux_info {
	my ( $self, $name ) = @_;

	my $dir = $NET . '/' . $name;
	return undef if $name =~ m{/|\A\.} || !-d $dir;
	my $read = sub {
		my $value = read_file( $dir . '/' . $_[0], err_mode => 'quiet' );
		return undef if !defined($value);
		$value =~ s/\s+\z//;
		return $value;
	};
	my $count = sub {
		my $total = 0;
		foreach my $counter (@_) {
			my $value = $read->( 'statistics/' . $counter ) // return undef;
			$total += $value;
		}
		return $total;
	};

	# up, or unknown with a carrier, as for tunnels and the like that do not say
	my $state  = $read->('operstate') // 'unknown';
	my $speed  = $read->('speed');
	my $duplex = $read->('duplex');

	return {
		up     => ( $state eq 'up' || ( $state eq 'unknown' && ( $read->('carrier') // '' ) eq '1' ) ) ? 1 : 0,
		speed  => defined($speed)  && $speed  =~ /\A[0-9]+\z/ && $speed > 0 ? $speed : undef,
		duplex => defined($duplex) && $duplex =~ /\A(?:full|half)\z/ ? $duplex : undef,
		mtu    => $read->('mtu'),
		errors => $count->( 'rx_errors',  'tx_errors' ),
		drops  => $count->( 'rx_dropped', 'tx_dropped' ),
	};
} ## end sub linux_info

=head2 freebsd_info

Returns what is known about a interface from ifconfig and netstat -I,
as taken by L</interface_status>, or undef if it is not there.

=cut

sub freebsd_info {
	my ( $self, $name ) = @_;

	my ( $exit, $output ) = $self->run_command( $IFCONFIG, $name );
	return undef if $exit;

	my ($flags)  = $output =~ /flags=[0-9a-f]+<([^>]*)>/;
	my ($status) = $output =~ /^\s*status: (.+?)\s*$/m;

	# what was negotiated is in parens, as "media: Ethernet autoselect (1000baseT <full-duplex>)", while media
	# set by hand has none, as "media: Ethernet 1000baseT <full-duplex>", and a lagg or a link that is down
	# is just "media: Ethernet autoselect", which says no speed
	my ($media) = $output =~ /^\s*media: (.+?)\s*$/m;
	$media = $1 if defined($media) && $media =~ /\((.+)\)/;
	my ( $speed, $duplex );
	if ( defined($media) && $media =~ /([0-9]+)(G?)base/i ) {
		$speed = $1 * ( $2 ? 1000 : 1 );
	}
	$duplex = $1 if defined($media) && $media =~ /<(full|half)-duplex/;
	my ($mtu) = $output =~ /\bmtu ([0-9]+)/;

	# the <Link#> row has the counters, its columns going by the header
	my ( $errors,       $drops );
	my ( $netstat_exit, $netstat ) = $self->run_command( $NETSTAT, '-I', $name, '-n', '-d' );
	if ( !$netstat_exit ) {
		my ( $header, @rows ) = split( /\n/, $netstat );
		my @columns = split( /\s+/, $header // '' );
		my ($link)
			= grep { ( split(/\s+/) )[2] =~ /\A<Link/ } grep { scalar( split(/\s+/) ) == scalar(@columns) } @rows;
		if ( defined($link) ) {
			my %row;
			@row{@columns} = split( /\s+/, $link );
			$errors        = ( $row{Ierrs} // 0 ) + ( $row{Oerrs} // 0 );
			$drops         = ( $row{Idrop} // 0 ) + ( $row{Drop}  // 0 );
		}
	} ## end if ( !$netstat_exit )

	return {
		up => ( ( ',' . ( $flags // '' ) . ',' ) =~ /,UP,/ && ( !defined($status) || $status eq 'active' ) )
		? 1
		: 0,
		speed  => $speed,
		duplex => $duplex,
		mtu    => $mtu,
		errors => $errors,
		drops  => $drops,
	};
} ## end sub freebsd_info

1;
