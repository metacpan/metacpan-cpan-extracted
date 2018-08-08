package Net::SPID::SAML;
$Net::SPID::SAML::VERSION = '0.15';
use Moo;

use Carp;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use File::Slurp qw(read_file);
use MIME::Base64 qw(decode_base64);
use Net::SPID::SAML::IdP;
use Net::SPID::SAML::In::LogoutRequest;
use Net::SPID::SAML::In::LogoutResponse;
use Net::SPID::SAML::In::Response;
use Net::SPID::SAML::Out::AuthnRequest;
use Net::SPID::SAML::Out::LogoutRequest;
use Net::SPID::SAML::Out::LogoutResponse;
use URI::Escape qw(uri_escape);
use XML::Writer;

has 'sp_entityid'   => (is => 'ro', required => 1);
has 'sp_key_file'   => (is => 'ro', required => 1);
has 'sp_cert_file'  => (is => 'ro', required => 1);
has 'sp_key'        => (is => 'lazy');
has 'sp_cert'       => (is => 'lazy');
has 'sp_assertionconsumerservice'   => (is => 'ro', required => 1);
has 'sp_singlelogoutservice'        => (is => 'ro', required => 1);
has 'sp_attributeconsumingservice'  => (is => 'ro', default => sub {[]});
has '_idp'          => (is => 'ro', default => sub { {} });

extends 'Net::SPID';

sub _build_sp_key {
    my ($self) = @_;
    
    my $key_string = read_file($self->sp_key_file);
    my $key = Crypt::OpenSSL::RSA->new_private_key($key_string);
    $key->use_sha256_hash;
    return $key;
}

sub _build_sp_cert {
    my ($self) = @_;
    
    return Crypt::OpenSSL::X509->new_from_file($self->sp_cert_file);
}

# TODO: generate the actual SPID button.
sub get_button {
    my ($self, $url_cb) = @_;
    
    # If $url_cb is a sprintf pattern, turn it into a callback.
    if (!ref $url_cb) {
        my $pattern = $url_cb;
        $url_cb = sub {
            sprintf $pattern, uri_escape(shift);
        };
    }
    
    my $html = '';
    foreach my $idp_id (sort keys %{$self->_idp}) {
        $html .= sprintf qq!<p><a class="btn btn-primary" href="%s">Login with SPID</a> <small>(%s)</small></p>\n!,
            $url_cb->($idp_id), $idp_id;
    }
    return $html;
}

sub load_idp_metadata {
    my ($self, $dir) = @_;
    
    $self->load_idp_from_xml_file($_) for glob "$dir/*.xml";
}

sub load_idp_from_xml_file {
    my ($self, $xml_file) = @_;
    
    # slurp XML from file
    my $xml = do { local $/ = undef; open my $fh, '<', $xml_file; scalar <$fh> };
    
    return $self->load_idp_from_xml($xml);
}

sub load_idp_from_xml {
    my ($self, $xml) = @_;
    
    my $idp = Net::SPID::SAML::IdP->new_from_xml(
        _spid   => $self,
        xml     => $xml,
    );
    $self->_idp->{$idp->entityID} = $idp;
    
    return 1;
}

sub idps {
    my ($self) = @_;
    
    return $self->_idp;
}

sub get_idp {
    my ($self, $idp_entityid) = @_;
    
    return $self->_idp->{$idp_entityid};
}

sub parse_response {
    my ($self, $payload, $in_response_to) = @_;
    
    my $a = Net::SPID::SAML::In::Response->new(
        _spid       => $self,
        base64      => $payload,
    );
    
    # Validate response. This will throw an exception in case of failure.
    $a->validate(in_response_to => $in_response_to);
    
    return $a;
}

sub parse_logoutresponse {
    my ($self, $payload, $url, $in_response_to) = @_;
    
    my $r = Net::SPID::SAML::In::LogoutResponse->new(
        _spid       => $self,
        base64      => $payload,
        url         => $url,
    );
    
    # Validate response. This will throw an exception in case of failure.
    $r->validate(in_response_to => $in_response_to);
    
    return $r;
}

sub parse_logoutrequest {
    my ($self, $payload, $url) = @_;
    
    my $r = Net::SPID::SAML::In::LogoutRequest->new(
        _spid       => $self,
        base64      => $payload,
        url         => $url,
    );
    
    # Validate request. This will throw an exception in case of failure.
    $r->validate;
    
    return $r;
}

