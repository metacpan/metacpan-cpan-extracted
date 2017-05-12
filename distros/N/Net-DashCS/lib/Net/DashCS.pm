package Net::DashCS;

use strict;
use vars qw( $VERSION );
$VERSION = '0.01';
sub Version { $VERSION };

1;

__END__

=head1 NAME

Net::DashCS - Perl client interface to Dash Carrier Services SOAP api

=head1 SYNOPSIS

use Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort;

my $port = new Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort;

my $response = $port->getURIs();

=head1 DESCRIPTION

Net::DashCS allows perl programs to perform provisioning of Dash Carrier
Services.  Presently on the Emergency provisioning is provided.

=head1 SEE ALSO

L<Net::DashCS::Interfaces::EmergencyProvisioningService::EmergencyProvisioningPort>  and http://dashcs.com

=head1 BUGS

Creepy.

=head1 AUTHOR AND COPYRIGHT

Jeff Finucane  jeff-net-dashcs@weasellips.com

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
