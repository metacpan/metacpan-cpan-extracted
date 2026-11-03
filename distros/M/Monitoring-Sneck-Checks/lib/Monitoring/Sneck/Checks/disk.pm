package Monitoring::Sneck::Checks::disk;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::disk - checks how full file systems are

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    disk_root|perl:disk -p /
    disks|perl:disk -p / -p /var -p /usr/home -w 85 -c 95 -W 80 -K 90

=head1 DESCRIPTION

Checks the percent used of each file system, and optionally of its
inodes, through L<Filesys::Df>. Used is as df shows it, out of what
users may use, so space kept for root is left out of the total. A path that can
not be looked at is CRITICAL.

=head1 OPTIONS

- -p, --path :: A path on the file system. May be given more than once.
Required.

- -w, --warning :: Range of percent used.
Default :: 80

- -c, --critical :: Range of percent used.
Default :: 90

- -W, --inode-warning :: Range of percent of inodes used.

- -K, --inode-critical :: Range of percent of inodes used.

=cut

sub option_spec { return ( 'path|p=s@', 'warning|w=s', 'critical|c=s', 'inode-warning|W=s', 'inode-critical|K=s' ) }

sub defaults { return { warning => '80', critical => '90' } }

sub required { return ('path') }

sub ranges { return ( 'warning', 'critical', 'inode-warning', 'inode-critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require Filesys::Df;
	my @codes;
	my @parts;
	foreach my $path ( @{ $self->opt('path') } ) {
		my $df = Filesys::Df::df( $path, 1 );
		if ( !defined($df) ) {
			push( @codes, $self->CRITICAL );
			push( @parts, $path . ' can not be looked at, ' . ( $! || 'unknown error' ) );
			next;
		}

		my $code = $self->threshold_status( $df->{per}, $self->opt('warning'), $self->opt('critical') );
		my $part = $path . ' ' . $df->{per} . '% used of ' . _size( $df->{user_blocks} // $df->{blocks} );
		$self->perfdata(
			label    => $path,
			value    => $df->{per},
			uom      => '%',
			warning  => $self->opt('warning'),
			critical => $self->opt('critical'),
			min      => 0,
			max      => 100
		);
		if ( defined( $df->{fper} ) && $df->{files} ) {
			my $inode_code
				= $self->threshold_status( $df->{fper}, $self->opt('inode-warning'), $self->opt('inode-critical') );
			$code = $self->worst( $code, $inode_code );
			$part = $part . ', ' . $df->{fper} . '% inodes' if $inode_code != $self->OK;
			$self->perfdata(
				label    => $path . ' inodes',
				value    => $df->{fper},
				uom      => '%',
				warning  => $self->opt('inode-warning'),
				critical => $self->opt('inode-critical'),
				min      => 0,
				max      => 100
			);
		} ## end if ( defined( $df->{fper} ) && $df->{files...})
		push( @codes, $code );
		push( @parts, $part );
	} ## end foreach my $path ( @{ $self->opt('path') } )

	return $self->finish( $self->worst(@codes), join( ', ', @parts ) );
} ## end sub check

# Turns bytes into a size for people, such as 931.5 GiB.
#
# Args...
#
#     - bytes :: The number of bytes.
#
# Returns the size, in the largest unit it is at least one of.
#
# Example...
#
#     _size(1073741824);    # '1.0 GiB'
sub _size {
	my ($bytes) = @_;

	my @units = ( 'B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB' );
	my $unit  = 0;
	while ( $bytes >= 1024 && $unit < $#units ) {
		$bytes = $bytes / 1024;
		$unit++;
	}

	return $unit == 0 ? $bytes . ' B' : sprintf( '%.1f %s', $bytes, $units[$unit] );
} ## end sub _size

1;
