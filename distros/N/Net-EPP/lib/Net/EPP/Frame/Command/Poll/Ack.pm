package Net::EPP::Frame::Command::Poll::Ack;
use base qw(Net::EPP::Frame::Command::Poll);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Poll::Ack - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>PollE<gt>> acknowledge command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Poll>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('poll'), $package);
	$self->getCommandNode->setAttribute('op' => 'ack');
	return $self;
}

=pod

=head1 METHODS

	$frame->setMsgID($id);

This method sets the C<msgID> attribute on the C<E<lt>pollE<gt>> element that
is used to specify the message ID being acknowleged.

=cut

sub setMsgID {
	my ($self, $id) = @_;
	$self->getCommandNode->setAttribute('msgID' => $id);
	return 1;
}

1;
