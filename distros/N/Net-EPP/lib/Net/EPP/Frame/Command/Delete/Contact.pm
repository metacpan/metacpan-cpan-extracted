package Net::EPP::Frame::Command::Delete::Contact;
use base qw(Net::EPP::Frame::Command::Delete);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Delete::Contact - an instance of L<Net::EPP::Frame::Command::Delete>
for contact objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Delete::Contact;
	use strict;

	my $delete = Net::EPP::Frame::Command::Delete::Contact->new;
	$delete->setContact('contact-id');

	print $delete->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <delete>
	        <contact:delete
	          xmlns:contact="urn:ietf:params:xml:ns:contact-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0
	          contact-1.0.xsd">
	            <contact:name>contact-idE<lt>/contact:name>
	        </contact:delete>
	      </delete>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Delete>
                    +----L<Net::EPP::Frame::Command::Delete::Contact>

=cut

sub new {
    my $package = shift;
    my $self    = bless($package->SUPER::new('delete'), $package);

    my $contact = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('contact'));

    return $self;
}

=pod

=head1 METHODS

	$frame->setContact($domain_name);

This specifies the contact object to be deleted.

=cut

sub setContact {
    my ($self, $id) = @_;

    my $name = $self->createElement('contact:id');
    $name->appendText($id);

    $self->getNode('delete')->getChildNodes->shift->appendChild($name);

    return 1;
}

1;
