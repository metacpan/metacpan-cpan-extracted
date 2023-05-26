package Net::EPP::Frame::Command::Transfer::Domain;
use base qw(Net::EPP::Frame::Command::Transfer);
use Net::EPP::Frame::ObjectSpec;
use strict;


=pod

=head1 NAME

Net::EPP::Frame::Command::Transfer::Domain - an instance of L<Net::EPP::Frame::Command::Transfer>
for domain objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Transfer::Domain;
	use strict;

	my $info = Net::EPP::Frame::Command::Transfer::Domain->new;
	$info->setOp('query');
	$info->setDomain('example.tld');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <transfer op="query">
	        <domain:transfer
	          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
	          domain-1.0.xsd">
	            <domain:name>example.tldE<lt>/domain:name>
	        </domain:transfer>
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
                    +----L<Net::EPP::Frame::Command::Transfer::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('transfer'), $package);

	my $domain = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	return $self;
}

=pod

=head1 METHODS

	$frame->setDomain('example.tld');

This method specifies the domain name for the transfer.

=cut

sub setDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

	$self->getNode('transfer')->getChildNodes->shift->appendChild($name);

	return 1;
}


=pod

	$frame->period($years);

This sets the optional renewal period for the transfer.

=cut

sub setPeriod {
	my ($self, $years) = @_;

	my $period = $self->createElement('domain:period');
	$period->setAttribute('unit', 'y');
	$period->appendText($years);

	$self->getNode('transfer')->getChildNodes->shift->appendChild($period);

	return 1;
}

=pod

	$frame->setAuthInfo($pw);

This sets the authInfo code for the transfer.

=cut

sub setAuthInfo {
	my ($self, $code) = @_;

	my $pw = $self->createElement('domain:pw');
	$pw->appendText($code);

	my $authInfo = $self->createElement('domain:authInfo');
	$authInfo->appendChild($pw);

	$self->getNode('transfer')->getChildNodes->shift->appendChild($authInfo);

	return 1;
}

1;
