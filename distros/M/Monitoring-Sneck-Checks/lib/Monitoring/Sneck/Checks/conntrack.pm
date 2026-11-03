package Monitoring::Sneck::Checks::conntrack;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::conntrack - checks how full the connection tracking table is

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where pfctl is on FreeBSD. Set by tests.
our $PFCTL = '/sbin/pfctl';

=head1 SYNOPSIS

    conntrack|perl:conntrack
    pf_states|perl:conntrack -w 70 -c 85

=head1 DESCRIPTION

Checks the percent of the connection tracking table in use. Once it is
full, new connections are dropped, with nothing but a kernel log line
saying so.

On Linux, it is nf_conntrack_count against nf_conntrack_max, under
/proc/sys/net/netfilter. If conntrack is not loaded there is no table,
which is OK. On FreeBSD, it is pf's states, from pfctl -si and the
states limit from pfctl -sm, which needs root. pf being loaded but
disabled is OK. pfctl failing, such as pf not being in the kernel, is
UNKNOWN, as are other OSes.

=head1 OPTIONS

- -w, --warning :: Range of percent used.
Default :: 80

- -c, --critical :: Range of percent used.
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

	my ( $used, $max, $what ) = $self->table;
	return $self->finish( $self->OK, $what ) if !defined($used);
	die("the limit is 0\n")                  if !$max;

	my $percent = sprintf( '%.1f', $used / $max * 100 );
	$self->perfdata(
		label    => 'used',
		value    => $percent,
		uom      => '%',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
		max      => 100
	);
	$self->perfdata( label => 'entries', value => $used, min => 0, max => $max );

	return $self->finish( $self->threshold_status( $percent, $self->opt('warning'), $self->opt('critical') ),
		$what . ' ' . $percent . '% used, ' . $used . ' of ' . $max );
} ## end sub check

=head2 table

Returns the entries in use, the limit, and what the table is, or undef
for the entries and why there is no table. Dies if it can not be found.

=cut

sub table {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		my $count = eval { $self->proc_file('sys/net/netfilter/nf_conntrack_count') };
		return ( undef, undef, 'conntrack is not loaded' ) if !defined($count);
		my $max = $self->proc_file('sys/net/netfilter/nf_conntrack_max');
		return ( $count =~ s/\s+//gr, $max =~ s/\s+//gr, 'conntrack' );
	}
	if ( $self->os eq 'freebsd' ) {
		my ( $exit, $info ) = $self->run_command( $PFCTL, '-si' );
		die( 'pfctl -si exited ' . $exit . ', ' . ( ( split( /\n/, $info ) )[0] // '' ) . "\n" ) if $exit;
		return ( undef, undef, 'pf is not enabled' ) if $info =~ /^Status: Disabled/m;
		my ($entries) = $info =~ /^\s*current entries\s+([0-9]+)/m;
		my ( $limit_exit, $limits ) = $self->run_command( $PFCTL, '-sm' );
		die( 'pfctl -sm exited ' . $limit_exit . "\n" ) if $limit_exit;
		my ($max) = $limits =~ /^states\s+hard limit\s+([0-9]+)/m;
		die("can not make sense of pfctl\n") if !defined($entries) || !defined($max);
		return ( $entries, $max, 'pf states' );
	} ## end if ( $self->os eq 'freebsd' )

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub table

1;
