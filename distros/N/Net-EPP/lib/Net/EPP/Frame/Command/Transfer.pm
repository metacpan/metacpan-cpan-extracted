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

	$frame->setOp($op);

Sets the op of the frame (i.e. C<request>, C<cancel>, C<approve> or C<reject>).

=cut

sub setOp {
    my ($self, $op) = @_;
    $self->getCommandNode->setAttribute('op', $op);
}

1;
