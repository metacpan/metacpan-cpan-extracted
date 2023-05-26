package Net::EPP::Frame::ObjectSpec;
use vars qw($SPEC);
use strict;

our $SPEC = {
	'domain'	=> [ 'urn:ietf:params:xml:ns:domain-1.0',	'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd'	],
	'contact'	=> [ 'urn:ietf:params:xml:ns:contact-1.0',	'urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd'	],
	'host'		=> [ 'urn:ietf:params:xml:ns:host-1.0',		'urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd'		],
	'secDNS'	=> [ 'urn:ietf:params:xml:ns:secDNS-1.1',	'urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd'	],
	'rgp'		=> [ 'urn:ietf:params:xml:ns:rgp-1.1',		'urn:ietf:params:xml:ns:rgp-1.1 rgp-1.1.xsd'	],
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

=item * C<domain>, for domain names;

=item * C<host>, for DNS server hosts;

=item * C<contact>, for contact objects;

=item * C<secDNS>, for DNSSEC information;

=item * C<rgp>, for registry grace periods.

=back

Note that C<secDNS> and C<rgp> refer to extensions to the domain object rather than
objects in their own right.

=cut

1;
