package Monitoring::Sneck::Checks::file_handles;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::file_handles - checks how many files are open against the limit

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    file_handles|perl:file_handles
    file_handles_tight|perl:file_handles -w 60 -c 80

=head1 DESCRIPTION

Checks the percent of the system wide limit on open files in use, as
running out stops anything from opening a file or socket.

On Linux it is from /proc/sys/fs/file-nr, and on FreeBSD from
kern.openfiles and kern.maxfiles through L<BSD::Sysctl>. Other OSes are
UNKNOWN. Newer Linux kernels may have a limit so high that this never
alerts, in which case the limit per process is what matters.

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

	my ( $open, $max ) = $self->handles;
	die("the limit is 0\n") if !$max;
	my $percent = sprintf( '%.1f', $open / $max * 100 );
	$self->perfdata(
		label    => 'used',
		value    => $percent,
		uom      => '%',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
		max      => 100
	);
	$self->perfdata( label => 'open', value => $open, min => 0, max => $max );

	return $self->finish( $self->threshold_status( $percent, $self->opt('warning'), $self->opt('critical') ),
		$percent . '% used, ' . $open . ' of ' . $max . ' open' );
} ## end sub check

=head2 handles

Returns the open files and the limit. Dies if they can not be found.

=cut

sub handles {
	my ($self) = @_;

	if ( $self->os eq 'linux' ) {

		# allocated, allocated but not used, which is 0 on newer kernels, and the limit
		my ( $allocated, $unused, $max ) = split( /\s+/, $self->proc_file('sys/fs/file-nr') );
		die("can not make sense of /proc/sys/fs/file-nr\n") if !defined($max) || $max !~ /\A[0-9]+\z/;
		return ( $allocated - $unused, $max );
	}
	if ( $self->os eq 'freebsd' ) {
		return ( $self->sysctl('kern.openfiles'), $self->sysctl('kern.maxfiles') );
	}

	die( 'not supported on ' . $self->os . "\n" );
} ## end sub handles

1;
