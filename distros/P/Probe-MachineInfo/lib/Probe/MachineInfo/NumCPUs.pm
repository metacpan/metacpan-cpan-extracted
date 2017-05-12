=head1 NAME

Probe::MachineInfo::NumCPUs - Number of CPUs

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::NumCPUs;


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
possible it returns the number of physical processors. If this is not possible
on the particular operating system then returns the number of cpus online.

=cut

sub get {
	my ($self) = @_;

	my $proc = Unix::Processors->new();
	my $num;
	eval {
		$num = $proc->max_physical;
	};
	if($@) {
		$num = $proc->max_online;
	}
	return $num;
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
