# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Domain.pm,v 1.3 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Update::Domain;
use base qw(Net::EPP::Frame::Command::Update);
use Net::EPP::Frame::ObjectSpec;
use strict;
use warnings;

our $DNSSEC_URN	= 'urn:ietf:params:xml:ns:secDNS-1.1';

=pod

=head1 NAME

Net::EPP::Frame::Command::Update::Domain - an instance of L<Net::EPP::Frame::Command::Update>
for domain names.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Update::Domain;
	use strict;

	my $info = Net::EPP::Frame::Command::Update::Domain->new;
	$info->setDomain('example.tld');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <update>
	        <domain:update
	          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
	          domain-1.0.xsd">
	            <domain:name>example-1.tldE<lt>/domain:name>
	        </domain:update>
	      </update>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Update>
                    +----L<Net::EPP::Frame::Command::Update::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('update'), $package);

	my $domain = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	foreach my $grp (qw(add rem chg)) {
		my $el = $self->createElement(sprintf('domain:%s', $grp));
		$self->getNode('update')->getChildNodes->shift->appendChild($el);
	}

	return $self;
}

=pod

=head1 METHODS

	$frame->setDomain($domain_name);

This specifies the domain name to be updated.

=cut

sub setDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

	my $n = $self->getNode('update')->getChildNodes->shift;
	$n->insertBefore( $name, $n->firstChild );

	return 1;
}

=pod

	$frame->addStatus($type, $info);

Add a status of $type with the optional extra $info.

=cut

sub addStatus {
	my ($self, $type, $info) = @_;
	my $status = $self->createElement('domain:status');
	$status->setAttribute('s', $type);
	$status->setAttribute('lang', 'en');
	if ($info) {
		$status->appendText($info);
	}
	$self->getElementsByLocalName('domain:add')->shift->appendChild($status);
	return 1;
}

=pod

	$frame->remStatus($type);

Remove a status of $type.

=cut

sub remStatus {
	my ($self, $type) = @_;
	my $status = $self->createElement('domain:status');
	$status->setAttribute('s', $type);
	$self->getElementsByLocalName('domain:rem')->shift->appendChild($status);
	return 1;
}

=pod

	$frame->addContact($type, $contact);
	
Add a contact of $type.

=cut

sub addContact {
	my ($self, $type, $contact_id) = @_;
	
	my $contact = $self->createElement('domain:contact');
	$contact->setAttribute('type', $type);
	$contact->appendText($contact_id);

	$self->getElementsByLocalName('domain:add')->shift->appendChild($contact);
	return 1;
}

=pod
	
	$frame->remContact($type, $contact);
	
Remove a contact of $type.

=cut

sub remContact {
	my ($self, $type, $contact_id) = @_;
	
	my $contact = $self->createElement('domain:contact');
	$contact->setAttribute('type', $type);
	$contact->appendText($contact_id);

	$self->getElementsByLocalName('domain:rem')->shift->appendChild($contact);
	return 1;
}

=pod

	$frame->chgAuthinfo($auth);

Change the authinfo.

=cut

sub chgAuthInfo {
	my ($self,$authInfo) = @_;

	my $el = $self->createElement('domain:authInfo');
	my $pw = $self->createElement('domain:pw');
	$pw->appendText($authInfo);
	$el->appendChild($pw);

	$self->getElementsByLocalName('domain:chg')->shift->appendChild($el);
	return 1;
}

=pod

	$frame->chgRegistrant($registrant);

Change the authinfo.

=cut

sub chgRegistrant {
	my ($self,$contact) = @_;

	my $registrant = $self->createElement('domain:registrant');
	$registrant->appendText($contact);

	$self->getElementsByLocalName('domain:chg')->shift->appendChild($registrant);
	return 1;
}

=pod

	$frame->addNS('ns0.example.com'); # host object mode

	$frame->addNS({'name' => 'ns0.example.com', 'addrs' => [ { 'addr' => '127.0.0.1', 'type' => 4 } ] }); # host attribute mode

=cut 

sub addNS {
	my ($self, @ns) = @_;

	if ( ref $ns[0] eq 'HASH' ) {
		$self->addHostAttrNS(@ns);
	}
	else {
		$self->addHostObjNS(@ns);
	}
	return 1;
}


