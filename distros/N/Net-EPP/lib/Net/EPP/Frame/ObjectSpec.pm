#! $Id: ObjectSpec.pm,v 1.2 2007/12/03 11:44:51 gavin Exp $
package Net::EPP::Frame::ObjectSpec;
use vars qw($SPEC);
use strict;

our $SPEC = {
	'domain'	=> [ 'urn:ietf:params:xml:ns:domain-1.0',	'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd'	],
	'contact'	=> [ 'urn:ietf:params:xml:ns:contact-1.0',	'urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd'	],
	'host'		=> [ 'urn:ietf:params:xml:ns:host-1.0',		'urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd'		],
	'secDNS'	=> [ 'urn:ietf:params:xml:ns:secDNS-1.1',	'urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd'	],
};

sub spec {
	my $type = $_[1];

	return (!defined($SPEC->{$type}) ? undef : ($type, @{$SPEC->{$type}}));
}

=pod

=head1 NAME

Net::EPP::Frame::ObjectSpec - metadata about EPP object types

=head1 SYNOPSIS

	use Net::EPP::Frame;
	use strict;

	# create an EPP frame:
	my $check = Net::EPP::Frame::Command::Check->new;

	# get the spec:
	my @spec = Net::EPP::Frame::ObjectSpec->spec('domain');

	# create an object:
	my $domain = $check->addObject(@spec);

	# set the attributes:
	my $name = $check->createElement('domain:name');
	$name->addText('example.tld');

	# assemble the frame:
	$domain->appendChild($name);
	$check->getCommandNode->appendChild($domain);

	print $check->toString;

=head1 DESCRIPTION

EPP is the Extensible Provisioning Protocol. EPP (defined in RFC 4930) is an
application layer client-server protocol for the provisioning and management of
objects stored in a shared central repository. Specified in XML, the protocol
defines generic object management operations and an extensible framework that
maps protocol operations to objects. As of writing, its only well-developed
application is the provisioning of Internet domain names, hosts, and related
contact details.

Net::EPP::Frame::ObjectSpec is a simple module designed to provide easy access to
metadata for the object types defined in the EPP specification.

=head1 USAGE

	my @spec = Net::EPP::Frame::ObjectSpec->spec($type);

This function returns an array containing metadata for the given object type.
If no metadata is registered then the function returns undef.

The array contains three members:

	@spec = (
		$type,
		$xmlns,
		$schemaLocation,
	);

C<$type> is the same as the supplied argument, and the other two members
correspond to the XML attributes used to specify the object in an EPP
C<E<lt>commandE<gt>> or C<E<lt>responseE<gt>> frame.

The objects currently registered are:

=over

=item * C<domain>, for domain names.

=item * C<host>, for DNS server hosts.

=item * C<contact>, for contact objects.

=item * C<secDNS>, for DNSSEC information.

=back

Note that secDNS is an extension to the domain object rather than an
object in its own right.

=head1 AUTHOR

CentralNic Ltd (http://www.centralnic.com/).

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * the L<Net::EPP::Frame> module, for constructing valid EPP frames.

=item * the L<Net::EPP::Client> module, for communicating with EPP servers.

=item * RFCs 4930 and RFC 4934, available from L<http://www.ietf.org/>.

=item * The CentralNic EPP site at L<http://www.centralnic.com/resellers/epp>.

=back

=cut

1;
