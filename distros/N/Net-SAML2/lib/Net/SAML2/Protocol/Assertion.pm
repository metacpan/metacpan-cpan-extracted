package Net::SAML2::Protocol::Assertion;
use Moose;

our $VERSION = '0.88'; # VERSION

use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use DateTime;
use DateTime::HiRes;
use DateTime::Format::XSD;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::XML::Sig;
use XML::Enc;
use XML::LibXML::XPathContext;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::Verify;
use List::Util qw(first);
use URN::OASIS::SAML2 qw(STATUS_SUCCESS);
use Carp qw(croak);
use Net::SAML2::Types qw(XsdID);
use Try::Tiny;

with 'Net::SAML2::Role::ProtocolMessage';
with 'Net::SAML2::Role::VerifyXML';
with 'Net::SAML2::Role::XMLCertificate';

# ABSTRACT: SAML2 assertion object


has 'attributes' => (isa => 'HashRef[ArrayRef]', is => 'ro', required => 1);
has 'audience'   => (isa => NonEmptySimpleStr, is => 'ro', required => 1);
has 'not_after'  => (isa => DateTime,          is => 'ro', required => 1);
has 'not_before' => (isa => DateTime,          is => 'ro', required => 1);
has 'session'         => (isa => 'Str', is => 'ro', required => 1);
has 'in_response_to'  => (isa => 'Str', is => 'ro', required => 1);
has 'response_status' => (isa => 'Str', is => 'ro', required => 1);
has 'response_substatus' => (isa => 'Str', is => 'ro');
has 'cacert'     => (isa => 'Str', is => 'ro', required => 0);
has 'cert_text'  => (isa => 'Str', is => 'ro', required => 0);
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
has 'insecure_trust_embedded_cert' => (
    isa       => 'Bool',
    is        => 'ro',
    default   => 0,
);



# BUILDARGS

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my %params = @_;
    unless ($params{cacert}
         || $params{cert_text}
         || $params{insecure_trust_embedded_cert}) {
        croak(
            "'cacert' or 'cert_text' is required to verify assertion signatures. "
          . "Without a trusted certificate the verifier accepts any "
          . "KeyInfo-embedded certificate. To explicitly disable this check "
          . "(test/dev only), pass insecure_trust_embedded_cert => 1 to "
          . "new_from_xml()."
        );
    }

    return $self->$orig(%params);
};

sub _assert_saml_value {
    my ($self, $xpath, $needle, $haystack, $ctx) = @_;

    my $found = $ctx
        ? $xpath->findvalue($haystack, $ctx)
        : $xpath->findvalue($haystack); # findvalue WILL concat multiple values iirc
    die "assert_saml_value: Unable to get a value for ($haystack)" unless defined $found;
    return $found unless defined $needle;

    if ($needle ne $found) {
      die "assert_saml_value: ($needle) does not match ($found) in ($haystack)";
    }
    return $found;
}

sub _get_actual_destination {
    my ($class, $destination, $xpath) = @_;

    return $class->_assert_saml_value($xpath, $destination,
        '/samlp:Response/@Destination | /samlp:ArtifactResponse/@Destination');
}

sub _get_not_before {
    my ($class, $xpath, $ctx) = @_;

    my $not_before;
    my $value = $ctx
            ? $xpath->findvalue('saml:Conditions/@NotBefore', $ctx)
            : $xpath->findvalue('//samlp:Response/saml:Assertion/saml:Conditions/@NotBefore');
    $value //= $xpath->findvalue('//saml:Conditions/@NotBefore');

    if ($value) {
        $not_before = DateTime::Format::XSD->parse_datetime($value);
    }
    else {
        $not_before = DateTime::HiRes->now();
    }
    return $not_before;
}

sub _get_not_after {
    my ($class, $xpath, $ctx) = @_;

    my $not_after;
    my $value = $ctx
            ? $xpath->findvalue('saml:Conditions/@NotOnOrAfter', $ctx)
            : $xpath->findvalue('//samlp:Response/saml:Assertion/saml:Conditions/@NotOnOrAfter');
    $value //= $xpath->findvalue('//saml:Conditions/@NotOnOrAfter');
    if ($value) {
        $not_after = DateTime::Format::XSD->parse_datetime($value);
    }
    else {
        $not_after = DateTime->from_epoch(epoch => time() + 1000);
    }
    return $not_after;
}

