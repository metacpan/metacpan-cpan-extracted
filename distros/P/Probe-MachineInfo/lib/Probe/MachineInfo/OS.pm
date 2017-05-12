=head1 NAME

Probe::MachineInfo::OS - OS Name

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::OS;


# pragmata
use base qw(Probe::MachineInfo::Metric);
use strict;
use warnings;


# Standard Perl Library and CPAN modules
use English;
use POSIX qw(uname);

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

	return (uname)[0];
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
