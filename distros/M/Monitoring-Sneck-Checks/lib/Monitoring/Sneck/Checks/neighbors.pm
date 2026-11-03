package Monitoring::Sneck::Checks::neighbors;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::neighbors - checks how full the ARP and NDP neighbor tables are

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# The tables, their stats file under /proc/net/stat, and their limit under /proc/sys/net.
our @TABLES = (
	[ 'arp', 'arp_cache',   'ipv4/neigh/default/gc_thresh3' ],
	[ 'ndp', 'ndisc_cache', 'ipv6/neigh/default/gc_thresh3' ]
);

=head1 SYNOPSIS

    neighbors|perl:neighbors
    neighbors_big_l2|perl:neighbors -w 60 -c 80

=head1 DESCRIPTION

Checks the ARP table, for IPv4, and the NDP one, for IPv6, against
gc_thresh3, past which the kernel will not add entries, so traffic to
new neighbors is dropped with only a kernel log line saying so. This
bites on big layer 2 networks.

The kernel also counts each time a table was full. That count is kept
in a state file, see L<Monitoring::Sneck::Checks::base/read_state>, and
any rise since the last run is CRITICAL, as packets were dropped.

The sizes come from /proc/net/stat. Only Linux has this, others are
UNKNOWN.

=head1 OPTIONS

- -w, --warning :: Range of percent of gc_thresh3 used.
Default :: 80

- -c, --critical :: Range of percent of gc_thresh3 used.
Default :: 90

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { warning => '80', critical => '90' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';
	my $file  = $Monitoring::Sneck::Checks::base::STATE_DIR . '/neighbors.json';
	my $state = $self->read_state($file);
	return $self->finish( $self->UNKNOWN, 'can not read the state in ' . $file ) if !defined($state);

	my @codes;
	my @parts;
	my %new_state;
	foreach my $table (@TABLES) {
		my ( $name, $stats_file, $limit_file ) = @{$table};
		my $stats = eval { $self->proc_file( 'net/stat/' . $stats_file ) } // next;
		my $limit = eval { $self->proc_file( 'sys/net/' . $limit_file ) }  // next;
		$limit =~ s/\s+//g;

		# a header, then a line per CPU in hex, entries being for the whole table and the rest for that CPU
		my ( $header, @rows ) = split( /\n/, $stats );
		my @columns = split( /\s+/, $header );
		my ( $entries, $fulls );
		foreach my $row (@rows) {
			my %row;
			@row{@columns} = map { hex($_) } split( /\s+/, $row );
			$entries //= $row{entries};
			$fulls = ( $fulls // 0 ) + ( $row{table_fulls} // 0 );
		}
		next if !defined($entries) || !$limit;

		my $percent = sprintf( '%.1f', $entries / $limit * 100 );
		my $code    = $self->threshold_status( $percent, $self->opt('warning'), $self->opt('critical') );
		my $part    = $name . ' ' . $entries . ' of ' . $limit;
		my $was     = $state->{ $name . '_fulls' };
		if ( defined($was) && $fulls > $was ) {
			$code = $self->CRITICAL;
			$part = $part . ', full ' . ( $fulls - $was ) . ' times since the last check';
		}
		$new_state{ $name . '_fulls' } = $fulls;
		push( @codes, $code );
		push( @parts, $part );
		$self->perfdata(
			label    => $name,
			value    => $percent,
			uom      => '%',
			warning  => $self->opt('warning'),
			critical => $self->opt('critical'),
			min      => 0,
			max      => 100
		);
	} ## end foreach my $table (@TABLES)
	die("no neighbor tables found\n") if !defined( $parts[0] );
	my $problem = $self->write_state( $file, \%new_state );
	return $self->finish( $self->UNKNOWN, $problem ) if defined($problem);

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

1;
