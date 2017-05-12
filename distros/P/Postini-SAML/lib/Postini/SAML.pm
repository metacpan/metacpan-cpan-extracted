package Postini::SAML;
{
  $Postini::SAML::VERSION = '0.001';
}

use warnings;
use strict;

use Crypt::OpenSSL::RSA;
use MIME::Base64 qw( encode_base64 );
use XML::Spice;
use Date::Format qw( time2str );
use Data::Random qw( rand_chars );
use XML::CanonicalizeXML;
use Digest::SHA1 qw( sha1 );
use Carp qw( croak );

# Postini SAML ACS
my $ACS_URL = 'https://pfs.postini.com/pfs/spServlet';

sub get_acs_url {
    return $ACS_URL;
}

sub new {
    my ($class, $arg) = @_;

    my @missing = grep { not exists $arg->{$_} } qw( keyfile certfile issuer );
    if ( @missing )
    {
        croak "missing args: " . join( q{ }, @missing );
    }
    
    my $self = bless {}, $class;

    $self->_load_rsa_key( $arg->{'keyfile'}, $arg->{'certfile'} );

    $self->{'issuer'} = $arg->{'issuer'};

    return $self;
}

sub _load_rsa_key {
    my ($self, $key_file, $cert_file) = @_;

    # load the keyfile and prepare a context for signing
    open my $key_fh, '<', $key_file or croak "couldn't open $key_file for reading: $!";
    my $key_text = do { local $/; <$key_fh> };
    close $key_fh;

    my $key = Crypt::OpenSSL::RSA->new_private_key( $key_text );
    if ( not $key )
    {
        croak "failed to instantiate Crypt::OpenSSL::RSA object from $key_file";
    }

    $key->use_pkcs1_padding();
    $self->{'key'} = $key;

    # we need to include the certificate without headers in the signed XML, so
    # extract it
    open my $cert_fh, '<', $cert_file or croak "couldn't open $cert_file for reading: $!";
    my $cert_text = do { local $/; <$cert_fh> };
    close $cert_fh;

    my ($cert_pem) = $cert_text =~ m{
        -----BEGIN\sCERTIFICATE-----
        (.+)
        -----END\sCERTIFICATE-----
    }smx;
    $cert_pem =~ s{ [\r\n]+ }{}smxg;

    # build a XML fragment containing the key info. this will be included in
    # the signature XML
    $self->{'key_info_xml'} =
        x('ds:KeyInfo',
            x('ds:X509Data',
                x('ds:X509Certificate', $cert_pem),
            ),
        ),
    ;
}

# return the current signature xml (actually XML::Spice chunk). deliberately
# returns undef if its not available, causing it to be ignored during chunk
# expansion
sub _get_cached_signature_xml {
    my ($self) = @_;
    return $self->{'signature_xml'};
}

# generate a valid, signed response and return it
sub get_response_xml {
    my ($self, $mail) = @_;

    if ( not $mail )
    {
        croak "required email address not provided";
    }

    # INPUT: 
    #   T, text-to-be-signed, a byte string; 
    #   Ks, RSA private key; 
    #
    # 1. Canonicalize the text-to-be-signed, C = C14n(T).
    # 2. Compute the message digest of the canonicalized text, m = Hash(C).
    # 3. Encapsulate the message digest in an XML <SignedInfo> element, SI, in canonicalized form.
    # 4. Compute the RSA signatureValue of the canonicalized <SignedInfo> element, SV = RsaSign(Ks, SI).
    # 5. Compose the final XML document including the signatureValue, this time in non-canonicalized form.
    
    # get rid of any cached signature
    delete $self->{'signature_xml'};

    # get the response data and canonicalise it
    my $response_xml = $self->_response_xml( $mail );
    my $canonical_response_xml = $self->_canonicalize_xml( $response_xml );

    # compute digest
    my $response_digest = encode_base64( sha1( $canonical_response_xml ), q{} );

    # create a canonical signed info fragment
    my $signed_info_xml = $self->_signed_info_xml( $response_digest );
    my $canonical_signed_info_xml = $self->_canonicalize_xml( $signed_info_xml );

    # create the signature
    my $signature = encode_base64( $self->{'key'}->sign( $canonical_signed_info_xml ), q{} );

    # now create the signature xml fragment
    $self->{'signature_xml'} = $self->_signature_xml( $signed_info_xml, $signature );;

    # force the response chunk to be regenerated which will cause the
    # signature to be included
    $response_xml->forget;

    # stringify and return
    return "".$response_xml;
}

# generate a signature XML fragment, including the signature metadata fragment
# and the raw signature
sub _signature_xml {
    my ($self, $signed_info_xml, $signature) = @_;

    my $signature_xml =
        x('ds:Signature',
            {
                'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
            },
            $signed_info_xml,
            x('ds:SignatureValue', $signature),
            $self->{'key_info_xml'},
        ),
    ;

    return $signature_xml;
}

