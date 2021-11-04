package Net::SAML2::XML::Sig;

use strict;
use warnings;

# ABSTRACT: Net::SAML2::XML::Sig - A toolkit to help sign and verify XML Digital Signatures


# use 'our' on v5.6.0
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

$DEBUG = 0;
# Based on XML::Sig VERSION = '0.47';
our $VERSION = '0.44';

use base qw(Class::Accessor);
Net::SAML2::XML::Sig->mk_accessors(qw(key));

# We are exporting functions
use base qw/Exporter/;

# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( sign verify );


use Digest::SHA qw(sha1 sha224 sha256 sha384 sha512);
use XML::LibXML;
use Net::SAML2::XML::Util qw/ no_comments /;
use MIME::Base64;
use Carp;


use constant TRANSFORM_ENV_SIG           => 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
use constant TRANSFORM_C14N              => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
use constant TRANSFORM_C14N_COMMENTS     => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments';
use constant TRANSFORM_C14N_V1_1         => 'http://www.w3.org/TR/2008/REC-xml-c14n11-20080502';
use constant TRANSFORM_C14N_V1_1_COMMENTS => 'http://www.w3.org/TR/2008/REC-xml-c14n11-20080502#WithComments';
use constant TRANSFORM_EXC_C14N          => 'http://www.w3.org/2001/10/xml-exc-c14n#';
use constant TRANSFORM_EXC_C14N_COMMENTS => 'http://www.w3.org/2001/10/xml-exc-c14n#WithComments';

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;  # autoflush




sub new {
    my $class = shift;
    my $params = shift;
    my $self = {};
    foreach my $prop ( qw/ key cert cert_text / ) {
        if ( exists $params->{ $prop } ) {
            $self->{ $prop } = $params->{ $prop };
        }
#        else {
#            confess "You need to provide the $prop parameter!";
#        }
    }
    bless $self, $class;
    $self->{ 'x509' } = exists $params->{ x509 } ? 1 : 0;
    if ( exists $params->{ 'key' } ) {
        $self->_load_key( $params->{ 'key' } );
    }
    if ( exists $params->{ 'cert' } ) {
        $self->_load_cert_file( $params->{ 'cert' } );
    }
    if ( exists $params->{ 'cert_text' } ) {
        $self->_load_cert_text( $params->{ 'cert_text' } );
    }

    if ( exists $params->{ sig_hash } && grep { $_ eq $params->{ sig_hash } } ('sha224', 'sha256', 'sha384', 'sha512'))
    {
        $self->{ sig_hash } = $params->{ sig_hash };
    }
    else {
        $self->{ sig_hash } = 'sha1';
    }

    if ( exists $params->{ digest_hash } && grep { $_ eq $params->{ digest_hash } } ('sha1', 'sha224', 'sha256', 'sha384',, 'sha512'))
    {
        $self->{ digest_hash } = $params->{ digest_hash };
    }
    else {
        $self->{ digest_hash } = 'sha1';
    }

    if (defined $self->{ key_type } && $self->{ key_type } eq 'dsa') {
        if ( defined $params->{ sig_hash } && grep { $_ eq $params->{ sig_hash } } ('sha1', 'sha256')) {
            $self->{ sig_hash } = $params->{ sig_hash };
        }
        else {
            $self->{ sig_hash } = 'sha1';
        }
    }

    if ( exists $params->{ no_xml_declaration } && $params->{ no_xml_declaration } == 1 ) {
        $self->{ no_xml_declaration } = 1;
    } else {
        $self->{ no_xml_declaration } = 0;
    }

    return $self;
}


sub sign {
    my $self = shift;
    my ($xml) = @_;

    die "You cannot sign XML without a private key." unless $self->key;

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };

    my $dom = no_comments($xml);
    #my $dom = XML::LibXML->load_xml(
    #                string => $xml,
    #                no_network => 1,
    #                load_ext_dtd => 0,
    #                expand_entities => 0 );

    $self->{ parser } = XML::LibXML::XPathContext->new($dom);
    $self->{ parser }->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
    $self->{ parser }->registerNs('ec', 'http://www.w3.org/2001/10/xml-exc-c14n#');
    $self->{ parser }->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');

    print ("Signing XML\n") if $DEBUG;

    my @ids_to_sign = $self->_get_ids_to_sign();

    foreach (@ids_to_sign) {
        my $signid = $_;
        # Temporarily create the Signature XML from the part
        # TODO: ths section needs a rewrite to create the xml in
        # a better way.

        # Create a Reference xml fragment including digest section
        my $digest_xml    = $self->_reference_xml( $signid, "REPLACE DIGEST " . $signid );

        # Create a SignedInfo xml fragment including digest section
        my $signed_info   = $self->_signedinfo_xml( $digest_xml );

        # Create a Signature xml fragment including SignedInfo section
        my $signature_xml = $self->_signature_xml( $signed_info, 'REPLACE SIGNATURE ' . $signid );

        print ("Sign ID: $signid\n") if $DEBUG;

        # Get the XML note to sign base on the ID
        my $xml = $self->_get_xml_to_sign($signid);

        # Set the namespace but do not apply it to the XML
        $xml->setNamespace("http://www.w3.org/2000/09/xmldsig#", "dsig", 0);

        # Canonicalize the XML to http://www.w3.org/2001/10/xml-exc-c14n#
        # TODO Change the Canonicalization method in the xml fragment from _signedinfo_xml
        #    <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
        #    <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        my $xml_canon        = $xml->toStringEC14N();

        if(my $ref = Digest::SHA->can($self->{ digest_hash })) {
            $self->{digest_method} = $ref;
        }
        else {
            die("Can't handle $self->{ digest_hash }");
        }

        # Calculate the digest of the XML being signed
        my $bin_digest    = $self->{digest_method}->( $xml_canon );
        my $digest        = encode_base64( $bin_digest, '' );
        print ("   Digest: $digest\n") if $DEBUG;

        # Display the ID of the XML being signed for debugging
        my $reference = $signid; #$self->{parser}->findvalue('//@ID', $xml);
        print ("   Reference URI: $reference\n") if $DEBUG;

        # Add the Signature to the xml being signed
        $xml->appendWellBalancedChunk($signature_xml, 'UTF-8');

        # Canonicalize the SignedInfo to http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments
        # TODO Change the Canonicalization method in the xml fragment from _signedinfo_xml

        my ($signature_node) = $xml->findnodes(
            './dsig:Signature', $xml);
        my ($signed_info_node) = $xml->findnodes(
            './dsig:Signature/dsig:SignedInfo',$xml);

        # Add the digest value to the Signed info
        my ($digest_value_node) = $xml->findnodes(
            './dsig:Signature/dsig:SignedInfo/dsig:Reference/dsig:DigestValue', $signature_node);
        $digest_value_node->removeChildNodes();
        $digest_value_node->appendText($digest);

        # At this point the SignedInfo includes the information
        # to allow us to use the _canonicalize_xml with the $signature_node
        my $signed_info_canon = $self->_canonicalize_xml($signed_info_node, $signature_node);

        # Calculate the signature of the Canonical Form of SignedInfo
        my $signature;
        if ($self->{key_type} eq 'dsa') {
            print ("    Signing SignedInfo using DSA key type\n") if $DEBUG;
            if(my $ref = Digest::SHA->can($self->{ sig_hash })) {
                $self->{sig_method} = $ref;
            }
            else {
                die("Can't handle $self->{ sig_hash }");
            }

            # DSA 1024-bit only permits the signing of 20 bytes or less, hence the sha1
            # DSA 2048-bit only permits the signing sha256
            my $bin_signature = $self->{key_obj}->do_sign( $self->{ sig_method }($signed_info_canon) );

            # https://www.w3.org/TR/2002/REC-xmldsig-core-20020212/#sec-SignatureAlg
            # The output of the DSA algorithm consists of a pair of integers
            # The signature value consists of the base64 encoding of the
            # concatenation of r and s in that order ($r . $s)
            my $r = $bin_signature->get_r;
            my $s = $bin_signature->get_s;

            my $sig_size = ($self->{key_obj}->get_sig_size - 8) * 8;
            my $rs = _zero_fill_buffer($sig_size);
            _concat_dsa_sig_r_s(\$rs, $r, $s, $sig_size);

            $signature        = encode_base64( $rs, "\n" );
        } elsif ($self->{key_type} eq 'ecdsa') {
            print ("    Signing SignedInfo using ECDSA key type\n") if $DEBUG;

            my $bin_signature = $self->{key_obj}->sign_message_rfc7518(
                $signed_info_canon, uc($self->{sig_hash})
            );
            # The output of the ECDSA algorithm consists of a pair of integers
            # The signature value consists of the base64 encoding of the
            # concatenation of r and s in that order ($r . $s).  In this
            # case sign_message_rfc7518 produces that

            $signature        = encode_base64( $bin_signature, "\n" );
        } else {
            print ("    Signing SignedInfo using RSA key type\n") if $DEBUG;
            my $sig_hash = 'use_' . $self->{ sig_hash } . '_hash';
            $self->{key_obj}->$sig_hash;
            my $bin_signature = $self->{key_obj}->sign( $signed_info_canon );
            $signature        = encode_base64( $bin_signature, "\n" );
        }

        # Add the Signature to the SignatureValue
        my ($signature_value_node) = $xml->findnodes(
            './dsig:Signature/dsig:SignatureValue', $signature_node);
        $signature_value_node->removeChildNodes();
        $signature_value_node->appendText($signature);

        print ("\n\n\n SignatureValue:\n" . $signature_value_node . "\n\n\n") if $DEBUG;
    }

    return $dom->toString;
}


