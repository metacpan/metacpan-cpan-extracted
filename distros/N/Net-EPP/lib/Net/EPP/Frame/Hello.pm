# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Hello.pm,v 1.4 2011/12/03 11:44:51 gavin Exp $
package Net::EPP::Frame::Hello;
use base qw(Net::EPP::Frame);

=pod

=head1 NAME

Net::EPP::Frame::Hello - an instance of L<Net::EPP::Frame> for client greetings

=head1 DESCRIPTION

This module is a subclass of L<Net::EPP::Frame> that represents EPP client
greetings.

Clients can send a greeting to an EPP server at any time during a session.
According to the EPP RFC, the server must transmit an EPP greeting frame to the
client upon connection, and in response to an EPP C<E<lt>helloE<gt>> command.
The C<E<lt>greetingE<gt>> frame provides information about the server,
including the server time, access control rules, and a list of the object
types that are provisioned by the server.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Hello>

=head1 METHODS

This module does not define any methods in addition to those it inherits from
its ancestors.

=head1 AUTHOR

CentralNic Ltd (http://www.centralnic.com/).

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::Frame>

=back

=cut

1;