# generate a signature metadata XML fragement, including the message digest
sub _signed_info_xml {
    my ($self, $digest) = @_;

    my $signed_info_xml =
        x('ds:SignedInfo',
            {
                # we must include all the namespaces in use anywhere in the
                # document so they can be included in the signature
                'xmlns:ds'    => 'http://www.w3.org/2000/09/xmldsig#',
                'xmlns:saml'  => 'urn:oasis:names:tc:SAML:1.0:assertion',
                'xmlns:samlp' => 'urn:oasis:names:tc:SAML:1.0:protocol',
            },

            x('ds:CanonicalizationMethod',
                {
                    'Algorithm' => 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315',
                },
            ),
            x('ds:SignatureMethod',
                {
                    'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
                },
            ),

            x('ds:Reference',
                {
                    'URI' => "",
                },
                x('ds:Transforms',
                    x('ds:Transform',
                        {
                            'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#enveloped-signature',
                        },
                    ),
                ),
                x('ds:DigestMethod',
                    {
                        'Algorithm' => 'http://www.w3.org/2000/09/xmldsig#sha1',
                    }
                ),
                x('ds:DigestValue', $digest),
            ),
        ),
    ;

    return $signed_info_xml;
}

# build the SAML response, including the signature if available
sub _response_xml {
    my ($self, $mail) = @_;

    my $now = time();
    my $issue_instant = time2str( '%Y-%m-%dT%XZ', $now, 'UTC' );

    # assertion is valid for 60 seconds
    my $not_on_or_after = time2str( '%Y-%m-%dT%XZ', $now+60, 'UTC' );

    # first character must not be a number to match xsd:ID
    my $response_id  = join q{}, 'z', rand_chars( 'set' => 'alphanumeric', 'size' => 40 );
    my $assertion_id = join q{}, 'z', rand_chars( 'set' => 'alphanumeric', 'size' => 40 );
    my $name_id      = join q{}, 'z', rand_chars( 'set' => 'alphanumeric', 'size' => 40 );

    my $response_xml =
        x('samlp:Response',
            {
                'xmlns:saml'   => 'urn:oasis:names:tc:SAML:1.0:assertion',
                'xmlns:samlp'  => 'urn:oasis:names:tc:SAML:1.0:protocol',

                'MajorVersion' => '1',
                'MinorVersion' => '1',

                'IssueInstant' => $issue_instant,
                'ResponseID'   => $response_id,
                'Recipient'    => $ACS_URL,
            },

            # include the signature if its available. if not then it wil be
            # undef and will be ignored
            sub { $self->{'signature_xml'} },

            x('samlp:Status',
                x('samlp:StatusCode',
                    {
                        'Value' => 'samlp:Success',
                    },
                ),
            ),

            x('saml:Assertion',
                {
                    'MajorVersion' => '1',
                    'MinorVersion' => '1',

                    'IssueInstant' => $issue_instant,
                    'AssertionID'  => $assertion_id,
                    'Issuer'       => $self->{'issuer'},
                },

                x('saml:Conditions',
                    {
                        'NotBefore'    => $issue_instant,
                        'NotOnOrAfter' => $not_on_or_after,
                    },
                ),

                x('saml:AuthenticationStatement',
                    {
                        'AuthenticationInstant' => $issue_instant,
                        'AuthenticationMethod' => 'urn:oasis:names:tc:SAML:1.0:am:unspecified',
                    },

                    x('saml:Subject',
                        x('saml:NameIdentifier', $name_id),
                        x('saml:SubjectConfirmation',
                            x('saml:ConfirmationMethod', 'urn:oasis:names:tc:SAML:1.0:cm:bearer'),
                        ),
                    ),
                ),

                x('saml:AttributeStatement',
                    x('saml:Subject',
                        x('saml:NameIdentifier', $name_id),
                        x('saml:SubjectConfirmation',
                            x('saml:ConfirmationMethod', 'urn:oasis:names:tc:SAML:1.0:cm:bearer'),
                        ),
                    ),

                    x('saml:Attribute',
                        {
                            'AttributeName'      => 'personal_email',
                            'AttributeNamespace' => 'urn:mace:shibboleth:1.0:attributeNamespace:uri',
                        },
                        x('saml:AttributeValue', $mail),
                    ),
                ),
            ),
        ),
    ;

    return $response_xml;
}

# canonicalise XML using W3C REC-xml-c14n-20010315 algorithm
# returns a string, not a XML::Spice chunk
sub _canonicalize_xml {
    my ($self, $xml) = @_;

    my $xpath = '<XPath>(//. | //@* | //namespace::*)</XPath>';
    return XML::CanonicalizeXML::canonicalize( $xml, $xpath, [], 0, 0 );
}

