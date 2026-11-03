package Monitoring::Sneck::Checks::swraid;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::swraid - checks software RAID, md on Linux and gmirror and graid on FreeBSD

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are on FreeBSD. Set by tests.
our $GMIRROR = '/sbin/gmirror';
our $GRAID   = '/sbin/graid';

=head1 SYNOPSIS

    swraid|perl:swraid
    swraid_boot|perl:swraid -a md0 -a md1
    swraid_gm|perl:swraid -a mirror/gm0

=head1 DESCRIPTION

Checks every software RAID array. One that is degraded, has failed
devices, or is not running is CRITICAL. One rebuilding or resyncing is
WARNING, with how far along it is. A check or scrub running is fine.
Arrays given with --array must be there.

On Linux, md arrays are read from /proc/mdstat. On FreeBSD,
gmirror status -s and graid status -s are run, those classes not being
loaded, or the commands not being there, counting as having no arrays. Other OSes are UNKNOWN.

Having no arrays at all is OK, unless --array says one should be there.

=head1 OPTIONS

- -a, --array :: A array that must be there, such as md0, mirror/gm0, or
raid/r0. May be given more than once.

=cut

sub option_spec { return ('array|a=s@') }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my @arrays
		= $self->os eq 'linux'   ? $self->linux_arrays
		: $self->os eq 'freebsd' ? $self->freebsd_arrays
		:                          die( 'not supported on ' . $self->os . "\n" );
	my %have = map { $_->{name} => 1 } @arrays;
	my @codes;
	my @parts;
	foreach my $name ( @{ $self->opt('array') // [] } ) {
		next if $have{$name};
		push( @codes, $self->CRITICAL );
		push( @parts, $name . ' is not there' );
	}
	foreach my $array (@arrays) {
		push( @codes, $array->{code} );
		push( @parts, $array->{name} . ' ' . $array->{says} );
	}
	return $self->finish( $self->OK, 'no software RAID arrays' ) if !defined( $parts[0] );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

=head2 linux_arrays

Returns the md arrays from /proc/mdstat, as hash refs of name, code,
and says, what to say about it.

=cut

sub linux_arrays {
	my ($self) = @_;

	my $mdstat = eval { $self->proc_file('mdstat') } // return ();
	my @arrays;
	foreach my $block ( split( /\n(?=md[0-9a-z_]+ :)/, $mdstat ) ) {
		next if $block !~ /\A(md[0-9a-z_]+) : (\w+)(?: \([^)]*\))*(?: (\w+))?([^\n]*)/;
		my ( $name, $state, $level, $devices ) = ( $1, $2, $3 // '', $4 );
		my @failed = $devices =~ /(\S+?)\[[0-9]+\]\(F\)/g;
		my ( $wanted, $working ) = $block =~ /\[([0-9]+)\/([0-9]+)\]/;
		my ( $doing,  $percent ) = $block =~ /\b(recovery|resync|reshape|check|repair)\s*=\s*([0-9.]+)%/;

		my %array = ( name => $name );
		if ( $state ne 'active' ) {
			@array{ 'code', 'says' } = ( $self->CRITICAL, 'is ' . $state );
		} elsif ( defined( $failed[0] ) || ( defined($working) && $working < $wanted ) ) {
			my $says
				= $level . ' degraded' . ( defined($working) ? ', ' . $working . ' of ' . $wanted . ' working' : '' );
			$says = $says . ', failed ' . join( ', ', @failed )  if defined( $failed[0] );
			$says = $says . ', ' . $doing . ' ' . $percent . '%' if defined($doing);
			@array{ 'code', 'says' } = ( $self->CRITICAL, $says );
		} elsif ( defined($doing) && $doing ne 'check' && $doing ne 'repair' ) {
			@array{ 'code', 'says' } = ( $self->WARNING, $level . ' ' . $doing . ' ' . $percent . '%' );
		} else {
			@array{ 'code', 'says' }
				= ( $self->OK, $level . ' ok' . ( defined($doing) ? ', ' . $doing . ' ' . $percent . '%' : '' ) );
		}
		push( @arrays, \%array );
	} ## end foreach my $block ( split( /\n(?=md[0-9a-z_]+ :)/...))

	return @arrays;
} ## end sub linux_arrays

=head2 freebsd_arrays

Returns the gmirror and graid arrays, as for L</linux_arrays>.

=cut

sub freebsd_arrays {
	my ($self) = @_;

	my @arrays;
	foreach my $class ( [ $GMIRROR, 'COMPLETE' ], [ $GRAID, 'OPTIMAL' ] ) {
		my ( $command, $good ) = @{$class};
		next if !-x $command;
		my ( $exit, $output ) = $self->run_command( $command, 'status', '-s' );

		# the class not being loaded exits non zero, saying so
		next if $exit;

		# NAME STATUS COMPONENT (STATE), one line per component
		my %by_name;
		my @order;
		foreach my $line ( split( /\n/, $output ) ) {
			next if $line !~ /\A\s*(\S+)\s+(\S+)\s+(\S+)(?:\s+\((.*)\))?\s*\z/;
			my ( $name, $status, $component, $component_state ) = ( $1, $2, $3, $4 // '' );
			push( @order, $name ) if !$by_name{$name};
			$by_name{$name}{status} = $status;
			push( @{ $by_name{$name}{busy} }, $component . ' ' . lc($component_state) )
				if $component_state =~ /SYNCHRONIZING|REBUILD|RESYNC/;
		}
		foreach my $name (@order) {
			my $array  = $by_name{$name};
			my %result = ( name => $name );
			if ( $array->{status} eq $good ) {
				@result{ 'code', 'says' } = ( $self->OK, lc( $array->{status} ) );
			} elsif ( defined( $array->{busy} ) ) {
				@result{ 'code', 'says' }
					= ( $self->WARNING, lc( $array->{status} ) . ', ' . join( ', ', @{ $array->{busy} } ) );
			} else {
				@result{ 'code', 'says' } = ( $self->CRITICAL, lc( $array->{status} ) );
			}
			push( @arrays, \%result );
		} ## end foreach my $name (@order)
	} ## end foreach my $class ( [ $GMIRROR, 'COMPLETE' ], [...])

	return @arrays;
} ## end sub freebsd_arrays

1;
