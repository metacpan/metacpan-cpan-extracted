package Net::EPP::Frame::Command::Update::Contact;
use base qw(Net::EPP::Frame::Command::Update);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Update::Contact - an instance of L<Net::EPP::Frame::Command::Update>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Update::Contact;
	use strict;

	my $info = Net::EPP::Frame::Command::Update::Contact->new;
	$info->setContact('REG-12345');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <info>REG-12345
	        <contact:update
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:id>example-1.tldE<lt>/contact:id>
	        </contact:update>
	      </info>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Update>
                    +----L<Net::EPP::Frame::Command::Update::Contact>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('update'), $package);

	my $contact = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('contact'));

	foreach my $grp (qw(add rem chg)) {
		my $el = $self->createElement(sprintf('contact:%s', $grp));
		$self->getNode('update')->getChildNodes->shift->appendChild($el);
	}

	return $self;
}

=pod

=head1 METHODS

	$frame->setContact($id);

This specifies the contact object to be updated.

=cut

sub setContact {
	my ($self, $id) = @_;

	my $el = $self->createElement('contact:id');
	$el->appendText($id);

	my $n = $self->getNode('update')->getChildNodes->shift;
	$n->insertBefore( $el, $n->firstChild );

	return 1;
}

=pod

	$frame->chgVoice($voice);

Change the contacts voice number.

=cut

sub chgVoice {
	my ($self, $voice) = @_;
	return $self->addEl('voice', $voice);
}

=pod

	$frame->chgFax($fax);

Change the contacts voice number.

=cut

sub chgFax {
	my ($self, $fax) = @_;
	return $self->addEl('fax', $fax);
}

=pod

	$frame->chgEmail($email);

Change the contacts email.

=cut

sub chgEmail {
	my ($self, $email) = @_;
	return $self->addEl('email', $email);
}

=pod

	$frame->addStatus($type, $info);

Add a status of $type with the optional extra $info.

=cut

sub addStatus {
	my ($self, $type, $info) = @_;
	my $status = $self->createElement('contact:status');
	$status->setAttribute('s', $type);
	$status->setAttribute('lang', 'en');
	if ($info) {
		$status->appendText($info);
	}
	$self->getElementsByLocalName('contact:add')->shift->appendChild($status);
	return 1;
}

=pod

	$frame->remStatus($type);

Remove a status of $type.

=cut

sub remStatus {
	my ($self, $type) = @_;
	my $status = $self->createElement('contact:status');
	$status->setAttribute('s', $type);
	$self->getElementsByLocalName('contact:rem')->shift->appendChild($status);
	return 1;
}

sub chgPostalInfo {
	my ($self, $type, $name, $org, $addr) = @_;

	my $el = $self->createElement('contact:postalInfo');
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

	$self->getElementsByLocalName('contact:chg')->shift->appendChild($el);

	return $el;
}


=pod

	$frame->chgAuthinfo($auth);

Change the authinfo.

=cut

sub chgAuthInfo {
	my ($self,$authInfo) = @_;

	my $el = $self->createElement('contact:authInfo');
	my $pw = $self->createElement('contact:pw');
	$pw->appendText($authInfo);
	$el->appendChild($pw);

	$self->getElementsByLocalName('contact:chg')->shift->appendChild($el);
	return 1;
}

sub addEl {
	my ($self, $name, $value) = @_;

	my $el = $self->createElement('contact:'.$name);
	$el->appendText($value) if defined($value);

	$self->getElementsByLocalName('contact:chg')->shift->appendChild($el);

	return $el;

}

1;
