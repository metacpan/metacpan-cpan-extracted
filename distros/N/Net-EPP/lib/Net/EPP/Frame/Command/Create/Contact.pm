package Net::EPP::Frame::Command::Create::Contact;
use base qw(Net::EPP::Frame::Command::Create);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Create::Contact - an instance of L<Net::EPP::Frame::Command::Create>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Create::Contact;
	use strict;

	my $create = Net::EPP::Frame::Command::Create::Contact->new;
	$create->setContact('contact-id);

	print $create->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <check>
	        <contact:create
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:id>example-1.tldE<lt>/contact:id>
	        </contact:create>
	      </check>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Create>
                    +----L<Net::EPP::Frame::Command::Create::Contact>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('create'), $package);

	$self->addObject(Net::EPP::Frame::ObjectSpec->spec('contact'));

	return $self;
}

=pod

=head1 METHODS

	my $element = $frame->setContact($contact_id);

This sets the contact ID of the object to be created. Returns the
C<E<lt>contact:nameE<gt>> element.

=cut

sub setContact {
	my ($self, $id) = @_;
	return $self->addEl('id', $id);
}

sub setVoice {
	my ($self, $voice) = @_;
	return $self->addEl('voice', $voice);
}

sub setFax {
	my ($self, $fax) = @_;
	return $self->addEl('fax', $fax);
}

sub setEmail {
	my ($self, $email) = @_;
	return $self->addEl('email', $email);
}

sub setAuthInfo {
	my ($self, $authInfo) = @_;
	my $el = $self->addEl('authInfo');
	my $pw = $self->createElement('contact:pw');
	$pw->appendText($authInfo);
	$el->appendChild($pw);
	return $el;
}

sub addPostalInfo {
	my ($self, $type, $name, $org, $addr) = @_;
	my $el = $self->addEl('postalInfo');
	$el->setAttribute('type', $type);

	my $nel = $self->createElement('contact:name');
	$nel->appendText($name);

	my $oel = $self->createElement('contact:org');
	$oel->appendText($org);

	my $ael = $self->createElement('contact:addr');

	if (ref($addr->{street}) eq 'ARRAY') {
		foreach my $street (@{$addr->{street}}) {
			my $sel = $self->createElement('contact:street');
			$sel->appendText($street);
			$ael->appendChild($sel);
		}
	}

	foreach my $name (qw(city sp pc cc)) {
		my $vel = $self->createElement('contact:'.$name);
		$vel->appendText($addr->{$name});
		$ael->appendChild($vel);
	}

	$el->appendChild($nel);
	$el->appendChild($oel) if $org;
	$el->appendChild($ael);

	return $el;
}

sub appendStatus {
	my ($self, $status) = @_;
	return $self->addEl('status', $status);
}

sub addEl {
	my ($self, $name, $value) = @_;

	my $el = $self->createElement('contact:'.$name);
	$el->appendText($value) if defined($value);

	$self->getNode('create')->getChildNodes->shift->appendChild($el);

	return $el;
	
}

1;