sub verify {
    my $self = shift;
    delete $self->{signer_cert};
    my ($xml) = @_;

    my $dom = no_comments($xml);
    #my $dom = XML::LibXML->load_xml(
    #                string => $xml,
    #                no_network => 1,
    #                load_ext_dtd => 0,
    #                expand_entities => 0 );

    $self->{ parser } = XML::LibXML::XPathContext->new($dom);
    $self->{ parser }->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
    $self->{ parser }->registerNs('ec', 'http://www.w3.org/2001/10/xml-exc-c14n#');
    $self->{ parser }->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');
    $self->{ parser }->registerNs('ecdsa', 'http://www.w3.org/2001/04/xmldsig-more#');

    my $signature_nodeset = $self->{ parser }->findnodes('//dsig:Signature');

    my $numsigs = $signature_nodeset->size();
    print ("NodeSet Size: $numsigs\n") if $DEBUG;

    # Loop through each Signature in the document checking each
    my $i;
    while (my $signature_node = $signature_nodeset->shift()) {
        $i++;
        print ("\nSignature $i\n") if $DEBUG;

        # Get SignedInfo Reference ID
        my $reference = $self->{ parser }->findvalue(
            'dsig:SignedInfo/dsig:Reference/@URI', $signature_node);
        $reference =~ s/#//g;

        print ("   Reference URI: $reference\n") if $DEBUG;

        # The reference ID must point to something in the document
        # if not disregard it and look for another signature
        # TODO check to ensure that if there is only a single reference
        # like this it won't accidentally validate
        if (! $self->{ parser }->findvalue('//*[@ID=\''. $reference . '\']')) {
            print ("   Signature reference $reference is not signing anything in this xml\n") if $DEBUG;
            if ($numsigs <= 1) {
                return 0;
            }
            else {
                next;
            }
        }

        # Get SignedInfo DigestMethod Algorithim
        my $digest_method = $self->{ parser }->findvalue(
                'dsig:SignedInfo/dsig:Reference/dsig:DigestMethod/@Algorithm', $signature_node);
        $digest_method =~ s/^.*[#]//;
        print ("   Digest Method: $digest_method\n") if $DEBUG;

        # Get the DigestValue used to verify Canonical XML
        # Note that the digest may have embedded newlines in the XML
        # Decode the base64 and encode it with no newlines
        my $refdigest = encode_base64(decode_base64(_trim($self->{ parser }->findvalue(
                'dsig:SignedInfo/dsig:Reference/dsig:DigestValue', $signature_node))), "");
        print ("   Digest Value: $refdigest\n") if $DEBUG;

        # Get the SignatureValue used to verify the SignedInfo
        my $signature = _trim($self->{ parser }->findvalue('dsig:SignatureValue', $signature_node));
        print ("   Signature: $signature\n") if $DEBUG;

        # Get SignatureMethod Algorithim
        my $signature_method = $self->{ parser }->findvalue(
                'dsig:SignedInfo/dsig:SignatureMethod/@Algorithm', $signature_node);
        $signature_method =~ s/^.*[#]//;
        $signature_method =~ s/^rsa-//;
        $signature_method =~ s/^dsa-//;
        $signature_method =~ s/^ecdsa-//;

        $self->{ sig_hash } = $signature_method;
        print ("   SignatureMethod: $signature_method\n") if $DEBUG;

        # Get the SignedInfo and obtain its Canonical form
        my ($signed_info) = $self->{ parser }->findnodes('dsig:SignedInfo', $signature_node);
        my $signed_info_canon = $self->_canonicalize_xml($signed_info, $signature_node);

        print "$signed_info_canon\n" if $DEBUG;

        if(my $ref = Digest::SHA->can($signature_method)) {
            $self->{sig_method} = $ref;
        }
        else {
            die("Can't handle $signature_method");
        }

        if(my $ref = Digest::SHA->can($digest_method)) {
            $self->{digest_method} = $ref;
        }
        else {
            die("Can't handle $digest_method");
        }

        # If a cert was provided to Net::SAML2::XML::Sig->new() use it to
        # verify the SignedInfo signature
        if (defined $self->{cert_obj}) {
            # use the provided cert to verify
            unless ($self->_verify_x509_cert($self->{cert_obj},$signed_info_canon,$signature)) {
                print STDERR "not verified by x509\n";
                return 0;
            }
        }
        # Extract the XML provided certificate and use it to
        # verify the SignedInfo signature
        else {
            # extract the certficate or key from the document
            my %verify_dispatch = (
                'X509Data' => '_verify_x509',
                'RSAKeyValue' => '_verify_rsa',
                'DSAKeyValue' => '_verify_dsa',
                'ECDSAKeyValue' => '_verify_ecdsa',
            );
            my $keyinfo_nodeset;
            foreach my $key_info_sig_type ( qw/X509Data RSAKeyValue DSAKeyValue ECDSAKeyValue/ ) {
                if ( $key_info_sig_type eq 'X509Data' ) {
                    $keyinfo_nodeset = $self->{ parser }->find(
                            "dsig:KeyInfo/dsig:$key_info_sig_type", $signature_node);
                    #print ("   keyinfo_nodeset X509Data: $keyinfo_nodeset\n") if $DEBUG;
                } else {
                    $keyinfo_nodeset = $self->{ parser }->find(
                            "dsig:KeyInfo/dsig:KeyValue/dsig:$key_info_sig_type", $signature_node);
                    #print ("   keyinfo_nodeset [DR]SAKeyValue: $keyinfo_nodeset\n") if $DEBUG;
                }
                if ( $keyinfo_nodeset->size ) {
                    my $verify_method = $verify_dispatch{$key_info_sig_type};
                    print ("   Verify Method: $verify_method\n") if $DEBUG;
                    if ( ! $self->$verify_method($keyinfo_nodeset->get_node(0),
                            $signed_info_canon, $signature) ) {
                        print ("keyinfo_nodeset->get_node: " . $keyinfo_nodeset->get_node(0) . "\n") if $DEBUG;
                        print STDERR "Failed to verify using $verify_method\n";
                        return 0;
                    } else {
                        print ("Success Verifying\n") if $DEBUG;
                    }
                    last;
                }
            }
            die "Unrecognized key type or no KeyInfo in document" unless (
                $keyinfo_nodeset && $keyinfo_nodeset->size > 0);
        }

        # Signature of SignedInfo was verified above now obtain the
        # Canonical form of the XML and verify the DigestValue of the XML

        # Remove the Signature from the signed XML
        my $signed_xml = $self->_get_signed_xml( $signature_node );
        $signed_xml->removeChild( $signature_node );

        # Obtain the Canonical form of the XML
        my $canonical = $self->_transform($signed_xml, $signature_node);

        # Add the $signature_node back to the $signed_xml to allow other
        # signatures to be validated if they exist
        $signed_xml->addChild( $signature_node );

        # Obtain the DigestValue of the Canonical XML
        my $digest = $self->{digest_method}->($canonical);

        print ( "    Reference Digest:  " . _trim($refdigest) ."\n") if $DEBUG;

        print ( "    Calculated Digest: ". _trim(encode_base64($digest, '')) ."\n") if $DEBUG;

        # Return 0 - fail verification on the first XML signature that fails
        return 0 unless ($refdigest eq _trim(encode_base64($digest, '')));

        print ( "Signature $i Valid\n") if $DEBUG;
        }

    return 1;
}


sub signer_cert {
    my $self = shift;
    return $self->{signer_cert};
}

##
## _get_ids_to_sign()
##
## Arguments:
##
## Returns: array Value of ID attributes from XML
##
## Finds all the values of the ID attributes in the XML
## and return them in reverse order found.  Reverse order
## assumes that the Signatures should be performed on lower
## Nodes first.
##
sub _get_ids_to_sign {
    my $self = shift;
    my @id = $self->{parser}->findnodes('//@ID');
    my @ids;
    foreach (@id) {
        my $i = $_;
        $_ =~ m/^.*\"(.*)\".*$/;
        $i = $1;
        #//*[@ID='identifier_1']
        die "You cannot sign an XML document without identifying the element to sign with an ID attribute" unless $i;
        unshift @ids, $i;
    }
    return @ids;


}

##
## _get_xml_to_sign()
##
## Arguments:
##    $id:     string ID of the Node for the XML to retrieve
##
## Returns: XML NodeSet to sign
##
## Find the XML node with the ID = $id and return the
## XML NodeSet
##
sub _get_xml_to_sign {
    my $self = shift;
    my $id = shift;
    die "You cannot sign an XML document without identifying the element to sign with an ID attribute" unless $id;

    my $xpath = "//*[\@ID='$id']";
    my ($node) = $self->_get_node( $xpath );
    return $node;
}

##
## _get_signed_xml($context)
##
## Arguments:
##    $context:     string XML NodeSet used as context
##
## Returns: XML NodeSet for with ID equal to the URI
##
## Find the XML node with the ID = $URI and return the
## XML NodeSet
##
sub _get_signed_xml {
    my $self = shift;
    my ($context) = @_;

    my $id = $self->{parser}->findvalue('./dsig:SignedInfo/dsig:Reference/@URI', $context);
    $id =~ s/^#//;
    print ("    Signed XML id: $id\n") if $DEBUG;

    $self->{'sign_id'} = $id;
    my $xpath = "//*[\@ID='$id']";
    return $self->_get_node( $xpath, $context );
}

##
## _transform($xml, $context)
##
## Arguments:
##    $xml:     string XML NodeSet
##    $context: string XML Context
##
## Returns: string  Transformed XML
##
## Canonicalizes/Transforms xml based on the Transforms
## from the SignedInfo.
##
sub _transform {
    my $self = shift;
    my ($xml, $context) = @_;

    $context->setNamespace( 'http://www.w3.org/2000/09/xmldsig#', 'dsig' );
    my $transforms = $self->{parser}->find(
        'dsig:SignedInfo/dsig:Reference/dsig:Transforms/dsig:Transform',
        $context
    );

    print "_transform\n" if $DEBUG;
    foreach my $node ($transforms->get_nodelist) {
        my $alg = $node->getAttribute('Algorithm');

        print "    Algorithm: $alg\n" if $DEBUG;
        if ($alg eq TRANSFORM_ENV_SIG) {
            # TODO the xml being passed here currently has the
            # Signature removed.  May be better to do it all here
            next;
        }
        elsif ($alg eq TRANSFORM_C14N) {
            print "        toStringC14N" if $DEBUG;
            $xml = $xml->toStringC14N();
        }
        elsif ($alg eq TRANSFORM_C14N_COMMENTS) {
            print "        toStringC14N(1)" if $DEBUG;
            $xml = $xml->toStringC14N(1);
        }
        elsif ($alg eq TRANSFORM_EXC_C14N) {
            my @prefixlist = $self->_find_prefixlist($node);
            print "        toStringEC14N(0, '', @prefixlist)\n" if $DEBUG;
            $xml = $xml->toStringEC14N(0, '', \@prefixlist);
        }
        elsif ($alg eq TRANSFORM_EXC_C14N_COMMENTS) {
            my @prefixlist = $self->_find_prefixlist($node);
            print "        toStringEC14N(1, '', @prefixlist)\n" if $DEBUG;
            $xml = $xml->toStringEC14N(1, '', \@prefixlist);
        }
        else {
            die "Unsupported transform: $alg";
        }
    }
    return $xml;
}

##
## _find_prefixlist($node)
##
## Arguments:
##    $node:    string XML NodeSet
##
## Returns: ARRAY of prefix lists
##
## Generate an array of prefix lists defined in InclusiveNamespaces
##
sub _find_prefixlist {
    my $self = shift;
    my ($node) = @_;
    my @children = $node->getChildrenByLocalName('InclusiveNamespaces');

    my $prefixlist = '';
    foreach my $child (@children) {
        if ($child) {
            $prefixlist .= $child->getAttribute('PrefixList');
        }
        $prefixlist .= ' ';
    }
    return split / /, $prefixlist;
}

##
## _verify_rsa($context,$canonical,$sig)
##
## Arguments:
##    $context:     string XML Context to use
##    $canonical:   string Canonical XML to verify
##    $sig:         string Base64 encode of RSA Signature
##
## Returns: integer (1 True, 0 False) if signature is valid
##
## Verify the RSA signature of Canonical XML
##
sub _verify_rsa {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    # Generate Public Key from XML
    my $mod = _trim($self->{parser}->findvalue('dsig:Modulus', $context));
    my $modBin = decode_base64( $mod );
    my $exp = _trim($self->{parser}->findvalue('dsig:Exponent', $context));
    my $expBin = decode_base64( $exp );
    my $n = Crypt::OpenSSL::Bignum->new_from_bin($modBin);
    my $e = Crypt::OpenSSL::Bignum->new_from_bin($expBin);
    my $rsa_pub = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e );

    # Decode signature and verify
    my $sig_hash = 'use_' . $self->{ sig_hash } . '_hash';
    $rsa_pub->$sig_hash;
    my $bin_signature = decode_base64($sig);
    return 1 if ($rsa_pub->verify( $canonical,  $bin_signature ));
    return 0;
}

##
## _clean_x509($cert)
##
## Arguments:
##    $cert:     string Certificate in base64 from XML
##
## Returns: string  Certificate in Valid PEM format
##
## Reformats Certifcate string into PEM format 64 characters
## with proper header and footer
##
sub _clean_x509 {
    my $self = shift;
    my ($cert) = @_;

    $cert = $cert->value() if(ref $cert);
    chomp($cert);

    # rewrap the base64 data from the certificate; it may not be
    # wrapped at 64 characters as PEM requires
    $cert =~ s/\n//g;

    my @lines;
    while (length $cert > 64) {
            push @lines, substr $cert, 0, 64, '';
        }
    push @lines, $cert;

    $cert = join "\n", @lines;

    $cert = "-----BEGIN CERTIFICATE-----\n" . $cert . "\n-----END CERTIFICATE-----\n";
    return $cert;
}

##
## _verify_x509($context,$canonical,$sig)
##
## Arguments:
##    $context:     string XML Context to use
##    $canonical:   string Canonical XML to verify
##    $sig:         string Base64 encode of RSA Signature
##
## Returns: integer (1 True, 0 False) if signature is valid
##
## Verify the RSA signature of Canonical XML using an X509
##
sub _verify_x509 {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    eval {
        require Crypt::OpenSSL::X509;
    };
    confess "Crypt::OpenSSL::X509 needs to be installed so that we can handle X509 certificates" if $@;

    # Generate Public Key from XML
    my $certificate = _trim($self->{parser}->findvalue('dsig:X509Certificate', $context));

    # This is added because the X509 parser requires it for self-identification
    $certificate = $self->_clean_x509($certificate);

    my $cert = Crypt::OpenSSL::X509->new_from_string($certificate);

    return $self->_verify_x509_cert($cert, $canonical, $sig);
}

##
## _verify_x509_cert($cert,$canonical,$sig)
##
## Arguments:
##    $cert:        string X509 Certificate
##    $canonical:   string Canonical XML to verify
##    $sig:         string Base64 encode of [EC|R]SA Signature
##
## Returns: integer (1 True, 0 False) if signature is valid
##
## Verify the X509 signature of Canonical XML
##
sub _verify_x509_cert {
    my $self = shift;
    my ($cert, $canonical, $sig) = @_;

    # Decode signature and verify
    my $bin_signature = decode_base64($sig);

    if ($cert->key_alg_name eq 'id-ecPublicKey') {
        eval {require Crypt::PK::ECC; CryptX->VERSION('0.036'); 1}
        or confess "Crypt::PK::ECC 0.036+ needs to be installed so
             that we can handle ECDSA signatures";
        my $ecdsa_pub = Crypt::PK::ECC->new(\$cert->pubkey);

        my $ecdsa_hash = $self->{rsa_hash};

        # Signature is stored as the concatenation of r and s.
        # verify_message_rfc7518 expects that format
        if ($ecdsa_pub->verify_message_rfc7518( $bin_signature, $canonical, uc($self->{sig_hash}) )) {
            $self->{signer_cert} = $cert;
            return 1;
        }
    }
    elsif ($cert->key_alg_name eq 'dsaEncryption') {
        eval {
            require Crypt::OpenSSL::DSA;
        };
        confess "Crypt::OpenSSL::DSA needs to be installed so
                    that we can handle DSA X509 certificates" if $@;

        my $dsa_pub  = Crypt::OpenSSL::DSA->read_pub_key_str( $cert->pubkey );
        my $sig_size = ($dsa_pub->get_sig_size - 8)/2;
        #my ($r, $s) = unpack('a20a20', $bin_signature);
        my $unpk = "a" . $sig_size . "a" . $sig_size;
        my ($r, $s) = unpack($unpk, $bin_signature);

        # Create a new Signature Object from r and s
        my $sigobj = Crypt::OpenSSL::DSA::Signature->new();
        $sigobj->set_r($r);
        $sigobj->set_s($s);

        if ($dsa_pub->do_verify($self->{sig_method}->($canonical), $sigobj)) {
            $self->{signer_cert} = $cert;
            return 1;
        }
    }
    else {
        eval {
            require Crypt::OpenSSL::RSA;
        };
        confess "Crypt::OpenSSL::RSA needs to be installed so
                    that we can handle X509 certificates" if $@;

        my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);

        my $sig_hash = 'use_' . $self->{sig_hash} . '_hash';
        $rsa_pub->$sig_hash();
        # If successful verify, store the signer's cert for validation
        if ($rsa_pub->verify( $canonical,  $bin_signature )) {
            $self->{signer_cert} = $cert;
            return 1;
        }
    }

    return 0;
}

