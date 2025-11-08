package Net::SAML2::Protocol::Assertion;
use Moose;

our $VERSION = '0.83'; # VERSION

use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use DateTime;
use DateTime::HiRes;
use DateTime::Format::XSD;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::XML::Sig;
use XML::Enc;
use XML::LibXML::XPathContext;
use List::Util qw(first);
use URN::OASIS::SAML2 qw(STATUS_SUCCESS);
use Carp qw(croak);

with 'Net::SAML2::Role::ProtocolMessage';

# ABSTRACT: SAML2 assertion object


has 'attributes' => (isa => 'HashRef[ArrayRef]', is => 'ro', required => 1);
has 'audience'   => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'not_after'  => (isa => DateTime,          is => 'ro', required => 1);
has 'not_before' => (isa => DateTime,          is => 'ro', required => 1);
has 'session'         => (isa => 'Str', is => 'ro', required => 1);
has 'in_response_to'  => (isa => 'Str', is => 'ro', required => 1);
has 'response_status' => (isa => 'Str', is => 'ro', required => 1);
has 'response_substatus' => (isa => 'Str', is => 'ro');
has 'xpath' => (isa => 'XML::LibXML::XPathContext', is => 'ro', required => 1);
has 'nameid_object' => (
    isa       => 'XML::LibXML::Element',
    is        => 'ro',
    required  => 0,
    init_arg  => 'nameid',
    predicate => 'has_nameid',
);
has 'authnstatement_object' => (
    isa       => 'XML::LibXML::Element',
    is        => 'ro',
    required  => 0,
    init_arg  => 'authnstatement',
    predicate => 'has_authnstatement',
);



sub _verify_encrypted_assertion {
    my $self     = shift;
    my $xml      = shift;
    my $cacert   = shift;
    my $key_file = shift;
    my $key_name = shift;

    my $xpath = XML::LibXML::XPathContext->new($xml);
    $xpath->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $xpath->registerNs('dsig',  'http://www.w3.org/2000/09/xmldsig#');
    $xpath->registerNs('xenc',  'http://www.w3.org/2001/04/xmlenc#');

    return $xml unless $xpath->exists('//saml:EncryptedAssertion');

    croak "Encrypted Assertions require key_file" if !defined $key_file;

    $xml = $self->_decrypt(
        $xml,
        key_file => $key_file,
        key_name => $key_name,
    );
    $xpath->setContextNode($xml);

    my $assert_nodes = $xpath->findnodes('//saml:Assertion');
    return $xml unless $assert_nodes->size;
    my $assert = $assert_nodes->get_node(1);

    return $xml unless $xpath->exists('dsig:Signature', $assert);
    my $xml_opts->{ no_xml_declaration } = 1;
    my $x   = Net::SAML2::XML::Sig->new($xml_opts);
    my $ret = $x->verify($assert->toString());
    die "Decrypted Assertion signature check failed" unless $ret;

    return $xml unless $cacert;
    my $cert = $x->signer_cert;
    die "Certificate not provided in SAML Response, cannot validate" unless $cert;

    my $ca = Crypt::OpenSSL::Verify->new($cacert, { strict_certs => 0 });
    die "Unable to verify signer cert with cacert: " . $cert->subject
        unless $ca->verify($cert);
    return $xml;
}

