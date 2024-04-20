package Net::EPP::Frame::Command::Transfer::Contact;
use base qw(Net::EPP::Frame::Command::Transfer);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Transfer::Contact - an instance of L<Net::EPP::Frame::Command::Transfer>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Transfer::Contact;
	use strict;

	my $info = Net::EPP::Frame::Command::Transfer::Contact->new;
	$info->setOp('query');
	$info->setContact('REG-12345');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <transfer op="query">
	        <contact:transfer
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:id>REG-12345E<lt>/contact:id>
	        </contact:transfer>
	      </transfer>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Transfer>
                    +----L<Net::EPP::Frame::Command::Transfer::Contact>

=cut

sub new {
    my $package = shift;
    my $self    = bless($package->SUPER::new('transfer'), $package);

    my $contact = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('contact'));

    return $self;
}

=pod

=head1 METHODS

	$frame->setContact($contactID);

This specifies the contact object for the transfer.

=cut

sub setContact {
    my ($self, $id) = @_;

    my $name = $self->createElement('contact:id');
    $name->appendText($id);

    $self->getNode('transfer')->getChildNodes->shift->appendChild($name);

    return 1;
}

=pod

	$frame->setAuthInfo($pw);

This sets the authInfo code for the transfer.

=cut

sub setAuthInfo {
    my ($self, $code) = @_;

    my $pw = $self->createElement('contact:pw');
    $pw->appendText($code);

    my $authInfo = $self->createElement('contact:authInfo');
    $authInfo->appendChild($pw);

    $self->getNode('transfer')->getChildNodes->shift->appendChild($authInfo);

    return 1;
}

1;