sub metadata {
    my ($self) = @_;
    
    my $md   = 'urn:oasis:names:tc:SAML:2.0:metadata';
    my $dsig = 'http://www.w3.org/2000/09/xmldsig#';
    my $x = XML::Writer->new( 
        OUTPUT          => 'self', 
        NAMESPACES      => 1,
        PREFIX_MAP      => {
            $md   => 'md',
            $dsig => 'ds',
        },
    );
    
    my $ID = $self->sp_entityid;
    $ID =~ s/[^a-z0-9_-]/_/g;
    $x->startTag([$md, 'EntityDescriptor'],
        entityID => $self->sp_entityid,
        ID => $ID);
    
    $x->startTag([$md, 'SPSSODescriptor'],
        protocolSupportEnumeration => 'urn:oasis:names:tc:SAML:2.0:protocol',
        AuthnRequestsSigned => 'true',
        WantAssertionsSigned => 'true');
    
    {
        $x->startTag([$md, 'KeyDescriptor'], use => 'signing');
        $x->startTag([$dsig, 'KeyInfo']);
        $x->startTag([$dsig, 'X509Data']);
        
        my $cert = $self->sp_cert->as_string;
        $cert =~ s/^-+BEGIN CERTIFICATE-+\n//;
        $cert =~ s/\n-+END CERTIFICATE-+\n?//;
        $x->dataElement([$dsig, 'X509Certificate'], $cert);
        
        $x->endTag(); #ds:X509Data
        $x->endTag(); #ds:KeyInfo
        $x->endTag(); #KeyDescriptor
    }
    $x->dataElement([$md, 'NameIDFormat'],
        'urn:oasis:names:tc:SAML:2.0:nameid-format:transient');
    
    foreach my $acs_index (0..$#{$self->sp_assertionconsumerservice}) {
        $x->emptyTag([$md, 'SingleSignOnService'],
            Location => $self->sp_assertionconsumerservice->[$acs_index],
            index => $acs_index,
            isDefault => $acs_index ? 'false' : 'true');
    }
    
    foreach my $url (keys %{$self->sp_singlelogoutservice}) {
        my $binding = 'urn:oasis:names:tc:SAML:2.0:bindings:'
            . $self->sp_singlelogoutservice->{$url};
        $x->emptyTag([$md, 'SingleLogoutService'],
            Location => $url,
            Binding => $binding);
    }
    
    foreach my $attr_index (0..$#{$self->sp_attributeconsumingservice}) {
        my $attr = $self->sp_attributeconsumingservice->[$attr_index];
        $x->startTag([$md, 'AttributeConsumingService'], index => $attr_index);
        $x->dataElement([$md, 'ServiceName'], $attr->{servicename});
        $x->dataElement([$md, 'RequestedAttribute'], $_)
            for @{$attr->{attributes}};
        $x->endTag();
    }
    
    $x->endTag(); #SPSSODescriptor
    $x->endTag(); #EntityDescriptor
    
    return $x->to_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use Net::SPID;
    
    my $spid = Net::SPID->new(
        sp_entityid     => 'https://www.prova.it/',
        sp_key_file     => 'sp.key',
        sp_cert_file    => 'sp.pem',
        sp_assertionconsumerservice => [
            'http://localhost:3000/spid-sso',
        ],
        sp_singlelogoutservice => {
            'http://localhost:3000/spid-slo' => 'HTTP-Redirect',
        },
    );
    
    # load Identity Providers
    $spid->load_idp_metadata('idp_metadata/');
    # or:
    $spid->load_idp_from_xml_file('idp_metadata/prova.xml');
    # or:
    $spid->load_idp_from_xml($metadata_xml);
    
    # generate an AuthnRequest
    my $authnreq = $idp->authnrequest(
        acs_index   => 0,   # index of AssertionConsumerService as per our SP metadata
        attr_index  => 1,   # index of AttributeConsumingService as per our SP metadata
        level       => 1,   # SPID level
    );
    
    # prepare a HTTP-Redirect binding
    my $url = $authnreq->redirect_url;

=head1 ABSTRACT

This Perl module is aimed at implementing SPID Service Providers and Attribute Authorities. L<SPID|https://www.spid.gov.it/> is the Italian digital identity system, which enables citizens to access all public services with single set of credentials. This module provides a layer of abstraction over the SAML protocol by exposing just the subset required in order to implement SPID authentication in a web application. In addition, it will be able to generate the HTML code of the SPID login button and enable developers to implement an Attribute Authority.

This module is not bound to any particular web framework, so you'll have to do some plumbing yourself in order to route protocol messages over HTTP (see the F<example/> directory for a full working example).
On top of this module, plugins for web frameworks can be developed in order to achieve even more API abstraction.

See L<README.md> for a full feature list with details about SPID compliance.

=head1 CONSTRUCTOR

The preferred way to instantiate this class is to call C<Net::SPID->new(protocol => 'saml', ...)> instead of calling C<Net::SPID::SAML->new(...)> directly.

=head2 new

=over

=item I<sp_entityid>

(Required.) The entityID value for this Service Provider. According to SPID regulations, this should be a URI.

=item I<sp_key_file>

(Required.) The absolute or relative file path to our private key file.

=item I<sp_cert_file>

(Required.) The absolute or relative file path to our certificate file.

=item I<sp_assertionconsumerservice>

An arrayref with the URL(s) of our AssertionConsumerService endpoint(s). It is used for metadata generation and for validating the C<Destination> XML attribute of the incoming responses.

=item I<sp_singlelogoutservice>

A hashref with the URL(s) of our SingleLogoutService endpoint(s), along with the specification of the binding. It is used for metadata generation and for validating the C<Destination> XML attribute of the incoming responses.

=item I<sp_attributeconsumingservice>

(Optional.) An arrayref with the AttributeConsumingServices to list in metadata, each one described by a C<servicename> and a list of C<attributes>. This is optional as it's only used for metadata generation.

    my $spid = Net::SPID->new(
        ...
        sp_attributeconsumingservice => [
            {
                servicename => 'Service 1',
                attributes => [qw(fiscalNumber name familyName dateOfBirth)],
            },
        ],
    );

=back

=head1 METHODS

=head2 get_button

This method generates the HTML markup for the SPID login button:

    my $html = $spid->get_button(sub {
        return '/spid-login?idp=' . $_[0];
    });
    my $html = $spid->get_button('/spid-login?idp=%s');

The first argument can be a subroutine which will get passed the clicked IdP entityID and will need to return the full URL. As an alternative a string can be supplied, which will be handled as a format argument for a C<sprintf()> call.

=head2 metadata

This method returns the XML representation of metadata for this Service Provider.

=head2 load_idp_metadata

This method accepts the absolute or relative path to a directory and loads one or multiple Identity Providers by reading all its files having a C<.xml> suffix.

    $spid->load_idp_metadata('idp_metadata/');

=head2 load_idp_from_xml_file

This method accepts the absolute or relative path to a XML file containing metadata of an Identity Provider and loads it.

    $spid->load_idp_from_xml_file('idp_metadata/prova.xml');

=head2 load_idp_from_xml

This method accepts a scalar containing the XML metadata of an Identity Provider and loads it. This is useful in case you store metadata in a database.

    $spid->load_idp_from_xml($xml);

=head2 idps

This method returns a hashref of loaded Identity Providers as L<Net::SPID::SAML::IdP> objects, having their C<entityID>s as keys.

    my %idps = %{$spid->idps};

=head2 get_idp

This method accepts an entityID and returns the corresponding L<Net::SPID::SAML::IdP> object if any, or undef.

    my $idp = $spid->get_idp('https://www.prova.it/');

=head2 parse_response

This method accepts a XML payload and parses it as a Response/Assertion, returning a L<Net::SPID::SAML::In::Response> object. Validation is performed (see the documentation for the L<Net::SPID::SAML::In::Response/validate> method), so this method may throw an exception.
A second argument can be supplied, containing the C<ID> of the request message; in this case validation will also check the C<InResponseTo> attribute.

    my $assertion = $spid->parse_assertion($xml, $request_id);

=head2 parse_logoutresponse

This method accepts a XML payload and parses it as a LogoutResponse, returning a L<Net::SPID::SAML::LogoutResponse> object. Validation is performed automatically by calling the C<validate()> method, so this method may throw an exception.
The XML payload can be supplied also in Base64-encoded form, thus you can supply the value of C<SAMLResponse> parameter directly.
In case the LogoutResponse was supplied through a HTTP-Redirect binding (in other words, via GET), the request URI (inclusive of the query string) must be supplied as second argument. This is used for signature validation. If HTTP-POST was used the second argument is ignored.
A third argument must be supplied, containing the C<ID> of the request message; this is used for the mandatory security check of the C<InResponseTo> attribute.

    my $response = $spid->parse_logoutresponse($xml, $url, $request_id);

=head2 parse_logoutrequest

This method accepts a XML payload and parses it as a LogoutRequest, returning a L<Net::SPID::SAML::LogoutRequest>. Use this to handle third-party-initiated logout procedures. Validation is performed, so this method may throw an exception.
In case HTTP-Redirect was used to deliver this LogoutRequest to our application, a second argument is required containing the request URI (see L<parse_logoutresponse>).

    my $request = $spid->parse_logoutrequest($xml, $url);

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