##
## _zero_fill_buffer($bits)
##
## Arguments:
##    $bits:     number of bits to set to zero
##
## Returns: Zero filled bit buffer of size $bits
##
## Create a buffer with all bits set to 0
##
sub _zero_fill_buffer {
    my $bits = shift;
    # set all bit to zero
    my $v = '';
    for (my $i = 0; $i < $bits; $i++) {
        vec($v, $i, 1) = 0;
    }
    return $v;
}

##
## _concat_dsa_sig_r_s(\$buffer,$r,$s)
##
## Arguments:
##    $buffer:      Zero Filled bit buffer
##    $r:           octet stream
##    $s:           octet stream
##
## Combine r and s components of DSA signature
##
sub _concat_dsa_sig_r_s {

    my ($buffer, $r, $s, $sig_size) = @_;
    my $bits_r = (length($r)*8)-1;
    my $bits_s = (length($s)*8)-1;

    my $halfsize = $sig_size / 2;

    # Place $s right justified in $v starting at bit 319
    for (my $i = $bits_s; $i >=0; $i--) {
        vec($$buffer, $halfsize + $i + (($halfsize -1) - $bits_s) , 1) = vec($s, $i, 1);
    }

    # Place $r right justified in $v starting at bit 159
    for (my $i = $bits_r; $i >= 0 ; $i--) {
        vec($$buffer, $i + (($halfsize -1) - $bits_r) , 1) = vec($r, $i, 1);
    }

}

