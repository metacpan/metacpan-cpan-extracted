=head1 NAME

Probe::MachineInfo::Hostid - Host ID

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::Hostid;

use IO::All;
# pragmata
use base qw(Probe::MachineInfo::SimpleMetric);
use strict;
use warnings;



# Standard Perl Library and CPAN modules
use English;

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#


=head2 command

 command

=cut

sub command {
	my ($self) = @_;

	return '/usr/bin/hostid';

}


1;

=head1 AUTHOR

Sagar R. Shah

=cut
