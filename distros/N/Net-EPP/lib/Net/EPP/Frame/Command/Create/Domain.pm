# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id$
package Net::EPP::Frame::Command::Create::Domain;
use base qw(Net::EPP::Frame::Command::Create);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Create::Domain - an instance of L<Net::EPP::Frame::Command::Create>
for domain objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Create::Domain;
	use strict;

	my $create = Net::EPP::Frame::Command::Create::Domain->new;
	$create->setDomain('example.uk.com);

	print $create->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <check>
	        <domain:create
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <domain:name>example-1.tldE<lt>/domain:name>
	        </domain:create>
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
                    +----L<Net::EPP::Frame::Command::Create::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('create'), $package);

	$self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	return $self;
}

=pod

=head1 METHODS

	my $element = $frame->setDomain($domain_name);

This sets the name of the object to be created. Returns the
C<E<lt>domain:nameE<gt>> element.

=cut

sub setDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

	$self->getNode('create')->getChildNodes->shift->appendChild($name);

	return 1;
}

sub setPeriod {
	my ($self, $period, $unit) = @_;

	$unit = 'y' if (!defined($unit) || $unit eq '');

	my $el = $self->createElement('domain:period');
	$el->setAttribute('unit', $unit);
	$el->appendText(int($period));

	$self->getNode('create')->getChildNodes->shift->appendChild($el);

	return 1;
}

sub setRegistrant {
	my ($self, $contact) = @_;

	my $registrant = $self->createElement('domain:registrant');
	$registrant->appendText($contact);

	$self->getNode('create')->getChildNodes->shift->appendChild($registrant);

	return 1;
}

sub setContacts {
	my ($self, $contacts) = @_;

	foreach my $type (keys(%{$contacts})) {
		my $contact = $self->createElement('domain:contact');
		$contact->setAttribute('type', $type);
		$contact->appendText($contacts->{$type});

		$self->getNode('create')->getChildNodes->shift->appendChild($contact);
	}

	return 1;
}

# 
# Type of elements of @ns depends on NS model used by EPP server.
#   hostObj model:
#       each element is a name of NS host object
#   hostAttr model:
#       each element is a hashref:
#       {
#           name => 'ns1.example.com,
#           addrs => [
#               { version => 'v4', addr => '192.168.0.10', },
#               { version => 'v4', addr => '192.168.0.20', },
#               ...
#           ];
#        }
#
sub setNS {
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
                $hostName->appendText( $host->{name} );
                $hostAttr->appendChild($hostName);

                # Adding IP addresses
                if ( exists $host->{addrs} && ref $host->{addrs} eq 'ARRAY' ) {
                        foreach my $addr ( @{ $host->{addrs} } ) {
                                my $hostAddr = $self->createElement('domain:hostAddr');
                                $hostAddr->appendText( $addr->{addr} );
                                $hostAddr->setAttribute( ip => $addr->{version} );
                                $hostAttr->appendChild($hostAddr);
                        }
                }

                # Adding host info to frame
                $ns->appendChild($hostAttr);
        }
	$self->getNode('create')->getChildNodes->shift->appendChild($ns);
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
	$self->getNode('create')->getChildNodes->shift->appendChild($ns);
        return 1;
}

sub setAuthInfo {
	my ($self, $authInfo) = @_;
	my $el = $self->addEl('authInfo');
	my $pw = $self->createElement('domain:pw');
	$pw->appendText($authInfo);
	$el->appendChild($pw);
	return $el;
}

sub appendStatus {
	my ($self, $status) = @_;
	return $self->addEl('status', $status);
}

sub addEl {
	my ($self, $name, $value) = @_;

	my $el = $self->createElement('domain:'.$name);
	$el->appendText($value) if defined($value);

	$self->getNode('create')->getChildNodes->shift->appendChild($el);

	return $el;
	
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