##
## _verify_dsa($context,$canonical,$sig)
##
## Arguments:
##    $context:     string XML Context to use
##    $canonical:   string Canonical XML to verify
##    $sig:         string Base64 encode 40 byte string of r and s
##
## Returns: integer (1 True, 0 False) if signature is valid
##
## Verify the DSA signature of Canonical XML
##
sub _verify_dsa {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    eval {
        require Crypt::OpenSSL::DSA;
    };
    confess "Crypt::OpenSSL::DSA needs to be installed so
                    that we can handle DSA signatures" if $@;

    # Generate Public Key from XML
    my $p = decode_base64(_trim($self->{parser}->findvalue('dsig:P', $context)));
    my $q = decode_base64(_trim($self->{parser}->findvalue('dsig:Q', $context)));
    my $g = decode_base64(_trim($self->{parser}->findvalue('dsig:G', $context)));
    my $y = decode_base64(_trim($self->{parser}->findvalue('dsig:Y', $context)));
    my $dsa_pub = Crypt::OpenSSL::DSA->new();
    $dsa_pub->set_p($p);
    $dsa_pub->set_q($q);
    $dsa_pub->set_g($g);
    $dsa_pub->set_pub_key($y);

    # Decode signature and verify
    my $bin_signature = decode_base64($sig);

    # https://www.w3.org/TR/2002/REC-xmldsig-core-20020212/#sec-SignatureAlg
    # The output of the DSA algorithm consists of a pair of integers
    # The signature value consists of the base64 encoding of the
    # concatenation of r and s in that order ($r . $s)
    # Binary Signature is stored as a concatenation of r and s
    my $sig_size = ($dsa_pub->get_sig_size - 8)/2;
    my $unpk = "a" . $sig_size . "a" . $sig_size;
    my ($r, $s) = unpack($unpk, $bin_signature);

    # Create a new Signature Object from r and s
    my $sigobj = Crypt::OpenSSL::DSA::Signature->new();
    $sigobj->set_r($r);
    $sigobj->set_s($s);

    # DSA signatures are limited to a message body of 20 characters, so a sha1 digest is taken
    return 1 if ($dsa_pub->do_verify( $self->{sig_method}->($canonical),  $sigobj ));
    return 0;
}

