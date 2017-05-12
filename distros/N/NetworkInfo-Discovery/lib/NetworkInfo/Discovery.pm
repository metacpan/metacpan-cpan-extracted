package NetworkInfo::Discovery;

use strict;
use warnings;
use vars qw($VERSION);
use NetworkInfo::Discovery::Register;

$VERSION = '0.12';

=head1 NAME

NetworkInfo::Discovery - Modules for network discovery and mapping

=head1 DESCRIPTION

NetworkInfo::Discovery is a set of modules that can be used to discover network 
topology, interfaces on the network, and information about the links between subnets.
This information is brought together into C<NetworkInfo::Discovery::Register> 
where it can be examined and used to build a unified map of the network.
The network map is controlled from a single location.

Host detection currently runs from a single location, but in the future
there will be support for having remote agents that contribute to the
central map.

=head1 MODULE LAYOUT

NetworkInfo::Discovery consists of several modules that all into three categories:

=head2 Register

The Register maintains a full picture of the network.  Anything that is discovered 
should be put into the Register where little details can be used to build the 
larger picture.  

=head2 Network Objects

These are the things about your network that you want to discover.  Namely, interfaces, 
subnets, and gateways.  See L<NetworkInfo::Discovery::Register> for details about what
attributes these have.

=head2 Detection Modules

These modules should all be a subclass of C<NetworkInfo::Discovery::Detect>.
It is their job to detect interfaces, gateways, and subnets that can then be 
fed into the register.  The following are the existing detection modules:

=over 4

=item Sniff 

is a passive monitor that listens to ethernet traffic on the
local sement to build a list of Hosts.

=item Traceroute 

is used to map interfaces and gateways using traceroute.

=item Scan 

is used to probe ip addresses or ranges of ip addresses for open tcp or udp ports.

=back

=head1 AVAILABILITY

This module can be found in CPAN at http://www.cpan.org/authors/id/T/TS/TSCANLAN/
or at http://they.gotdns.org:88/~tscanlan/perl/

=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Register>

L<NetworkInfo::Discovery::Detect>

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

L<NetworkInfo::Discovery::Scan>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Thomas P. Scanlan IV.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
