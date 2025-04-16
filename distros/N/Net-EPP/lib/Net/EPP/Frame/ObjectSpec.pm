package Net::EPP::Frame::ObjectSpec;
use vars qw($SPEC);
use strict;

our $SPEC = {
    'domain'                   => ['urn:ietf:params:xml:ns:domain-1.0',  'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd'],
    'contact'                  => ['urn:ietf:params:xml:ns:contact-1.0', 'urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd'],
    'host'                     => ['urn:ietf:params:xml:ns:host-1.0',    'urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd'],
    'secDNS'                   => ['urn:ietf:params:xml:ns:secDNS-1.1',  'urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd'],
    'rgp'                      => ['urn:ietf:params:xml:ns:rgp-1.0',     'urn:ietf:params:xml:ns:rgp-1.0 rgp-1.0.xsd'],
    'maintenance'              => ['urn:ietf:params:xml:ns:epp:maintenance-1.0'],
    'secure-authinfo-transfer' => ['urn:ietf:params:xml:ns:epp:secure-authinfo-transfer-1.0'],
    'b-dn'                     => ['urn:ietf:params:xml:ns:epp:b-dn'],
    'unhandled-namespaces'     => ['urn:ietf:params:xml:ns:epp:unhandled-namespaces-1.0'],
    'loginSec'                 => ['urn:ietf:params:xml:ns:epp:loginSec-1.0'],
    'fee'                      => ['urn:ietf:params:xml:ns:epp:fee-1.0'],
    'changePoll'               => ['urn:ietf:params:xml:ns:changePoll-1.0'],
    'orgext'                   => ['urn:ietf:params:xml:ns:epp:orgext-1.0'],
    'org'                      => ['urn:ietf:params:xml:ns:epp:org-1.0'],
    'allocationToken'          => ['urn:ietf:params:xml:ns:allocationToken-1.0'],
    'launch'                   => ['urn:ietf:params:xml:ns:launch-1.0'],
    'keyrelay'                 => ['urn:ietf:params:xml:ns:keyrelay-1.0'],
    'ttl'                      => ['urn:ietf:params:xml:ns:epp:ttl-1.0'],
};

sub spec {
    my ($package, $type) = @_;

    return (!defined($SPEC->{$type}) ? undef : ($type, @{$SPEC->{$type}}));
}

sub xmlns {
    my ($package, $type) = @_;
    return $SPEC->{$type}->[0];
}

=pod

=head1 NAME

Net::EPP::Frame::ObjectSpec - metadata about EPP objects and extensions.

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

C<Net::EPP::Frame::ObjectSpec> is a simple module designed to provide easy access
to metadata for the objects and extensions defined in EPP and various
extensions.

=head1 METHODS

=head2 C<xmlns()>

    my $xmlns = Net::EPP::Frame::ObjectSpec->xmlns($type);

Returns a string containing the XML namespace URI of the thing identified by
C<$type>, or C<undef> if C<$type> is unknown.

See below for possible values of C<$type>.

=head2 C<spec()>

	my @spec = Net::EPP::Frame::ObjectSpec->spec($type);

This function returns an array containing metadata for the given object type.
If no metadata is registered then the function returns C<undef>.

The returned array contains three members:

	@spec = (
		$type,
		$xmlns,
		$schemaLocation, # (deprecated)
	);

C<$type> is the same as the supplied argument, while C<$xmlns> is the XML
namespace URI for the given type. The third argument is suitable for inclusion
in a C<schemaLocation> attribute, but is now deprecated and will be C<undef> for
any value of C<$type> other than C<domain>, C<host> C<contact>, C<secDNS> and
C<rgp>.

=head1 THE C<$type> ARGUMENT

The C<$type> argument to C<xmlns()> and C<spec()> identifies the object or
extension desired. Possible values are:

=head2 OBJECT MAPPINGS

=over

=item * C<domain>, for domain names;

=item * C<host>, for host objects;

=item * C<contact>, for contact objects;

=item * C<org>, for organization object.

=back

=head2 EXTENSIONS

=over

=item * C<secDNS>, for the DNSSEC extension;

=item * C<rgp>, for Registry Grace Period extension;

=item * C<ttl>, for the TTL extension;

=item * C<maintenance>, for the Maintenance extension;

=item * C<secure-authinfo-transfer>, for the Secure authInfo extension;

=item * C<b-dn>, for the bundled domain names extension;

=item * C<unhandled-namespaces>, for the unhandled namespaces extension;

=item * C<loginSec>, for the Login Security extension;

=item * C<fee>, for the Fee extension;

=item * C<changePoll>, for the Change Poll extension;

=item * C<orgext>, for the Organization extension;

=item * C<allocationToken>, for the Allocation Token extension;

=item * C<launch>, for the Launch extension;

=item * C<keyrelay>, for the Key Relay extension;

=item * C<ttl>, for the TTL extension.

=back

=head1 COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1;
