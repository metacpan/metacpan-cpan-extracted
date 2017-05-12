
package Net::Link;

use strict;
use warnings;

use Net::Interface;
use Carp;
use IO::File;

our $VERSION = '0.01';

our @ISA = qw( Net::Interface );

croak(__PACKAGE__ . " requires Linux") if $^O ne 'linux';
croak(__PACKAGE__ . " requires /sys/") unless -d '/sys/';

sub up {
	my ($self) = @_;

	my $carrier = '/sys/class/net/' . $self->name . '/carrier';

	my $io = new IO::File($carrier);
	if($io) {
		my $line = $io->getline;
		return ($line and $line =~ /^1/);
	}

	return;
}


sub down { return ! $_[0]->up }


!0;


__END__

=head1 NAME

Net::Link

=head1 SYNOPSIS

	use Net::Link;

	my $if = new Net::Link('eth0');

	print "Got uplink.\n" if($if->up);

=head1 DESCRIPTION

This is a simple extension of L<Net::Interface> that adds two methods to
determine if a network interface has a link/carrier. The information is taken
from the 'sysfs', a virtual file system on Linux systems that provides system
information (so the module will work on Linux only). The module has been tested
with ethernet and wireless network devices.

For ethernet devices, being "up" means that there's a ethernet cable plugged in the
port.

For wireless network devices, having an uplink means that the device is
associated to an access point or something else.

The information provided by this module affects only the "link" level. For
higher level information (IP address, netmask, etc.), use the methods provided
by L<Net::Interface>.

=head1 METHODS

The added methods are "up" and "down". Both return a boolean.

=head1 COPYRIGHT

Copyright (C) 2008 by Jonas Kramer <jkramer@cpan.org>. Published under the
terms of the Artistic License 2.0.

=cut
