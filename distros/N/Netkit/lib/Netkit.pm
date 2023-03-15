package Netkit;

use Netkit::Machine;
use Netkit::Lan;
use Netkit::Vlan;
use Netkit::Lab;
use Netkit::Interface;
use Netkit::Route;
use Netkit::Attachment;
use Netkit::Rule;


our $VERSION = 0.02;

=head1 Name

Netkit - Create Netkit labs with code.

=head1 SYNOPSIS

Generates a standalone netkit lab from a selection of configurable objects.
 
=head1 DESCRIPTION

A more verbose yet more understandable way to create netkit machines using code.

Generates a standalone netkit lab from a selection of configurable objects.

Allows configurations of:

- LANs

- Interface attachments

- Static Routes

- Firewall rules

- NAT rules

- VLANs

Other elements of startup files can be added using the Machine extra field.

=head1 AUTHOR

Adams, Rhys <rhys@therhys.co.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Rhys Adams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.32.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