##
## _verify_ecdsa($context,$canonical,$sig)
##
## Arguments:
##    $context:     string XML Context to use
##    $canonical:   string Canonical XML to verify
##    $sig:         string Base64 encoded
##
## Returns: integer (1 True, 0 False) if signature is valid
##
## Verify the ECDSA signature of Canonical XML
##
sub _verify_ecdsa {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    eval {require Crypt::PK::ECC; CryptX->VERSION('0.036'); 1}
    or confess "Crypt::PK::ECC 0.036+ needs to be installed so
             that we can handle ECDSA signatures";
    # Generate Public Key from XML
    my $oid = _trim($self->{parser}->findvalue('//dsig:NamedCurve/@URN', $context));

    use URI ();
    my $u1 = URI->new($oid);
    $oid = $u1->nss;

    my %curve_name = (
        '1.2.840.10045.3.1.1'   => 'secp192r1',
        '1.3.132.0.33'          => 'secp224r1',
        '1.2.840.10045.3.1.7'   => 'secp256r1',
        '1.3.132.0.34'          => 'secp384r1',
        '1.3.132.0.35'          => 'secp521r1',
        '1.3.36.3.3.2.8.1.1.1'  => 'brainpoolP160r1',
        '1.3.36.3.3.2.8.1.1.3'  => 'brainpoolP192r1',
        '1.3.36.3.3.2.8.1.1.5'  => 'brainpoolP224r1',
        '1.3.36.3.3.2.8.1.1.7'  => 'brainpoolP256r1',
        '1.3.36.3.3.2.8.1.1.9'  => 'brainpoolP320r1',
        '1.3.36.3.3.2.8.1.1.11' => 'brainpoolP384r1',
        '1.3.36.3.3.2.8.1.1.13' => 'brainpoolP512r1',
    );

    my $x = $self->{parser}->findvalue('//dsig:PublicKey/dsig:X/@Value', $context);
    my $y = $self->{parser}->findvalue('//dsig:PublicKey/dsig:Y/@Value', $context);

    my $ecdsa_pub = Crypt::PK::ECC->new();

    $ecdsa_pub->import_key({
        kty => "EC",
        curve_name => $curve_name{ $oid },
        pub_x   => $x,
        pub_y   => $y,
    });

    my $bin_signature = decode_base64($sig);

    # verify_message_rfc7518 is used to verify signature stored as a
    # concatenation of integers r and s
    return 1 if ($ecdsa_pub->verify_message_rfc7518(
                    $bin_signature,
                    $canonical,
                    uc($self->{sig_hash}))
                );
    return 0;
}

##
## _get_node($xpath, context)
##
## Arguments:
##    $xpath:       string XML XPath to use
##    $context:     string XML context
##
## Returns: string  XML NodeSet
##
## Return a NodeSet based on the xpath string
##
sub _get_node {
    my $self = shift;
    my ($xpath, $context) = @_;
    my $nodeset;
    if ($context) {
         $nodeset = $self->{parser}->find($xpath, $context);
    } else {
         $nodeset = $self->{parser}->find($xpath);
    }
    foreach my $node ($nodeset->get_nodelist) {
        return $node;
    }
}

# TODO remove unused?
sub _get_node_as_text {
    my $self = shift;
    my ($xpath, $context) = @_;
    my $node = $self->_get_node($xpath, $context);
    if ($node) {
        return $node->toString;
    } else {
        return '';
    }
}

# TODO remove unused?
sub _transform_env_sig {
    my $self = shift;
    my ($str) = @_;
    my $prefix = '';
    if (defined $self->{dsig_prefix} && length $self->{dsig_prefix}) {
        $prefix = $self->{dsig_prefix} . ':';
    }

    # This removes the first Signature tag from the XML - even if there is another XML tree with another Signature inside and that comes first.
    # TODO: Remove the outermost Signature only.

    $str =~ s/(<${prefix}Signature(.*?)>(.*?)\<\/${prefix}Signature>)//is;

    return $str;
}

##
## _trim($string)
##
## Arguments:
##    $string:      string String to remove whitespace
##
## Returns: string  Trimmed String
##
## Trim the whitespace from the begining and end of the string
##
sub _trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

##
## _load_ecdsa_key($key_text)
##
## Arguments:
##    $key_text:    string ECDSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{KeyInfo}
##   self->{key_obj}
##   self->{key_type}
##
sub _load_ecdsa_key {
    my $self = shift;
    my $key_text = shift;

    eval {require Crypt::PK::ECC; CryptX->VERSION('0.036'); 1}
    or confess "Crypt::PK::ECC 0.036+ needs to be installed so
             that we can handle ECDSA signatures";

    my $ecdsa_key = Crypt::PK::ECC->new('t/ecdsa.private.pem');

    if ( $ecdsa_key ) {
        $self->{ key_obj } = $ecdsa_key;

        my $key_hash    = $ecdsa_key->key2hash;

        my $oid         = $key_hash->{ curve_oid };
        my $x           = $key_hash->{ pub_x };
        my $y           = $key_hash->{ pub_y };

        $self->{KeyInfo} = "<dsig:KeyInfo>
                             <dsig:KeyValue>
                                <dsig:ECDSAKeyValue>
                                    <dsig:DomainParameters>
                                        <dsig:NamedCurve URN=\"urn:oid:$oid\" />
                                    </dsig:DomainParameters>
                                    <dsig:PublicKey>
                                        <dsig:X Value=\"$x\" />
                                        <dsig:Y Value=\"$y\" />
                                    </dsig:PublicKey>
                                </dsig:ECDSAKeyValue>
                             </dsig:KeyValue>
                            </dsig:KeyInfo>";
        $self->{key_type} = 'ecdsa';
    }
    else {
        confess "did not get a new Crypt::PK::ECC object";
    }
}

