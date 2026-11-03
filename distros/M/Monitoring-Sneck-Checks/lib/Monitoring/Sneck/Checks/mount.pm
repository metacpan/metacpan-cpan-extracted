package Monitoring::Sneck::Checks::mount;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::mount - checks file systems are mounted and writable

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $FSTAB = '/etc/fstab';
our $MOUNT = '/sbin/mount';

# Types in fstab that are not mounted at a path.
our %NOT_MOUNTED_TYPES = map { $_ => 1 } ( 'swap', 'ignore' );

=head1 SYNOPSIS

    mounts|perl:mount
    data_mounted|perl:mount --no-fstab -p /data -p /backup
    mounts_not_cd|perl:mount -i /media/cdrom

=head1 DESCRIPTION

Checks every file system in fstab is mounted, and that those not set
ro there are not mounted read only, as one going read only after
errors often goes unnoticed. Either is CRITICAL. Paths given with
--path must be mounted too, but are not checked for being read only.

Swap is left alone. Entries that are noauto or x-systemd.automount are
not expected to be mounted, though they are checked for being read
only if they are.

Mounts are read from /proc/mounts on Linux and mount -p on FreeBSD.
Other OSes are UNKNOWN, as is fstab not being readable unless
--no-fstab is given.

=head1 OPTIONS

- -p, --path :: A path that must be a mount point. May be given more
than once.

- -i, --ignore :: A mount point in fstab to leave alone. May be given
more than once.

- -n, --no-fstab :: Only check --path, which must then be given.

=cut

sub option_spec { return ( 'path|p=s@', 'ignore|i=s@', 'no-fstab|n' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ('--no-fstab needs --path') if $options->{'no-fstab'} && !defined( $options->{path} );

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my %mounted = map { $_->{path}       => $_ } $self->mounts;
	my %ignore  = map { _normal_path($_) => 1 } @{ $self->opt('ignore') // [] };
	my @wanted;
	if ( !$self->opt('no-fstab') ) {
		my $fstab = read_file( $FSTAB, err_mode => 'quiet' );
		return $self->finish( $self->UNKNOWN, 'can not read ' . $FSTAB . ', ' . $! ) if !defined($fstab);
		push( @wanted, grep { !$ignore{ $_->{path} } } _parse($fstab) );
	}
	push( @wanted, map { { path => _normal_path($_), options => {}, given => 1 } } @{ $self->opt('path') // [] } );

	my @problems;
	my $checked = 0;
	my %seen;
	foreach my $want (@wanted) {
		next if $seen{ $want->{path} }++;
		my $options = $want->{options};
		my $mount   = $mounted{ $want->{path} };
		my $lazy    = $options->{noauto} || $options->{'x-systemd.automount'};
		if ( !defined($mount) ) {
			push( @problems, $want->{path} . ' is not mounted' ) if !$lazy;
			next;
		}
		$checked++;
		if ( $mount->{options}{ro} && !$options->{ro} && !$want->{given} ) {
			push( @problems, $want->{path} . ' is read only' );
		}
	} ## end foreach my $want (@wanted)

	my $message = $checked . ' mounted';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( defined( $problems[0] ) ? $self->CRITICAL : $self->OK, $message );
} ## end sub check

=head2 mounts

Returns what is mounted, as hash refs of path and options, a hash ref
of each option to its value, or 1. Dies if it can not be found.

=cut

sub mounts {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {
		return _parse( $self->proc_file('mounts'), 1 );
	}
	if ( $self->os eq 'freebsd' ) {
		my ( $exit, $output ) = $self->run_command( $MOUNT, '-p' );
		die( $MOUNT . ' -p exited ' . $exit . "\n" ) if $exit;
		return _parse( $output, 1 );
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub mounts

# Parses fstab, or something in the same format, such as /proc/mounts
# and mount -p.
#
# Args...
#
#     - content :: The text.
#
#     - all :: 1 to keep everything, for what is mounted, else entries
#       not mounted at a path, such as swap, are left out.
#
# Returns a list of hash refs of device, path, type, and options, a hash
# ref of each option to its value, or 1. \040 and the like in paths
# are turned into what they stand for.
#
# Example...
#
#     _parse("/dev/ada0p2 / ufs rw,noatime 1 1\n");
#     # ( { device => '/dev/ada0p2', path => '/', type => 'ufs', options => { rw => 1, noatime => 1 } } )
sub _parse {
	my ( $content, $all ) = @_;

	my @entries;
	foreach my $line ( split( /\n/, $content ) ) {
		next if $line =~ /\A\s*(?:#|\z)/;
		my ( $device, $path, $type, $options ) = split( /\s+/, $line =~ s/\A\s+//r );
		next if !defined($type);
		$path = _normal_path( $path =~ s/\\([0-7]{3})/chr(oct($1))/ger );
		next if !$all && ( $NOT_MOUNTED_TYPES{$type} || $path !~ m{\A/} );
		my %options = map { /\A([^=]+)=(.*)\z/ ? ( $1 => $2 ) : ( $_ => 1 ) } split( /,/, $options // '' );
		push( @entries, { device => $device, path => $path, type => $type, options => \%options } );
	}

	return @entries;
} ## end sub _parse

# Drops a trailing / from a path, other than for /.
#
# Args...
#
#     - path :: The path.
#
# Returns the path.
#
# Example...
#
#     _normal_path('/data/');    # '/data'
sub _normal_path {
	my ($path) = @_;

	$path =~ s{(?<=.)/+\z}{};

	return $path;
}

1;
