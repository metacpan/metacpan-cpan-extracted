package Net::EPP::Frame::Command::Check::Domain;
use base qw(Net::EPP::Frame::Command::Check);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Check::Domain - an instance of L<Net::EPP::Frame::Command::Check>
for domain names.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Check::Domain;
	use strict;

	my $check = Net::EPP::Frame::Command::Check::Domain->new;
	$check->addDomain('example-1.tld');
	$check->addDomain('example-2.tld');
	$check->addDomain('example-2.tld');

	print $check->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <check>
	        <domain:check
	          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
	          domain-1.0.xsd">
	            <domain:name>example-1.tldE<lt>/domain:name>
	            <domain:name>example-2.tldE<lt>/domain:name>
	            <domain:name>example-3.tldE<lt>/domain:name>
	        </domain:check>
	      </check>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Check>
                    +----L<Net::EPP::Frame::Command::Check::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('check'), $package);

	$self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	return $self;
}

=pod

=head1 METHODS

	$frame->addDomain($domain_name);

This adds a domain name to the list of domains to be checked.

=cut

sub addDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

	$self->getNode('check')->getChildNodes->shift->appendChild($name);

	return 1;
}

1;