##
## _load_dsa_key($key_text)
##
## Arguments:
##    $key_text:    string DSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{KeyInfo}
##   self->{key_obj}
##   self->{key_type}
##
sub _load_dsa_key {
    my $self = shift;
    my $key_text = shift;

    eval {
        require Crypt::OpenSSL::DSA;
    };

    confess "Crypt::OpenSSL::DSA needs to be installed so that we can handle DSA keys." if $@;

    my $dsa_key = Crypt::OpenSSL::DSA->read_priv_key_str( $key_text );

    if ( $dsa_key ) {
        $self->{ key_obj } = $dsa_key;
        my $g = encode_base64( $dsa_key->get_g(), '' );
        my $p = encode_base64( $dsa_key->get_p(), '' );
        my $q = encode_base64( $dsa_key->get_q(), '' );
        my $y = encode_base64( $dsa_key->get_pub_key(), '' );

        $self->{KeyInfo} = "<dsig:KeyInfo>
                             <dsig:KeyValue>
                              <dsig:DSAKeyValue>
                               <dsig:P>$p</dsig:P>
                               <dsig:Q>$q</dsig:Q>
                               <dsig:G>$g</dsig:G>
                               <dsig:Y>$y</dsig:Y>
                              </dsig:DSAKeyValue>
                             </dsig:KeyValue>
                            </dsig:KeyInfo>";
        $self->{key_type} = 'dsa';
    }
    else {
        confess "did not get a new Crypt::OpenSSL::RSA object";
    }
}

##
## _load_rsa_key($key_text)
##
## Arguments:
##    $key_text:    string RSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{KeyInfo}
##   self->{key_obj}
##   self->{key_type}
##
sub _load_rsa_key {
    my $self = shift;
    my ($key_text) = @_;

    eval {
        require Crypt::OpenSSL::RSA;
    };
    confess "Crypt::OpenSSL::RSA needs to be installed so that we can handle RSA keys." if $@;

    my $rsaKey = Crypt::OpenSSL::RSA->new_private_key( $key_text );

    if ( $rsaKey ) {
        $rsaKey->use_pkcs1_padding();
        $self->{ key_obj }  = $rsaKey;
        $self->{ key_type } = 'rsa';

        if (!$self->{ x509 }) {
            my $bigNum = ( $rsaKey->get_key_parameters() )[1];
            my $bin = $bigNum->to_bin();
            my $exp = encode_base64( $bin, '' );

            $bigNum = ( $rsaKey->get_key_parameters() )[0];
            $bin = $bigNum->to_bin();
            my $mod = encode_base64( $bin, '' );
            $self->{KeyInfo} = "<dsig:KeyInfo>
                                 <dsig:KeyValue>
                                  <dsig:RSAKeyValue>
                                   <dsig:Modulus>$mod</dsig:Modulus>
                                   <dsig:Exponent>$exp</dsig:Exponent>
                                  </dsig:RSAKeyValue>
                                 </dsig:KeyValue>
                                </dsig:KeyInfo>";
        }
    }
    else {
        confess "did not get a new Crypt::OpenSSL::RSA object";
    }
}

##
## _load_x509_key($key_text)
##
## Arguments:
##    $key_text:    string RSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{key_obj}
##   self->{key_type}
##
sub _load_x509_key {
    my $self = shift;
    my $key_text = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };
    confess "Crypt::OpenSSL::X509 needs to be installed so that we
            can handle X509 Certificates." if $@;

    my $x509Key = Crypt::OpenSSL::X509->new_private_key( $key_text );

    if ( $x509Key ) {
        $x509Key->use_pkcs1_padding();
        $self->{ key_obj } = $x509Key;
        $self->{key_type} = 'x509';
    }
    else {
        confess "did not get a new Crypt::OpenSSL::X509 object";
    }
}

##
## _load_cert_file()
##
## Arguments: none
##
## Returns: nothing
##
## Read the file name from $self->{ cert } and
## Populate:
##   self->{key_obj}
##   $self->{KeyInfo}
##
sub _load_cert_file {
    my $self = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };

    confess "Crypt::OpenSSL::X509 needs to be installed so that we can handle X509 certs." if $@;

    my $file = $self->{ cert };
    if ( open my $CERT, '<', $file ) {
        my $text = '';
        local $/ = undef;
        $text = <$CERT>;
        close $CERT;

        my $cert = Crypt::OpenSSL::X509->new_from_string($text);
        if ( $cert ) {
            $self->{ cert_obj } = $cert;
            my $cert_text = $cert->as_string;
            $cert_text =~ s/-----[^-]*-----//gm;
            $self->{KeyInfo} = "<dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>\n"._trim($cert_text)."\n</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>";
        }
        else {
            confess "Could not load certificate from $file";
        }
    }
    else {
        confess "Could not find certificate file $file";
    }

    return;
}

##
## _load_cert_text()
##
## Arguments: none
##
## Returns: nothing
##
## Read the certificate from $self->{ cert_text } and
## Populate:
##   self->{key_obj}
##   $self->{KeyInfo}
##
sub _load_cert_text {
    my $self = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };

    confess "Crypt::OpenSSL::X509 needs to be installed so that we can handle X509 certs." if $@;

    my $text = $self->{ cert_text };
    my $cert = Crypt::OpenSSL::X509->new_from_string($text);
    if ( $cert ) {
        $self->{ cert_obj } = $cert;
        my $cert_text = $cert->as_string;
        $cert_text =~ s/-----[^-]*-----//gm;
        $self->{KeyInfo} = "<dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>\n"._trim($cert_text)."\n</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>";
    }
    else {
            confess "Could not load certificate from given text.";
    }

    return;
}

##
## _load_key($file)
##
## Arguments: $self->{ key }
##
## Returns: nothing
##
## Load the key and process it acording to its headers
##
sub _load_key {
    my $self = shift;
    my $file = $self->{ key };

    if ( open my $KEY, '<', $file ) {
        my $text = '';
        local $/ = undef;
        $text = <$KEY>;
        close $KEY;

        if ( $text =~ m/BEGIN ([DR]SA) PRIVATE KEY/ ) {
            my $key_used = $1;

            if ( $key_used eq 'RSA' ) {
                $self->_load_rsa_key( $text );
            }
            else {
                $self->_load_dsa_key( $text );
            }

            return 1;
        } elsif ( $text =~ m/BEGIN EC PRIVATE KEY/ ) {
            $self->_load_ecdsa_key( $text );
        } elsif ( $text =~ m/BEGIN PRIVATE KEY/ ) {
            $self->_load_rsa_key( $text );
        } elsif ($text =~ m/BEGIN CERTIFICATE/) {
            $self->_load_x509_key( $text );
        }
        else {
            confess "Could not detect type of key $file.";
        }
    }
    else {
        confess "Could not load key $file: $!";
    }

    return;
}

