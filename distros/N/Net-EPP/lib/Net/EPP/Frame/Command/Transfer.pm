# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Transfer.pm,v 1.3 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Transfer;
use Net::EPP::Frame::Command::Transfer::Contact;
use Net::EPP::Frame::Command::Transfer::Domain;
use base qw(Net::EPP::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Transfer - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>transferE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Transfer>

=head1 METHODS

=cut

sub setOp {
	my ($self, $op) = @_;
	$self->getCommandNode->setAttribute('op', $op);
}

=pod

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
