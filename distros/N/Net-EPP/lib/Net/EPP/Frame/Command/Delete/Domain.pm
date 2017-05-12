# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Domain.pm,v 1.2 2011/12/03 11:44:52 gavin Exp $
package Net::EPP::Frame::Command::Delete::Domain;
use base qw(Net::EPP::Frame::Command::Delete);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Delete::Domain - an instance of L<Net::EPP::Frame::Command::Delete>
for domain names.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Delete::Domain;
	use strict;

	my $delete = Net::EPP::Frame::Command::Delete::Domain->new;
	$delete->setDomain('example.tld');

	print $delete->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <delete>
	        <domain:delete
	          xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0
	          domain-1.0.xsd">
	            <domain:name>example.tldE<lt>/domain:name>
	        </domain:delete>
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
                    +----L<Net::EPP::Frame::Command::Delete::Domain>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('delete'), $package);

	my $domain = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('domain'));

	return $self;
}

=pod

=head1 METHODS

	$frame->setDomain($domain_name);

This specifies the domain name to be deleted.

=cut

sub setDomain {
	my ($self, $domain) = @_;

	my $name = $self->createElement('domain:name');
	$name->appendText($domain);

	$self->getNode('delete')->getChildNodes->shift->appendChild($name);

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