sub get_form {
    my ($self, $mail) = @_;

    my $saml_response = encode_base64( $self->get_response_xml( $mail ), q{} );

    my $html = join( q{},
        qq{<form action="$ACS_URL" method="post">},
        qq{<input type="hidden" name="SAMLResponse" value="$saml_response" />},
        qq{<input type="hidden" name="TARGET" value="$ACS_URL" />},
        qq{<input type="submit" name="Submit" value="Submit" />},
        qq{</form>},
    );

    return $html;
}

__END__

=head1 NAME

Postini::SAML - Do SAML-based sign-in to Postini services

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Postini::SAML;

    # setup keys and certificates
    my $saml = Postini::SAML->new({
        keyfile  => 'postini.key',
        certfile => 'postini.crt',
        issuer   => 'example.com',
    });

    # get a signed SAML response that will sign in the given user
    my $response_xml = $saml->get_response_xml('user@example.com');
 
    # quick and dirty HTML form for testing
    print $saml->get_form('user@example.com');

=head1 DESCRIPTION

L<Postini::SAML> creates signed SAML responses suitable for signing your users
into Postini services (aka "Google Message Security" and/or "Google Message
Discovery").

It is not a complete SAML implementation or SSO solution. It implements just
enough of the SAML spec to get you into Postini. The author is not an expert
on SAML, XML or security in general. Don't be afraid though; this module does
work and is production use at at least one site :)

Postini offers two modes of operation for SAML SSO - "push" (or "post") and
"pull" (or "artifact). This modules implements the push model.

The typical SAML flow for Postini is slightly different to a standard SAML
flow in that it is not initiated on the Postini side. Instead you need to set
up a sign-in page on your website or application server and direct your users
to it. The flow is as follows:

=over 4

=item *

User accesses a web page that you provide. If they are not already identified
(signed in), they work through some sign-in process.

=item *

Page uses L<Postini::SAML> to generate a HTML form containing the signed
response with the user's Postini username (email address). The form target is
the Postini ACS URL.

=item *

User submits the form (either explicitly or implicitly eg via Javascript) to
Postini.

=item *

Postini verifies the signature and if valid, signs the user in.

=back

See the discussion of L</get_form> for information on how to generate your own
form.

=head1 SETUP

Before you use this module its necessary to have SSO configured for your
Postini organisation. The Postini docs are a bit thin on what you need to do.
A full explanation is well outside the scope of this document, but here's list
of things you should have in place before trying to use this module:

=over 4

=item *

Create a certificate and key pair.

=item *

Upload the certificate/public key to Postini. Set an appropriate value for the
issuer (typically your domain name).

=item *

Enable SSO login for one or more of your user organisations. Make sure you
keep at least one admin user in another organisation that uses password login,
otherwise you may find you can't get back in if something goes wrong.

=back

=head1 CONSTRUCTOR

    my $saml = Postini::SAML->new({
        keyfile  => 'postini.key',
        certfile => 'postini.crt',
        issuer   => 'example.com',
    });

Creates an object that can produce SAML responses. You need to provide three arguments:

=over 4

=item keyfile

Name of file containing the private key in PEM format.

=item certfile

Name of file containing the certificate in PEM format.

=item issuer

The issuer attached to this certificate in the Postini configuration.

=back

=head1 METHODS

=head2 get_response_xml

    my $response_xml = $saml->get_response_xml('user@example.com');

Create a signed SAML response document that, when submitted to the Postini ACS
URL, will sign in the specified user. The response is valid for 60 seconds and
so should be returned to the user for submission immediately.

=head2 get_form

    print $saml->get_form('user@example.com');

Creates a basic HTML form that, when submitted, will sign in the specified
user. This is provided for testing purposes only. While you could use it as
part of a larger page you're probably better to make something tailored to
your environment.

To submit the SAML response to Postini you need to perform a HTTP POST to the
ACS URL, which can be obtained using L</get_acs_url>. The request takes two
arguments:

=over 4

=item SAMLResponse

The Base64-encoded response XML returned by L</get_response_xml>.

=item TARGET

The Postini ACS URL, obtained using L</get_acs_url>.

=back

=head2 get_acs_url

    my $acs_url = $saml->get_acs_url;

Get the ACS URL to submit the SAML response document to. The is hardcoded to
C<https://pfs.postini.com/pfs/spServlet>.

=head1 BUGS

None known. Please report bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Postini-SAML>

=head1 FEEDBACK

If you find this module useful, please consider rating it on the CPAN Ratings
service at L<http://cpanratings.perl.org/rate?distribution=Postini-SAML>.

If you like (or hate) this module, please tell the author! Send mail to
E<lt>rob@eatenbyagrue.orgE<gt>.

=head1 SEE ALSO

L<Google::SAML::Response>

=head1 AUTHOR

Robert Norris E<lt>rob@eatenbyagrue.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Monash University.

This module is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
