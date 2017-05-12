# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Check.pm,v 1.5 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Check;
use base qw(Net::EPP::Frame::Command);
use Net::EPP::Frame::Command::Check::Domain;
use Net::EPP::Frame::Command::Check::Contact;
use Net::EPP::Frame::Command::Check::Host;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Check - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>checkE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Check>

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