sub _get_nameid {
    my ($class, $xpath, $ctx) = @_;

    my $nameid;
    my $nameid_nodes = $ctx
        ? $xpath->findnodes('saml:Subject/saml:NameID', $ctx)
        : $xpath->findnodes('/samlp:Response/saml:Assertion/saml:Subject/saml:NameID');

    if ($nameid_nodes->size) {
        $nameid = $nameid_nodes->get_node(1);
    }
    elsif (!$ctx) {
        my $global = $xpath->findnodes('//saml:Subject/saml:NameID');
        $nameid = $global->get_node(1) if $global->size;
    }
    return $nameid;
}

sub _get_authnstatement {
    my ($class, $xpath, $ctx) = @_;

    my $authnstatement;
    my $authn_nodes = $ctx
        ? $xpath->findnodes('saml:AuthnStatement', $ctx)
        : $xpath->findnodes('/samlp:Response/saml:Assertion/saml:AuthnStatement');

    if ($authn_nodes->size) {
        $authnstatement = $authn_nodes->get_node(1);
    }
    return $authnstatement;
}

sub _get_actual_issuer {
    my ($class, $issuer, $xpath, $ctx) = @_;

    return $ctx
        ? $class->_assert_saml_value($xpath, $issuer, 'saml:Issuer', $ctx)
        : $class->_assert_saml_value($xpath, $issuer, '//saml:Assertion/saml:Issuer');
}

sub _get_id {
    my $class           = shift;
    my $xpath           = shift;
    my $assertion_node  = shift;

    return $xpath->findvalue('//saml:Assertion/@ID') unless $assertion_node;
    return $assertion_node->getAttribute('ID');
}

sub _get_audience {
    my $class           = shift;
    my $xpath           = shift;
    my $assertion_node  = shift;

    return $xpath->findvalue('//saml:Conditions/saml:AudienceRestriction/saml:Audience') unless $assertion_node;
    return $xpath->findvalue('saml:Conditions/saml:AudienceRestriction/saml:Audience', $assertion_node);
}

sub _get_session {
    my $class           = shift;
    my $xpath           = shift;
    my $assertion_node  = shift;

    return $xpath->findvalue('//saml:AuthnStatement/@SessionIndex') unless $assertion_node;
    return $xpath->findvalue('saml:AuthnStatement/@SessionIndex', $assertion_node);
}

sub _get_in_response_to {
    my $class           = shift;
    my $xpath           = shift;
    my $assertion_node  = shift;

    return $xpath->findvalue(
        '//saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@InResponseTo'
    ) unless $assertion_node;

    return $xpath->findvalue(
        'saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@InResponseTo',
        $assertion_node);
}

sub _get_trusted_assertion {
    my $class           = shift;
    my $xpath           = shift;
    my ($candidate_refs)  = @_;

    my $assertion_node;
    for my $sign_id_ref (@$candidate_refs) {
        next unless (defined $sign_id_ref && XsdID->check($sign_id_ref));
        my $candidates = $xpath->findnodes("//*[\@ID='$sign_id_ref']");
        croak("XSW guard: signed Reference URI '$sign_id_ref' is ambiguous "
            . "(matched " . $candidates->size . " elements)")
            if $candidates->size > 1;
        my $root = $candidates->get_node(1);
        next unless $root;

        my $ln = $root->localname // '';
        my $ns = $root->namespaceURI // '';
        if ($ln eq 'Assertion'
            && $ns eq 'urn:oasis:names:tc:SAML:2.0:assertion') {
            $assertion_node = $root;
            last;
        }
        my $asns = $xpath->findnodes('.//saml:Assertion', $root);
        if ($asns->size) {
            $assertion_node = $asns->get_node(1);
            last;
        }
    }
    return $assertion_node;
}

