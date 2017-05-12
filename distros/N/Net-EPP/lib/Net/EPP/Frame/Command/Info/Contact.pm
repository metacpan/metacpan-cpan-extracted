# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Contact.pm,v 1.4 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Info::Contact;
use base qw(Net::EPP::Frame::Command::Info);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Info::Contact - an instance of L<Net::EPP::Frame::Command::Info>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Info::Contact;
	use strict;

	my $info = Net::EPP::Frame::Command::Info::Contact->new;
	$info->setContact('REG-12345');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <info>
	        <contact:info
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:id>REG-12345E<lt>/contact:id>
	        </contact:info>
	      </info>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Info>
                    +----L<Net::EPP::Frame::Command::Info::Contact>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('info'), $package);

	my $contact = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('contact'));

	return $self;
}

=pod

=head1 METHODS

	$frame->setContact($contactID);

This specifies the contact object for which information is being requested.

=cut

sub setContact {
	my ($self, $id) = @_;

	my $name = $self->createElement('contact:id');
	$name->appendText($id);

	$self->getNode('info')->getChildNodes->shift->appendChild($name);

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
