# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Response.pm,v 1.9 2011/07/04 09:48:51 gavin Exp $
package Net::EPP::Frame::Response;
use Net::EPP::ResponseCodes;
use base qw(Net::EPP::Frame);

=pod

=head1 NAME

Net::EPP::Frame::Response - an instance of L<Net::EPP::Frame> for server responses

=head1 DESCRIPTION

This module is a subclass of L<Net::EPP::Frame> that represents EPP server
responses.

Responses are sent back to clients when the server receives a
C<E<lt>commandE<gt>> frame.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Response>

=cut

sub new {
	my $package = shift;
	my $self = $package->SUPER::new('response');
	return bless($self, $package);
}

sub _addExtraElements {
	my $self = shift;

	my $result = $self->createElement('result');
	$result->appendChild($self->createElement('msg'));
	$self->response->addChild($result);

	$self->result->setAttribute('code' => COMMAND_FAILED);

	$self->response->addChild($self->createElement('resData'));

	my $trID = $self->createElement('trID');
	$trID->addChild($self->createElement('clTRID'));
	$trID->addChild($self->createElement('svTRID'));
	$self->response->addChild($trID);

	return 1;
}

=pod

=head1 METHODS

	my $node = $frame->response;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>commandE<gt>> element.

	my $node = $frame->result;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>resultE<gt>> element.

	my $node = $frame->msg;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>msgE<gt>> element.

	my $node = $frame->resData;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>resDataE<gt>> element.

	my $node = $frame->trID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>trIDE<gt>> element.

	my $node = $frame->clTRID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>clTRIDE<gt>> element.

	my $node = $frame->svTRID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svTRIDE<gt>> element.

=cut

sub response {$_[0]->getNode('response') }
sub result {$_[0]->getNode('result') }
sub resData {$_[0]->getNode('resData') }
sub trID {$_[0]->getNode('trID') }
sub clTRID {$_[0]->getNode('clTRID') }
sub svTRID {$_[0]->getNode('svTRID') }

=pod

	my $msg = $frame->code;

This method returns the code attribute of the C<E<lt>resultE<gt>>
element.

=cut

sub code {
	 my $self = shift;
	 my $result = $self->result;
	 if ($result) {
		  return $result->getAttribute('code');
	 }
	 return COMMAND_FAILED;
}

=pod

	my $msg = $frame->msg;

This method returns a string containing the text content of the
C<E<lt>msgE<gt>> element.

=cut

sub msg {
	my $self = shift;
	my $msgs = $self->getElementsByLocalName('msg');
	return $msgs->shift->textContent if ($msgs->size == 1);
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
