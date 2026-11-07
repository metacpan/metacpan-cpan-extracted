package Monitoring::Sneck::Checks::linux_ras;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::linux_ras - checks for errors rasdaemon has logged

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# ras-mc-ctl, found through PATH. Set by tests.
our $RAS_MC_CTL = 'ras-mc-ctl';

=head1 SYNOPSIS

    rasdaemon|perl:linux_ras

=head1 DESCRIPTION

Runs ras-mc-ctl db --summary, found through PATH, for the hardware
errors rasdaemon has logged, such as memory, PCIe, and machine check
errors. Any line that is not blank or starting with "No " is a error,
which is CRITICAL, the lines following the status line. ras-mc-ctl
exiting non-zero is UNKNOWN.

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my ( $exit, $output ) = $self->run_command( $RAS_MC_CTL, 'db', '--summary' );
	return $self->finish( $self->UNKNOWN, 'ras-mc-ctl exited ' . $exit . ', ' . ( $output =~ s/\s+\z//r ) )
		if $exit != 0;

	my @errors = grep { /\S/ && !/\ANo / } split( /\n/, $output );

	return $self->finish( $self->CRITICAL, 'rasdaemon has logged errors', @errors ) if @errors;

	return $self->finish( $self->OK, 'no errors logged by rasdaemon' );
} ## end sub check

1;