sub new_from_xml {
    my($class, %args) = @_;

    my $key_file = $args{key_file};
    my $cacert   = delete $args{cacert};

    my $xpath = XML::LibXML::XPathContext->new();
    $xpath->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $xpath->registerNs('dsig',  'http://www.w3.org/2000/09/xmldsig#');
    $xpath->registerNs('xenc',  'http://www.w3.org/2001/04/xmlenc#');

    my $xml = no_comments($args{xml});
    $xpath->setContextNode($xml);

    $xml = $class->_verify_encrypted_assertion(
        $xml,
        $cacert,
        $key_file,
        $args{key_name},
    );

    my $dec = $class->_decrypt(
        $xml,
        key_file => $key_file,
        key_name => $args{key_name}
    );
    $xpath->setContextNode($dec);

    my $attributes = {};
    for my $node ($xpath->findnodes('//saml:Assertion/saml:AttributeStatement/saml:Attribute/saml:AttributeValue/..'))
    {
        my @values = $xpath->findnodes("saml:AttributeValue", $node);
        $attributes->{$node->getAttribute('Name')} = [map $_->string_value, @values];
    }

    my $xpath_base = '//samlp:Response/saml:Assertion/saml:Conditions/';

    my $not_before;
    if (my $value = $xpath->findvalue($xpath_base . '@NotBefore')) {
        $not_before = DateTime::Format::XSD->parse_datetime($value);
    }
    elsif (my $global = $xpath->findvalue('//saml:Conditions/@NotBefore')) {
        $not_before = DateTime::Format::XSD->parse_datetime($global);
    }
    else {
        $not_before = DateTime::HiRes->now();
    }

    my $not_after;
    if (my $value = $xpath->findvalue($xpath_base . '@NotOnOrAfter')) {
        $not_after = DateTime::Format::XSD->parse_datetime($value);
    }
    elsif (my $global = $xpath->findvalue('//saml:Conditions/@NotOnOrAfter')) {
        $not_after = DateTime::Format::XSD->parse_datetime($global);
    }
    else {
        $not_after = DateTime->from_epoch(epoch => time() + 1000);
    }

    my $nameid;
    if (my $node = $xpath->findnodes('/samlp:Response/saml:Assertion/saml:Subject/saml:NameID')) {
        $nameid = $node->get_node(1);
    }
    elsif (my $global = $xpath->findnodes('//saml:Subject/saml:NameID')) {
        $nameid = $global->get_node(1);
    }

    my $authnstatement;
    if (my $node = $xpath->findnodes('/samlp:Response/saml:Assertion/saml:AuthnStatement')) {
        $authnstatement = $node->get_node(1);
    }

    my $nodeset = $xpath->findnodes('/samlp:Response/samlp:Status/samlp:StatusCode|/samlp:ArtifactResponse/samlp:Status/samlp:StatusCode');

    croak("Unable to parse status from assertion") unless $nodeset->size;

    my $status_node = $nodeset->get_node(1);
    my $status = $status_node->getAttribute('Value');
    my $substatus;

    if (my $s = first { $_->isa('XML::LibXML::Element') } $status_node->childNodes) {
        $substatus = $s->getAttribute('Value');
    }

    my $self = $class->new(
        id             => $xpath->findvalue('//saml:Assertion/@ID'),
        issuer         => $xpath->findvalue('//saml:Assertion/saml:Issuer'),
        destination    => $xpath->findvalue('/samlp:Response/@Destination'),
        attributes     => $attributes,
        session        => $xpath->findvalue('//saml:AuthnStatement/@SessionIndex'),
        $nameid ? (nameid => $nameid) : (),
        audience       => $xpath->findvalue('//saml:Conditions/saml:AudienceRestriction/saml:Audience'),
        not_before     => $not_before,
        not_after      => $not_after,
        xpath          => $xpath,
        in_response_to => $xpath->findvalue('//saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@InResponseTo'),
        response_status => $status,
        $substatus ? (response_substatus => $substatus) : (),
        $authnstatement ? (authnstatement => $authnstatement) : (),
    );

    return $self;
}



sub name {
    my $self = shift;
    return $self->attributes->{CN}[0];
}


sub nameid {
    my $self = shift;
    return unless $self->has_nameid;
    return $self->nameid_object->textContent;
}


sub nameid_format {
    my $self = shift;
    return unless $self->has_nameid;
    return $self->nameid_object->getAttribute('Format');
}


sub nameid_name_qualifier {
    my $self = shift;
    return unless $self->has_nameid;
    return $self->nameid_object->getAttribute('NameQualifier');
}


sub nameid_sp_name_qualifier {
    my $self = shift;
    return unless $self->has_nameid;
    return $self->nameid_object->getAttribute('SPNameQualifier');
}


sub nameid_sp_provided_id {
    my $self = shift;
    return unless $self->has_nameid;
    return $self->nameid_object->getAttribute('SPProvidedID');
}


sub authnstatement {
    my $self = shift;
    return unless $self->has_authnstatement;
    return $self->authnstatement_object->textContent;
}


sub authnstatement_authninstant {
    my $self = shift;
    return unless $self->has_authnstatement;
    return $self->authnstatement_object->getAttribute('AuthnInstant');
}


sub authnstatement_sessionindex {
    my $self = shift;
    return unless $self->has_authnstatement;
    return $self->authnstatement_object->getAttribute('SessionIndex');
}


sub authnstatement_subjectlocality {
    my $self = shift;
    return unless $self->has_authnstatement;

    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    my $subjectlocality;
    my $xpath_base = '//saml:AuthnStatement/saml:SubjectLocality';
    if (my $nodes = $xpc->find($xpath_base, $self->authnstatement_object)) {
        my $node = $nodes->get_node(1);
        $subjectlocality = $node;
    }
    return $subjectlocality;
}


sub subjectlocality_address {
    my $self = shift;
    return unless $self->has_authnstatement;
    my $subjectlocality = $self->authnstatement_subjectlocality;
    return unless $subjectlocality;
    return $subjectlocality->getAttribute('Address');
}