sub _trusted_signature_refs {
    my ($class, $xpath, $cacert) = @_;

    return unless $cacert;

    my $ca = Crypt::OpenSSL::Verify->new($cacert, { strict_certs => 0 });

    # We are looking for references for trusted Signature nodes here
    # the X509Certificate of each signature is verified against the
    # cacert and a list of trusted references is created
    my @trusted_refs;
    for my $sig ($xpath->findnodes('//dsig:Signature')) {
        my $pem = $class->get_pem_from_keynode($sig);
        my $cert_obj = try { Crypt::OpenSSL::X509->new_from_string($pem) };
        next unless $cert_obj;

        # Crypt::OpenSSL::Verify->verify can both return a bool AND die on
        # parse / chain failure; treat both as untrusted.
        my $ok = try { $ca->verify($cert_obj) };
        next unless $ok;

        my $ref = $xpath->findvalue(
            './dsig:SignedInfo/dsig:Reference/@URI', $sig);
        next unless defined $ref;
        $ref =~ s/^#//;

        next unless XsdID->check($ref);

        my $resolved = $xpath->findnodes("//*[\@ID='$ref']");

        # A CA-trusted signature whose Reference URI resolves to more than
        # one element is an active XSW1 (duplicate-ID) attack - fail closed.
        die("XSW guard: trusted signature Reference URI '$ref' is "
            . "ambiguous (matched " . $resolved->size . " elements)")
            if $resolved->size > 1;

        next unless $resolved->size == 1;
        my $node = $resolved->get_node(1);

        my $genuine = try {
            Net::SAML2::XML::Sig->new({
                cert_text          => $pem,
                no_xml_declaration => 1,
            })->verify($node->toString);
        };
        next unless $genuine;

        push @trusted_refs, $ref;
    }

    return @trusted_refs;
}

sub _verify_encrypted_assertion {
    my $self     = shift;
    my $xml      = shift;
    my $cacert   = shift;
    my $key_file = shift;
    my $key_name = shift;
    my $insecure_trust_embedded_cert = shift;
    my $cert_text = shift;
    my $require_signed_assertion = shift;

    unless ($cacert || $cert_text || $insecure_trust_embedded_cert) {
        croak(
            "'cacert' or 'cert_text' is required to verify assertion signatures. "
          . "Without a trusted certificate the verifier accepts any "
          . "KeyInfo-embedded certificate. To explicitly disable this check "
          . "(test/dev only), pass insecure_trust_embedded_cert => 1 to "
          . "new_from_xml()."
        );
    }

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

    unless ($xpath->exists('dsig:Signature', $assert)) {
        return $xml unless $require_signed_assertion;
        croak(
            "Decrypted assertion has no signature. Set require_signed_assertion => 0 "
          . "to accept unsigned encrypted assertions (not recommended)."
        );
    }

    $self->verify_xml(
        $assert->toString(),
        no_xml_declaration => 1,
        $cert_text ? (cert_text => $cert_text) : (),
        $cacert ? (cacert => $cacert) : (),
    );

    return $xml;
}

