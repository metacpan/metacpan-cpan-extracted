package Monitoring::Sneck::Checks::packages;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::packages - checks packages are or are not installed

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where things are. Set by tests.
our $DPKG_STATUS = '/var/lib/dpkg/status';
our $PKG         = '/usr/sbin/pkg';

=head1 SYNOPSIS

    !no_telnet|control=CIS-2.3.4 framework=CIS|perl:packages -a telnet -a rsh-client
    !auditd||perl:packages -i auditd -i audispd-plugins
    !www_no_compilers||perl:packages -j www -a gcc13 -a llvm18

=head1 DESCRIPTION

Checks packages are installed, or are not, as given. Anything not as
given is CRITICAL.

On Debian and its kin, the dpkg status file is read, and a package
only counts as installed once fully installed, not if it was removed
with its config files left. On FreeBSD, pkg query is run, for a jail
too with --jail. Others are UNKNOWN.

=head1 OPTIONS

- -i, --installed :: A package that must be installed. May be given
more than once.

- -a, --absent :: A package that must not be installed. May be given
more than once.

- -j, --jail :: On FreeBSD, check the packages in this jail. UNKNOWN on
other OSes.

One or more of --installed or --absent must be given.

=cut

sub option_spec { return ( 'installed|i=s@', 'absent|a=s@', 'jail|j=s' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'installed', 'absent' ) {
		foreach my $package ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $package . '" is not a package name' )
				if $package !~ /\A[A-Za-z0-9][A-Za-z0-9+._:-]*\z/;
		}
	}
	push( @problems, 'nothing to check, give --installed or --absent' )
		if !defined( $options->{installed} ) && !defined( $options->{absent} );
	push( @problems, '--jail "' . $options->{jail} . '" is not a jail name or ID' )
		if defined( $options->{jail} ) && $options->{jail} !~ /\A[A-Za-z0-9_.-]+\z/;

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $installed = $self->installed;
	my @problems;
	my @fine;
	foreach my $package ( @{ $self->opt('installed') // [] } ) {
		if   ( $installed->{$package} ) { push( @fine,     $package . ' installed' ) }
		else                            { push( @problems, $package . ' is not installed' ) }
	}
	foreach my $package ( @{ $self->opt('absent') // [] } ) {
		if   ( $installed->{$package} ) { push( @problems, $package . ' is installed' ) }
		else                            { push( @fine,     $package . ' not installed' ) }
	}
	my $where = defined( $self->opt('jail') ) ? ' in jail ' . $self->opt('jail') : '';

	return $self->finish( $self->CRITICAL, join( ', ', @problems ) . $where ) if defined( $problems[0] );
	return $self->finish( $self->OK,       join( ', ', @fine ) . $where );
} ## end sub check

=head2 installed

Returns a hash ref of the names of the installed packages. Dies if
they can not be found.

=cut

sub installed {
	my ($self) = @_;

	if ( $self->os eq 'freebsd' ) {
		my @command = ($PKG);
		push( @command, '-j', $self->opt('jail') ) if defined( $self->opt('jail') );
		my ( $exit, $output ) = $self->run_command( @command, 'query', '%n' );
		die( 'pkg query exited ' . $exit . "\n" ) if $exit;
		return { map { $_ => 1 } split( /\n/, $output ) };
	}
	die("--jail is only for freebsd\n") if defined( $self->opt('jail') );
	if ( $self->os eq 'linux' && -e $DPKG_STATUS ) {
		my $status = read_file( $DPKG_STATUS, err_mode => 'quiet' );
		die( 'can not read ' . $DPKG_STATUS . ', ' . $! . "\n" ) if !defined($status);
		my %installed;
		foreach my $stanza ( split( /\n\n+/, $status ) ) {
			next if $stanza !~ /^Status: \S+ \S+ installed$/m;
			$installed{$1} = 1 if $stanza =~ /^Package: (\S+)$/m;
		}
		return \%installed;
	} ## end if ( $self->os eq 'linux' && -e $DPKG_STATUS)

	die( 'not supported on ' . $self->os . ( $self->os eq 'linux' ? ' without dpkg' : '' ) . "\n" );
} ## end sub installed

1;
