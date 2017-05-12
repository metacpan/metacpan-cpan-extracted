# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Domain.pm,v 1.3 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Info::Domain;
use base qw(Net::EPP::Frame::Command::Info);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Info::Domain - an instance of L<Net::EPP::Frame::Command::Info>
for domain names.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Info::Domain;
	use strict;

	my $info = Net::EPP::Frame::Command::Info::Domain->new;
	$info->setDomain('example.tld');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <info>
	        <domain:info
	          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
	          domain-1.0.xsd">
	            <domain:name>example-1.tldE<lt>/domain:name>
	        </domain:info>
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
                    +----L<Net::EPP::Frame::Command::Info::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('info'), $package);

	my $domain = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	return $self;
}

=pod

=head1 METHODS

	$frame->setDomain($domain_name);

This specifies the domain name for which information is being requested.

=cut

sub setDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

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
