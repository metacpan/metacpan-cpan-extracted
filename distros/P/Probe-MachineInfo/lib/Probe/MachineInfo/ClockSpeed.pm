=head1 NAME

Probe::MachineInfo::ClockSpeed - Clock Speed

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::ClockSpeed;


# pragmata
use base qw(Probe::MachineInfo::Metric);
use strict;
use warnings;


# Standard Perl Library and CPAN modules
use English;
use Unix::Processors;

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#


=head2 get

 get()

Uses Unix::Processors to return the number of processors on the machine. If
possible it returns undef.

=cut

sub get {
	my ($self) = @_;

	my $proc = Unix::Processors->new();
	my $speed;
	eval {
		$speed = $proc->max_clock();
	};
	return $speed;
}

=head2 units

 units()

mins

=cut

sub units {
	my ($self) = @_;

	return "MHz";
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