sub new_from_xml {
    my($class, %args) = @_;

    my $key_file = $args{key_file};
    my $cacert   = delete $args{cacert};
    my $cert_text = delete $args{cert_text};
    my $issuer   = delete $args{issuer};
    my $destination   = delete $args{destination};
    my $insecure_trust_embedded_cert = delete $args{insecure_trust_embedded_cert} // 0;
    my $require_signed_assertion = delete $args{require_signed_assertion} // 0;

    my $xpath = XML::LibXML::XPathContext->new();
    $xpath->registerNs('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $xpath->registerNs('dsig',  'http://www.w3.org/2000/09/xmldsig#');
    $xpath->registerNs('xenc',  'http://www.w3.org/2001/04/xmlenc#');

    my $xml = no_comments($args{xml});
    $xpath->setContextNode($xml);

    my $actual_destination = $class->_get_actual_destination($destination, $xpath);
    if ($cacert && $xpath->findnodes('//dsig:Signature')->size > 0) {
        my $verifier = Net::SAML2::XML::Sig->new({
            x509               => 1,
            no_xml_declaration => 1,
        });

        my $ok = try {
            $verifier->verify($xml->toString)
        } catch {
            croak(sprintf(
                "XML signature verification failed in new_from_xml%s",
                $_ ? " ($_)" : '',
            ));
        };
        # XML::Sig can croak or return 0 in event that the signature fails
        croak(sprintf(
            "XML signature verification failed in new_from_xml%s",
            $_ ? " ($_)" : '',
        )) unless $ok;
    }

    $xml = $class->_verify_encrypted_assertion(
        $xml,
        $cacert,
        $key_file,
        $args{key_name},
        $insecure_trust_embedded_cert,
        $cert_text,
        $require_signed_assertion,
    );

    my $dec = $class->_decrypt(
        $xml,
        key_file => $key_file,
        key_name => $args{key_name}
    );
    $xpath->setContextNode($dec);

    my @trusted_refs = $class->_trusted_signature_refs($xpath, $cacert);
    my $sig_count = $xpath->findnodes('//dsig:Signature')->size;
    if ($cacert && $sig_count > 0 && !@trusted_refs) {
        croak(
            "No <dsig:Signature> in the document chains to the configured "
          . "cacert. Refusing to extract assertion content."
        );
    }

    my @candidate_refs;
    if (@trusted_refs) {
        @candidate_refs = @trusted_refs;
    }
    else {
        croak("No trusted signature found in the assertion. Pass "
            . "insecure_trust_embedded_cert => 1 to new_from_xml() to trust "
            . "embedded certificates (dev/test only).")
            unless $insecure_trust_embedded_cert;

        my $ids = $xpath->findnodes('//saml:Assertion/@ID');
        if ($ids->size == 1) {
            (my $ref = $ids->get_node(1)->value) =~ s/^#//;
            @candidate_refs = ($ref) if length $ref;
        }
    }

    my $assertion_node = $class->_get_trusted_assertion($xpath, \@candidate_refs);

    if ($cacert && $sig_count > 0 && !$assertion_node) {
        croak(
            "XSW guard: no CA-trusted signature anchors a <saml:Assertion>. "
          . "Refusing to extract assertion content via document order."
        );
    }

    if (defined $destination && $assertion_node) {
        my $recipient = $xpath->findvalue(
            'saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData/@Recipient',
            $assertion_node,
        );
        if (($recipient // '') ne $destination) {
            croak(sprintf(
                "Assertion SubjectConfirmationData/Recipient (%s) does "
              . "not match expected destination (%s)",
                $recipient, $destination,
            ));
        }
    }

    die "Net::SAML2: no Assertion found in response\n"
        unless $assertion_node || $xpath->exists('//saml:Assertion');

    my $attributes = {};
    my @attr_owners = $assertion_node
        ? $xpath->findnodes(
            './saml:AttributeStatement/saml:Attribute/saml:AttributeValue/..',
            $assertion_node)
        : $xpath->findnodes(
            '//saml:Assertion/saml:AttributeStatement/saml:Attribute/saml:AttributeValue/..');
    for my $node (@attr_owners) {
        my @values = $xpath->findnodes("saml:AttributeValue", $node);
        $attributes->{$node->getAttribute('Name')} = [map $_->string_value, @values];
    }

    my $not_before      = $class->_get_not_before($xpath, $assertion_node);
    my $not_after       = $class->_get_not_after($xpath, $assertion_node);
    my $nameid          = $class->_get_nameid($xpath, $assertion_node);
    my $authnstatement  = $class->_get_authnstatement($xpath, $assertion_node);
    my $actual_issuer   = $class->_get_actual_issuer($issuer, $xpath, $assertion_node);

    my $nodeset = $xpath->findnodes('/samlp:Response/samlp:Status/samlp:StatusCode|/samlp:ArtifactResponse/samlp:Status/samlp:StatusCode');

    croak("Unable to parse status from assertion") unless $nodeset->size;

    my $status_node = $nodeset->get_node(1);
    my $status      = $status_node->getAttribute('Value');
    my $substatus;

    if (my $s = first { $_->isa('XML::LibXML::Element') } $status_node->childNodes) {
        $substatus = $s->getAttribute('Value');
    }

    my $self = $class->new(
        id             => $class->_get_id($xpath, $assertion_node),
        issuer         => $actual_issuer,
        destination    => $actual_destination,
        attributes     => $attributes,
        session        => $class->_get_session($xpath, $assertion_node),
        $nameid ? (nameid => $nameid) : (),
        audience       => $class->_get_audience($xpath, $assertion_node),
        not_before     => $not_before,
        not_after      => $not_after,
        xpath          => $xpath,
        in_response_to => $class->_get_in_response_to($xpath, $assertion_node),
        response_status => $status,
        $substatus ? (response_substatus => $substatus) : (),
        $authnstatement ? (authnstatement => $authnstatement) : (),
        $cacert ? (cacert => $cacert) : (),
        $cert_text ? (cert_text => $cert_text) : (),
        $insecure_trust_embedded_cert ? (insecure_trust_embedded_cert => $insecure_trust_embedded_cert) : (),
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
    my ($self, $audience, $in_response_to, $issuer, $destination) = @_;

    return 0 unless defined $audience;
    return 0 unless($audience eq $self->audience);

    return 0 unless !defined $in_response_to
        or $in_response_to eq $self->in_response_to;

    return 0 unless !defined $issuer
        or $issuer eq $self->issuer;

    return 0 unless !defined $destination
        or $destination eq $self->destination;

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
    return no_comments($enc->decrypt($xml, %options));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Protocol::Assertion - SAML2 assertion object

=head1 VERSION

version 0.88

=head1 SYNOPSIS

  my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml         => decode_base64($SAMLResponse),
    cacert      => 'cacert.pem',        # Required to securely validate Assertions
    key_file    => 'private.key',       # Required for Encrypted Assertions
    issuer      => $idp->{entity_id},   # May be required in future version
    destination => 'SP Destination',    # May be required in future version
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

C<cacert> verifies the signature against the certificate embedded in the
document's C<KeyInfo>.  When the IdP references its signing key by
C<KeyName> or C<RetrievalMethod> (no embedded C<X509Certificate>), use
C<cert_text> instead.

=item B<cert_text>

text form of the IdP signing certificate (FORMAT_PEM) used to verify the
assertion signature.  Unlike C<cacert>, this B<pins> a specific
certificate: the signature is verified directly against it. One of
C<cacert>, C<cert_text> or C<insecure_trust_embedded_cert> is required.

=item B<require_signed_assertion>

Boolean.  When true, a decrypted C<EncryptedAssertion> that carries no
signature is rejected rather than accepted.

=item B<issuer>

Specifies the expected Issuer value in the Assertion.  Results in a croak
if defined and the value does not match the value in the Assertion.

It would be the $idp->{entity_id}

While optional it is recommended for ensuring that the Assertion is properly
validated.

B<Notice>: This may become required in a future version.

=item B<destination>

Specifies the expected destination value in the Assertion.  Results in a croak
if defined and the value does not match the value in the Assertion.

It would be the B<Location> field of the assertion_consumer_service for the
Binding that you are receiving the Assertion via (POST).

While optional it is recommended for ensuring that the Assertion is properly
validated.

B<Notice>: This may become required in a future version.

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

=head2 valid( $audience, $in_response_to, $issuer, $destination )

Returns true if this Assertion is currently valid for the given audience.

Also accepts $in_response_to which it checks against the returned
Assertion.  This is very important for security as it helps ensure
that the assertion that was received was for the request that was made.

Checks the audience matches, and that the current time is within the
Assertions validity period as specified in its Conditions element.

Optionally it also checks that the $issuer and $destination matches
the values provided in the Assertion.

Parameters:

=over

=item $audience: Intended Audience for the Assertion

=item $in_response_to: the orginal SAML request ID

It checks against the returned Assertion.  This is very important for security
as it helps ensure that the assertion that was received was for the request
that was made.

=item $issuer: The IdP configured Issuer

Checks to ensure that the Issuer in the Assertion is the expected value.

=item $destination: The SP Destination

Checks to ensure that the Destination in the Response is the expected value.

=back

=head2 success

Returns true if the response status is a success, returns false otherwise.
In case the assertion isn't successfull, the L</response_status> and L</response_substatus> calls can be use to see why the assertion wasn't successful.

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
