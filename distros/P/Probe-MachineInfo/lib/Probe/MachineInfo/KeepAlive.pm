=head1 NAME

Probe::MachineInfo::KeepAlive - Keepalive

=head1 SYNOPSIS

blah

=head1 DESCRIPTION

blah

=head1 PUBLIC INTERFACE

=cut

package Probe::MachineInfo::KeepAlive;


# pragmata
use base qw(Probe::MachineInfo::Metric);
use strict;
use warnings;


# Standard Perl Library and CPAN modules

#
# CLASS ATTRIBUTES
#

#
# CONSTRUCTOR
#


=head2 get

 get()

Calculates keepalive by multiplying /proc/sys/net/ipv4/tcp_keepalive_{intvl,probes}

=cut

sub get {
	my ($self) = @_;

	my @values = ();
	my $filename_base = '/proc/sys/net/ipv4/tcp_keepalive_';

	foreach my $property (qw(intvl probes)) {
		my $filename = $filename_base . $property;
		open(FILE, '<', $filename) or $self->log->warn("Unable to open $filename: $!\n") and return;
		my $value = <FILE>;
		chomp $value;
		close(FILE) or $self->log->debug("Unable to close $filename: $!\n");
		push @values, $value;
	}

	return unless @values == 2;

	my $keepalive = $values[0] * $values[1];

	# Return in mins
	return $keepalive/60;
}

=head2 units

 units()

mins

=cut

sub units {
	my ($self) = @_;

	return "mins";
}

1;

=head1 AUTHOR

Sagar R. Shah

=cut