##
## _signature_xml($signed_info,$signature_value)
##
## Arguments:
##   $signed_info:      string XML String Fragment
##   $signature_value   String Base64 Signature Value
##
## Returns: string      XML fragment
##
## Create a XML string of the Signature
##
sub _signature_xml {
    my $self = shift;
    my ($signed_info,$signature_value) = @_;
    return qq{<dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
            $signed_info
            <dsig:SignatureValue>$signature_value</dsig:SignatureValue>
            $self->{KeyInfo}
        </dsig:Signature>};
}

##
## _signedinfo_xml($digest_xml)
##
## Arguments:
##   $digest_xml        string XML String Fragment
##
## Returns: string      XML fragment
##
## Create a XML string of the SignedInfo
##
sub _signedinfo_xml {
    my $self = shift;
    my ($digest_xml) = @_;

    my $algorithm;
    if ( $self->{ sig_hash } eq 'sha1' && $self->{key_type} ne 'ecdsa' ) {
        $algorithm = "http://www.w3.org/2000/09/xmldsig#$self->{key_type}-$self->{ sig_hash }";
    }
    elsif ( $self->{key_type} eq 'ecdsa' ) {
        $algorithm = "http://www.w3.org/2001/04/xmldsig-more#$self->{key_type}-$self->{ sig_hash }";
    }
    elsif ( $self->{ key_type } eq 'dsa' && $self->{ sig_hash } eq 'sha256') {
        $algorithm = "http://www.w3.org/2009/xmldsig11#$self->{key_type}-$self->{ sig_hash }";
    }
    else {
        $algorithm = "http://www.w3.org/2001/04/xmldsig-more#$self->{key_type}-$self->{ sig_hash }";
    }

    #return qq{<dsig:SignedInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
    return qq{<dsig:SignedInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
                <dsig:SignatureMethod Algorithm="$algorithm" />
                $digest_xml
            </dsig:SignedInfo>};
}

##
## _reference_xml($id)
##
## Arguments:
##   $id        string XML ID related to the URI
##   $digest    string Base64 encoded digest
##
## Returns: string      XML fragment
##
## Create a XML string of the Reference
##
sub _reference_xml {
    my $self = shift;
    my $id = shift;
    my ($digest) = @_;

    my $algorithm;
    if ( $self->{ digest_hash } eq 'sha1') {
        $algorithm = "http://www.w3.org/2000/09/xmldsig#$self->{ digest_hash }";
    }
    elsif (($self->{ digest_hash } eq 'sha224') || ($self->{ digest_hash } eq 'sha384')) {
        $algorithm = "http://www.w3.org/2001/04/xmldsig-more#$self->{ digest_hash }";
    }
    else {
        $algorithm = "http://www.w3.org/2001/04/xmlenc#$self->{ digest_hash }";
    }

    return qq{<dsig:Reference URI="#$id">
                        <dsig:Transforms>
                            <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
                            <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
                        </dsig:Transforms>
                        <dsig:DigestMethod Algorithm="$algorithm" />
                        <dsig:DigestValue>$digest</dsig:DigestValue>
                    </dsig:Reference>};
}


