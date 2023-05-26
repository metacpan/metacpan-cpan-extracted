package Net::EPP::Frame::Command::Info;
use Net::EPP::Frame::Command::Info::Contact;
use Net::EPP::Frame::Command::Info::Domain;
use Net::EPP::Frame::Command::Info::Host;
use base qw(Net::EPP::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Info - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>infoE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Info>

=head1 METHODS

This module does not define any methods in addition to those it inherits from
its ancestors.

=cut

1;