sub subjectlocality_dnsname {
    my $self = shift;
    return unless $self->has_authnstatement;
    my $subjectlocality = $self->authnstatement_subjectlocality;
    return unless $subjectlocality;
    return $subjectlocality->getAttribute('DNSName');
}


sub authnstatement_authncontext {
    my $self = shift;
    return unless $self->has_authnstatement;

    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    my $authncontext;
    my $xpath_base = '//saml:AuthnStatement/saml:AuthnContext';
    if (my $nodes = $xpc->find($xpath_base, $self->authnstatement_object)) {
        my $node = $nodes->get_node(1);
        $authncontext = $node;
    }
    return $authncontext;
}


sub contextclass_authncontextclassref {
    my $self = shift;
    return unless $self->has_authnstatement;
    my $authncontextclassref = $self->authnstatement_authncontext;
    return unless $authncontextclassref;
    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    if (my $value = $xpc->findvalue('//saml:AuthnContextClassRef', $self->authnstatement_object)) {
        $authncontextclassref = $value;
    }
    return $authncontextclassref;
}


sub valid {
    my ($self, $audience, $in_response_to) = @_;

    return 0 unless defined $audience;
    return 0 unless($audience eq $self->audience);

    return 0 unless !defined $in_response_to
        or $in_response_to eq $self->in_response_to;

    my $now = DateTime::HiRes->now;

    # not_before is "NotBefore" element - exact match is ok
    # not_after is "NotOnOrAfter" element - exact match is *not* ok
    return 0 unless DateTime::->compare($now,             $self->not_before) > -1;
    return 0 unless DateTime::->compare($self->not_after, $now) > 0;

    return 1;
}


sub success {
    my $self = shift;
    return 1 if $self->response_status eq STATUS_SUCCESS;
    return 0;
}

sub _decrypt {
    my $self    = shift;
    my $xml     = shift;
    my %options = @_;

    return $xml unless $options{key_file};

    my $enc = XML::Enc->new(
        {
            no_xml_declaration => 1,
            key                => $options{key_file},
        }
    );
    return XML::LibXML->load_xml(string => $enc->decrypt($xml, %options));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::Assertion - SAML2 assertion object

=head1 VERSION

version 0.83

=head1 SYNOPSIS

  my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml => decode_base64($SAMLResponse)
  );

=head1 METHODS

=head2 new_from_xml( ... )

Constructor. Creates an instance of the Assertion object, parsing the
given XML to find the attributes, session and nameid.

Arguments:

=over

=item B<xml>

XML data

=item B<key_file>

Optional but Required handling Encrypted Assertions.

path to the SP's private key file that matches the SP's public certificate
used by the IdP to Encrypt the response (or parts of the response)

=item B<cacert>

path to the CA certificate for verification.  Optional: This is only used for
validating the certificate provided for a signed Assertion that was found
when the EncryptedAssertion is decrypted.

While optional it is recommended for ensuring that the Assertion in an
EncryptedAssertion is properly validated.

=back

=head2 response_status

Returns the response status

=head2 response_substatus

SAML errors are usually "nested" ("Responder -> RequestDenied" for instance,
means that the responder in this transaction (the IdP) denied the login
request). For proper error message generation, both levels are needed.

=head2 name

Returns the CN attribute, if provided.

=head2 nameid

Returns the NameID

=head2 nameid_format

Returns the NameID Format

=head2 nameid_name_qualifier

Returns the NameID NameQualifier

=head2 nameid_sp_name_qualifier

Returns the NameID SPNameQualifier

=head2 nameid_sp_provided_id

Returns the NameID SPProvidedID

=head2 authnstatement

Returns the AuthnStatement

=head2 authnstatement_authninstant

Returns the AuthnStatement AuthnInstant

=head2 authnstatement_sessionindex

Returns the AuthnStatement SessionIndex

=head2 authnstatement_subjectlocality

Returns the AuthnStatement SubjectLocality

=head2 subjectlocality_address

Returns the SubjectLocality Address

=head2 subjectlocality_dnsname

Returns the SubjectLocality DNSName

=head2 authnstatement_authncontext

Returns the AuthnContext for the AuthnStatement

=head2 contextclass_authncontextclassref

Returns the ContextClass AuthnContextClassRef

=head2 valid( $audience, $in_response_to )

Returns true if this Assertion is currently valid for the given audience.

Also accepts $in_response_to which it checks against the returned
Assertion.  This is very important for security as it helps ensure
that the assertion that was received was for the request that was made.

Checks the audience matches, and that the current time is within the
Assertions validity period as specified in its Conditions element.

=head2 success

Returns true if the response status is a success, returns false otherwise.
In case the assertion isn't successfull, the L</response_status> and L</response_substatus> calls can be use to see why the assertion wasn't successful.

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
