# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id$
package Net::EPP;
use vars qw($VERSION);
use Net::EPP::Client;
use Net::EPP::Frame;
use Net::EPP::Protocol;
use Net::EPP::ResponseCodes;
use Net::EPP::Simple;
use strict;

our $VERSION = '0.22';

1;

__END__

=pod

=head1 NAME

C<Net::EPP> - a Perl library for the Extensible Provisioning Protocol (EPP)

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 5730)
is an application layer client-server protocol for the provisioning and
management of objects stored in a shared central repository. Specified
in XML, the protocol defines generic object management operations and an
extensible framework that maps protocol operations to objects. As of
writing, its only well-developed application is the provisioning of
Internet domain names, hosts, and related contact details.

This project offers a number of Perl modules which implement various
EPP-related functions:

=over

=item * a low level protocol implementation (L<Net::EPP::Protocol>)

=item * a low-level client (L<Net::EPP::Client>)

=item * a high-level client (L<Net::EPP::Simple>)

=item * an EPP frame builder (L<Net::EPP::Frame>)

=item * a utility library to export EPP responde codes (L<Net::EPP::ResponseCodes>)

=back

These modules were originally created and maintained by CentralNic for
use by their own registrars, but since their original release have
become widely used by registrars and registries of all kinds.

CentralNic has chosen to create this project to allow interested third
parties to contribute to the development of these libraries, and to
guarantee their long-term stability and maintenance. 

=head1 AUTHOR

CentralNic Ltd (http://www.centralnic.com/), with the assistance of other contributors around the world, including (but not limited to):

=over

=item Rick Jansen

=item Mike Kefeder

=item Sage Weil

=item Eberhard Lisse

=item Yulya Shtyryakova

=item Ilya Chesnokov

=item Simon Cozens

=item Patrick Mevzek

=item Alexander Biehl and Christian Maile, united-domains AG

=back   

=head1 REPORTING BUGS

Please email any bug reports to L<epp@centralnic.com>.

=head1 SEE ALSO

=over

=item * Google Code Project page: L<http://code.google.com/p/perl-net-epp>

=back

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