##
## _canonicalize_xml($xml, $context)
##
## Arguments:
##    $xml:     string XML NodeSet
##    $context: string XML Context
##
## Returns: string  Canonical XML
##
## Canonicalizes xml based on the CanonicalizationMethod
## from the SignedInfo.
##
sub _canonicalize_xml {
    my $self = shift;
    my ($xml, $context) = @_;

    print ("_canonicalize_xml:\n") if $DEBUG;
    my $canon_method = $self->{ parser }->findnodes(
                'dsig:SignedInfo/dsig:CanonicalizationMethod', $context
    );

    foreach my $node ($canon_method->get_nodelist) {
        my $alg = $node->getAttribute('Algorithm');

        print ("    Canon Method: $alg\n") if $DEBUG;
        if ($alg eq TRANSFORM_C14N) {
           print ("        toStringC14N\n") if $DEBUG;
           $xml = $xml->toStringC14N();
        }
        elsif ($alg eq TRANSFORM_C14N_COMMENTS) {
            print ("        toStringC14N_Comments\n") if $DEBUG;
            $xml = $xml->toStringC14N(1);
        }
        elsif ($alg eq TRANSFORM_C14N_V1_1) {
           print ("        toStringC14N_v1_1\n") if $DEBUG;
           $xml = $xml->toStringC14N_v1_1();
        }
        elsif ($alg eq TRANSFORM_C14N_V1_1_COMMENTS) {
            print ("        toStringC14N_v1_1_Comments\n") if $DEBUG;
            $xml = $xml->toStringC14N_v1_1(1);
        }
        elsif ($alg eq TRANSFORM_EXC_C14N) {
            print ("        toStringEC14N\n") if $DEBUG;
            $xml = $xml->toStringEC14N();
        }
        elsif ($alg eq TRANSFORM_EXC_C14N_COMMENTS) {
            print ("        toStringEC14N_Comments\n") if $DEBUG;
            $xml = $xml->toStringEC14N(1);
        }
        else {
            die "Unsupported transform: $alg";
        }
    }
    return $xml;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::XML::Sig - Net::SAML2::XML::Sig - A toolkit to help sign and verify XML Digital Signatures

=head1 VERSION

version 0.44

=head1 SYNOPSIS

   my $xml = '<foo ID="abc">123</foo>';
   my $signer = Net::SAML2::XML::Sig->new({
     key => 'path/to/private.key',
   });

   # create a signature
   my $signed = $signer->sign($xml);
   print "Signed XML: $signed\n";

   # verify a signature
   $signer->verify($signed)
     or die "Signature Invalid.";
   print "Signature valid.\n";

=head1 DESCRIPTION

This perl module provides two primary capabilities: given an XML string, create
and insert digital signatures, or if one is already present in the string verify
it -- all in accordance with the W3C standard governing XML signatures.

=head1 NAME

Net::SAML2::XML::Sig - A toolkit to help sign and verify XML Digital Signatures.

=head1 PREREQUISITES

=over

=item * L<Digest::SHA>

=item * L<XML::LibXML>

=item * L<MIME::Base64>

=item * L<Crypt::OpenSSL::X509>

=item * L<Crypt::OpenSSL::Bignum>

=item * L<Crypt::OpenSSL::RSA>

=item * L<Crypt::OpenSSL::DSA>

=item * L<Crypt::PK::ECC>

=back

=head1 USAGE

=head2 SUPPORTED ALGORITHMS & TRANSFORMS

This module supports the following signature methods:

=over

=item * DSA

=item * RSA

=item * RSA encoded as x509

=item * ECDSA

=item * ECDSA encoded as x509

=back

This module supports the following canonicalization methods and transforms:

=over

=item * Enveloped Signature

=item * REC-xml-c14n-20010315#

=item * REC-xml-c14n-20010315#WithComments

=item * REC-xml-c14n11-20080502

=item * REC-xml-c14n11-20080502#WithComments

=item * xml-exc-c14n#

=item * xml-exc-c14n#WithComments

=back

=head2 OPTIONS

Each of the following options are also accessors on the main
Net::SAML2::XML::Sig object. TODO Not strictly correct rewrite

=over

=item B<key>

The path to a file containing the contents of a private key. This option
is used only when generating signatures.

=item B<cert>

The path to a file containing a PEM-formatted X509 certificate. This
option is used only when generating signatures with the "x509"
option. This certificate will be embedded in the signed document, and
should match the private key used for the signature.

=item B<cert_text>

A string containing a PEM-formatted X509 certificate. This
option is used only when generating signatures with the "x509"
option. This certificate will be embedded in the signed document, and
should match the private key used for the signature.

=item B<x509>

Takes a true (1) or false (0) value and indicates how you want the
signature to be encoded. When true, the X509 certificate supplied will
be encoded in the signature. Otherwise the native encoding format for
RSA, DSA and ECDSA will be used.

=item B<sig_hash>

Passing sig_hash to new allows you to specify the SignatureMethod
hashing algorithm used when signing the SignedInfo.  RSA and ECDSA
supports the hashes specified sha1, sha224, sha256, sha384 and sha512

DSA supports only sha1 and sha256 (but you really should not sign
anything with DSA anyway).

=item B<digest_hash>

Passing digest_hash to new allows you to specify the DigestMethod
hashing algorithm used when calculating the hash of the XML being
signed.  Supported hashes can be specified sha1, sha224, sha256,
sha384, and sha512

=item B<no_xml_declaration>

Some applications such as Net::SAML2 expect to sign a fragment of the
full XML document so is this is true (1) it will not include the
XML Declaration at the beginning of the signed XML.  False (0) or
undefined returns an XML document starting with the XML Declaration.

=back

=head2 METHODS

=head3 B<new(...)>

Constructor; see OPTIONS above.

=head3 B<sign($xml)>

When given a string of XML, it will return the same string with a signature
generated from the key provided when the Net::SAML2::XML::Sig object was initialized.

This method will sign all elements in your XML with an ID (case sensitive)
attribute. Each element with an ID attribute will be the basis for a seperate
signature. It will correspond to the URI attribute in the Reference element
that will be contained by the signature. If no ID attribute can be found on
an element, the signature will not be created.

The elements are signed in reverse order currently assuming (possibly
incorrectly) that the lower element in the tree may need to be signed
inclusive of its Signature because it is a child of the higher element.

Arguments:
    $xml:     string XML string

Returns: string  Signed XML

=head3 B<verify($xml)>

Returns true or false based upon whether the signature is valid or not.

When using Net::SAML2::XML::Sig exclusively to verify a signature, no key needs to be
specified during initialization given that the public key should be
transmitted with the signature.

Net::SAML2::XML::Sig checks all signature in the provided xml and will fail should any
signature pointing to an existing ID in the XML fail to verify.

Should there be a Signature included that does not point to an existing node
in the XML it is ignored and other Signaures are checked.  If there are no
other Signatures it will return false.

Arguments:
    $xml:     string XML string

Returns: string  Signed XML

=head3 B<signer_cert()>

Following a successful verify with an X509 certificate, returns the
signer's certificate as embedded in the XML document for verification
against a CA certificate. The certificate is returned as a
Crypt::OpenSSL::X509 object.

Arguments: none

Returns: Crypt::OpenSSL::X509: Certificate used to sign the XML

=head1 ABOUT DIGITAL SIGNATURES

Just as one might want to send an email message that is cryptographically signed
in order to give the recipient the means to independently verify who sent the email,
one might also want to sign an XML document. This is especially true in the
scenario where an XML document is received in an otherwise unauthenticated
context, e.g. SAML.

However XML provides a challenge that email does not. In XML, two documents can be
byte-wise inequivalent, and semanticaly equivalent at the same time. For example:

    <?xml version="1.0"?>
    <foo>
      <bar />
    </foo>

    And:

    <?xml version="1.0"?>
    <foo>
      <bar></bar>
    </foo>

Each of these document express the same thing, or in other words they "mean"
the same thing. However if you were to strictly sign the raw text of these
documents, they would each produce different signatures.

XML Signatures on the other hand will produce the same signature for each of
the documents above. Therefore an XML document can be written and rewritten by
different parties and still be able to have someone at the end of the line
verify a signature the document may contain.

There is a specially subscribed methodology for how this process should be
executed and involves transforming the XML into its canonical form so a
signature can be reliably inserted or extracted for verification. This
module implements that process.

=head2 EXAMPLE SIGNATURE

Below is a sample XML signature to give you some sense of what they look like.
First let's look at the original XML document, prior to being signed:

  <?xml version="1.0"?>
  <foo ID="abc">
    <bar>123</bar>
  </foo>

Now, let's insert a signature:

  <?xml version="1.0"?>
  <foo ID="abc">
    <bar>123</bar>
    <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
      <SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
        <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments" />
        <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
        <Reference URI="#abc">
          <Transforms>
            <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
          </Transforms>
          <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
          <DigestValue>9kpmrvv3peVJpNSTRycrV+jeHVY=</DigestValue>
        </Reference>
      </SignedInfo>
      <SignatureValue>
        HXUBnMgPJf//j4ihaWnaylNwAR5AzDFY83HljFIlLmTqX1w1C72ZTuRObvYve8TNEbVsQlTQkj4R
        hiY0pgIMQUb75GLYFtc+f0YmBZf5rCWY3NWzo432D3ogAvpEzYXEQPmicWe2QozQhybaz9/wrYki
        XiXY+57fqCkf7aT8Bb6G+fn7Aj8gnZFLkmKxwCdyGsIZOIZdQ8MWpeQrifxBR0d8W1Zm6ix21WNv
        ONt575h7VxLKw8BDhNPS0p8CS3hOnSk29stpiDMCHFPxAwrbKVL1kGDLaLZn1q8nNRmH8oFxG15l
        UmS3JXDZAss8gZhU7g9T4XllCqjrAvzPLOFdeQ==
      </SignatureValue>
      <KeyInfo>
        <KeyValue>
          <RSAKeyValue>
            <Modulus>
              1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPKD7KGtkKn9vq
              i4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1XABtbxTimS1B0aO1zYW6d+U
              Yl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1VI8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bH
              n/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCf
              OSMsf0TX+OdlbH079AsxOwoUjlzjuKdCiFPdU6yAJw==
            </Modulus>
            <Exponent>Iw==</Exponent>
          </RSAKeyValue>
        </KeyValue>
      </KeyInfo>
    </Signature>
  </foo>

=head1 SEE ALSO

L<http://www.w3.org/TR/xmldsig-core/>

=head1 VERSION CONTROL

L<https://github.com/perl-net-saml2/perl-XML-Sig>

=head1 AUTHORS and CREDITS

Author: Byrne Reese <byrne@majordojo.com>

Thanks to Manni Heumann who wrote Google::SAML::Response from
which this module borrows heavily in order to create digital
signatures.

Net::SAML2 embedded version amended by Chris Andrews <chris@nodnol.org>.

Maintainer: Timothy Legge <timlegge@cpan.org>

=head1 AUTHOR

Chris Andrews  <chrisa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Chris Andrews and Others, see the git log.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

}

