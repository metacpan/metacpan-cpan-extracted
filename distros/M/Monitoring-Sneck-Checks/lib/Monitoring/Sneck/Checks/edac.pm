package Monitoring::Sneck::Checks::edac;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::edac - checks for memory errors Linux's EDAC has counted

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where EDAC is in sysfs. Set by tests.
our $EDAC = '/sys/devices/system/edac';

=head1 SYNOPSIS

    edac|perl:edac
    edac_ecc_box|perl:edac -r -w 10 -c 100

=head1 DESCRIPTION

Reads the corrected and uncorrected memory error counts of each memory
controller under /sys/devices/system/edac/mc, without rasdaemon. See
L<Monitoring::Sneck::Checks::linux_ras> for that.

- CRITICAL :: Any uncorrected errors. Corrected errors over --critical.

- WARNING :: Corrected errors over --warning. No memory controllers
with --required.

- UNKNOWN :: Not being Linux, or a controller's counts not being
readable.

- OK :: Everything else, including no memory controllers, as on VMs
and boxes without ECC or a EDAC driver, so the same check can go
everywhere.

The counts are since boot, or since they were last reset by writing to
reset_counters of the controller.

The DIMMs with errors are named, by their label or as mc0 dimm2 if it
has none, as are errors EDAC could not tie to a DIMM. A line for each
controller follows the status line.

=head1 OPTIONS

- -w, --warning :: Range for corrected errors.
Default :: 0

- -c, --critical :: Range for corrected errors.

- -r, --required :: WARNING if there are no memory controllers, for
boxes that should have ECC and a EDAC driver loaded.

=cut

sub option_spec { return ( 'warning|w=s', 'critical|c=s', 'required|r' ) }

sub defaults { return { warning => '0' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	die( 'not supported on ' . $self->os . "\n" ) if $self->os ne 'linux';

	my $mc_dir = $EDAC . '/mc';
	my $number = sub { ( $_[0] =~ /([0-9]+)\z/ )[0] };
	my @controllers;
	if ( opendir( my $dh, $mc_dir ) ) {
		@controllers = sort { $number->($a) <=> $number->($b) } grep { /\Amc[0-9]+\z/ } readdir($dh);
	}
	if ( !defined( $controllers[0] ) ) {
		return $self->finish( $self->opt('required') ? $self->WARNING : $self->OK, 'no EDAC memory controllers' );
	}

	# a file under mc, trimmed, or undef if it can not be read
	my $read = sub {
		my $content = read_file( $mc_dir . '/' . $_[0], err_mode => 'quiet' );
		return defined($content) ? $content =~ s/\A\s+|\s+\z//gr : undef;
	};
	# such as "3 corrected, 1 uncorrected", leaving out a count that is 0
	my $counts = sub {
		my ( $ce, $ue ) = @_;
		return join( ', ', ( $ce ? $ce . ' corrected' : () ), ( $ue ? $ue . ' uncorrected' : () ) );
	};

	my $corrected   = 0;
	my $uncorrected = 0;
	my @where;
	my @details;
	foreach my $controller (@controllers) {
		my $ce = $read->( $controller . '/ce_count' );
		my $ue = $read->( $controller . '/ue_count' );
		return $self->finish( $self->UNKNOWN, 'can not read the counts of ' . $mc_dir . '/' . $controller )
			if !defined($ce) || !defined($ue) || $ce !~ /\A[0-9]+\z/ || $ue !~ /\A[0-9]+\z/;
		$corrected   = $corrected + $ce;
		$uncorrected = $uncorrected + $ue;
		push(
			@details,
			join( ', ',
				$controller . ' ' . ( $read->( $controller . '/mc_name' ) // 'unknown' ),
				( $read->( $controller . '/size_mb' ) // '?' ) . ' MB',
				$ce . ' corrected',
				$ue . ' uncorrected' )
		);

		# newer kernels have dimm or rank dirs, depending on the driver
		my @dimms;
		if ( opendir( my $dh, $mc_dir . '/' . $controller ) ) {
			@dimms = sort { $number->($a) <=> $number->($b) } grep { /\A(?:dimm|rank)[0-9]+\z/ } readdir($dh);
		}
		foreach my $dimm (@dimms) {
			my $dimm_ce = $read->( $controller . '/' . $dimm . '/dimm_ce_count' ) || 0;
			my $dimm_ue = $read->( $controller . '/' . $dimm . '/dimm_ue_count' ) || 0;
			next if !$dimm_ce && !$dimm_ue;
			my $label = $read->( $controller . '/' . $dimm . '/dimm_label' );
			$label = $controller . ' ' . $dimm if !defined($label) || $label eq '';
			push( @where, $label . ' ' . $counts->( $dimm_ce, $dimm_ue ) );
		}
		my $noinfo_ce = $read->( $controller . '/ce_noinfo_count' ) || 0;
		my $noinfo_ue = $read->( $controller . '/ue_noinfo_count' ) || 0;
		push( @where, $controller . ' no DIMM ' . $counts->( $noinfo_ce, $noinfo_ue ) ) if $noinfo_ce || $noinfo_ue;
	} ## end foreach my $controller (@controllers)

	my $code = $self->worst( $self->threshold_status( $corrected, $self->opt('warning'), $self->opt('critical') ),
		$uncorrected ? $self->CRITICAL : $self->OK );
	$self->perfdata(
		label    => 'corrected',
		value    => $corrected,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0,
	);
	$self->perfdata( label => 'uncorrected', value => $uncorrected, critical => 0, min => 0 );
	my $message
		= scalar(@controllers)
		. ' memory controller'
		. ( @controllers == 1 ? '' : 's' ) . ', '
		. $corrected
		. ' corrected, '
		. $uncorrected
		. ' uncorrected';
	$message = $message . ', ' . join( ', ', @where ) if defined( $where[0] );

	return $self->finish( $code, $message, @details );
} ## end sub check

1;
