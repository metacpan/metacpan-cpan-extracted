# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Ack.pm,v 1.2 2011/12/03 11:44:52 gavin Exp $
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