sub addHostAttrNS {
	my ($self, @ns) = @_;

	my $ns = $self->createElement('domain:ns');

	# Adding attributes
	foreach my $host (@ns) {
		my $hostAttr = $self->createElement('domain:hostAttr');

		# Adding NS name
		my $hostName = $self->createElement('domain:hostName');
		$hostName->appendText($host->{name});
		$hostAttr->appendChild($hostName);

		# Adding IP addresses
		if ( exists $host->{addrs} && ref $host->{addrs} eq 'ARRAY' ) {
			foreach my $addr ( @{ $host->{addrs} } ) {
				my $hostAddr = $self->createElement('domain:hostAddr');
				$hostAddr->appendText($addr->{addr});
				$hostAddr->setAttribute(ip => $addr->{version});
				$hostAttr->appendChild($hostAddr);
			}
		}

		# Adding host info to frame
		$ns->appendChild($hostAttr);
	}
	
	$self->getElementsByLocalName('domain:add')->shift->appendChild($ns);
	return 1;
}


sub addHostObjNS {
	my ($self, @ns) = @_;

	my $ns = $self->createElement('domain:ns');
	foreach my $host (@ns) {
		my $el = $self->createElement('domain:hostObj');
		$el->appendText($host);
		$ns->appendChild($el);
	}
	
	$self->getElementsByLocalName('domain:add')->shift->appendChild($ns);
	return 1;
}

=pod

	$frame->remNS('ns0.example.com'); # host object mode

	$frame->remNS({'name' => 'ns0.example.com', 'addrs' => [ { 'addr' => '127.0.0.1', 'type' => 4 } ] }); # host attribute mode

=cut 

sub remNS {
	my ($self, @ns) = @_;

	if ( ref $ns[0] eq 'HASH' ) {
		$self->remHostAttrNS(@ns);
	}
	else {
		$self->remHostObjNS(@ns);
	}
	return 1;
}


sub remHostAttrNS {
	my ($self, @ns) = @_;

	my $ns = $self->createElement('domain:ns');

	# Adding attributes
	foreach my $host (@ns) {
		my $hostAttr = $self->createElement('domain:hostAttr');

		# Adding NS name
		my $hostName = $self->createElement('domain:hostName');
		$hostName->appendText($host->{name});
		$hostAttr->appendChild($hostName);

		# Adding IP addresses
		if ( exists $host->{addrs} && ref $host->{addrs} eq 'ARRAY' ) {
			foreach my $addr ( @{ $host->{addrs} } ) {
				my $hostAddr = $self->createElement('domain:hostAddr');
				$hostAddr->appendText($addr->{addr});
				$hostAddr->setAttribute(ip => $addr->{version});
				$hostAttr->appendChild($hostAddr);
			}
		}

		# Adding host info to frame
		$ns->appendChild($hostAttr);
	}
	
	$self->getElementsByLocalName('domain:rem')->shift->appendChild($ns);
	return 1;
}


sub remHostObjNS {
	my ($self, @ns) = @_;

	my $ns = $self->createElement('domain:ns');
	foreach my $host (@ns) {
		my $el = $self->createElement('domain:hostObj');
		$el->appendText($host);
		$ns->appendChild($el);
	}
	
	$self->getElementsByLocalName('domain:rem')->shift->appendChild($ns);
	return 1;
}

=pod

=head2 DNSSEC methods

=cut

sub _get_dnsssec {
	my $self = shift;
	my $tag = shift;

	my $el = self->getElementsByTagNameNS($DNSSEC_URN, $tag);
	return $el if $el;

	my $ext = $self->getNode('extension');
	$ext = $self->getNode('command')->addNewChild(undef, 'extension')
	    if not defined $ext;

	my $upd = $ext->addNewChild($DNSSEC_URN, 'secDNS:update');
	$upd->addNewChild($DNSSEC_URN, 'secDNS:add');
	$upd->addNewChild($DNSSEC_URN, 'secDNS:rem');

	return $self->_get_dnssec($tag);
}

=pod

=head1 AUTHOR

CentralNic Ltd (http://www.centralnic.com/), with contributions from United Domains AG (http://www.united-domains.de/).

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::Frame>

=back

=cut

1;
