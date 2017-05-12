=head1 NAME

Probe::MachineInfo::Uptime - Host ID

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::Uptime;


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

/usr/bin/uptime

=cut

sub command {
	my($self) = @_;

	return '/usr/bin/uptime';

}

=head2 regex

=cut

sub regex {
	my($self) = @_;
	return qr/ up \s+ (.*?) , \s+ \d+ \s+ user /x;
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
