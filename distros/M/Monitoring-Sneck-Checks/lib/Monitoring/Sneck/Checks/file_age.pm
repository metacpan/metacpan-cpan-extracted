package Monitoring::Sneck::Checks::file_age;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::file_age - checks how old and how big a file is

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    backup_age|perl:file_age -f /var/backups/db.sql.gz -w 90000 -c 180000 -W 1024:
    heartbeat|perl:file_age -f /var/run/app.heartbeat -w 60 -c 300
    nightly_dump|perl:file_age -n '/var/backups/db-*.sql.gz' -w 90000 -c 180000 -W 1024:

=head1 DESCRIPTION

Checks the age of a file, from when it was last changed, and its size.
A file that is not there is CRITICAL, unless --ignore-missing is given.

With --newest, the file is the most recently changed one matching a
glob, for files named by date, such as backups. Nothing matching is
the same as a file not being there.

As ranges, a plain number such as 240 is over 240 seconds, and 1024: is
under 1024 bytes.

=head1 OPTIONS

- -f, --file :: The file.

- -n, --newest :: A glob, the newest file matching it being checked, in
place of --file.

- -w, --warning :: Range of seconds for the age.
Default :: 240

- -c, --critical :: Range of seconds for the age.
Default :: 600

- -W, --size-warning :: Range of bytes for the size.

- -C, --size-critical :: Range of bytes for the size.

- -i, --ignore-missing :: A missing file is OK.

One of --file or --newest must be given.

=cut

sub option_spec {
	return (
		'file|f=s',         'newest|n=s',        'warning|w=s', 'critical|c=s',
		'size-warning|W=s', 'size-critical|C=s', 'ignore-missing|i'
	);
}

sub defaults { return { warning => '240', critical => '600' } }

sub validate {
	my ( $self, $options ) = @_;

	return ('give one of --file or --newest') if defined( $options->{file} ) == defined( $options->{newest} );

	return ();
}

sub ranges { return ( 'warning', 'critical', 'size-warning', 'size-critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $file  = $self->opt('file');
	my $which = '';
	if ( defined( $self->opt('newest') ) ) {
		require File::Glob;
		my %changed = map { $_ => ( stat($_) )[9] } grep { -f $_ } File::Glob::bsd_glob( $self->opt('newest') );
		($file) = sort { $changed{$b} <=> $changed{$a} || $a cmp $b } keys(%changed);
		if ( !defined($file) ) {
			my $nothing = 'nothing matches ' . $self->opt('newest');
			return $self->finish( $self->opt('ignore-missing') ? $self->OK : $self->CRITICAL, $nothing );
		}
		$which = 'the newest of ' . $self->opt('newest') . ', ';
	} ## end if ( defined( $self->opt('newest') ) )
	my @stat = stat($file);
	if ( !defined( $stat[0] ) ) {
		my $why = $!;
		if ( $self->opt('ignore-missing') && !-e $file ) {
			return $self->finish( $self->OK, $file . ' is not there' );
		}
		return $self->finish( $self->CRITICAL, $file . ', ' . $why );
	}

	my $age  = time - $stat[9];
	my $size = $stat[7];
	$self->perfdata(
		label    => 'age',
		value    => $age,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical')
	);
	$self->perfdata(
		label    => 'size',
		value    => $size,
		uom      => 'B',
		warning  => $self->opt('size-warning'),
		critical => $self->opt('size-critical'),
		min      => 0
	);
	my $code = $self->worst(
		$self->threshold_status( $age,  $self->opt('warning'),      $self->opt('critical') ),
		$self->threshold_status( $size, $self->opt('size-warning'), $self->opt('size-critical') ),
	);

	return $self->finish( $code, $which . $file . ' is ' . $age . ' seconds old and ' . $size . ' bytes' );
} ## end sub check

1;
