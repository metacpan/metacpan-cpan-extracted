=head1 NAME

Probe::MachineInfo::Hostname - Hostname Name

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::Hostname;


# pragmata
use base qw(Probe::MachineInfo::Metric);
use strict;
use warnings;


# Standard Perl Library and CPAN modules
use English;
use Sys::Hostname;

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#


=head2 get

 get()

=cut

sub get {
	my ($self) = @_;

	return hostname();
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
